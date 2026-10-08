# Component 4 API and payment contract

Base URL: `http://localhost:8081`. Prefix: `/api/guide-bookings`.
All endpoints require the existing `Authorization: Bearer <accessToken>` JWT. Identity comes from the authenticated `User`, never a request user ID. Use JSON and ISO-8601 timestamps with an explicit offset; schedules display in `Asia/Colombo` (+05:30).

## Discovery and guide management

| Method/path (relative to prefix) | Request / behavior |
|---|---|
| `GET /guides` | Combined optional `q`, `language`, `area`, `specialty`, `certified`, `rating`, `date` (YYYY-MM-DD), `at` (timestamp). Returns enabled, email-verified, approved guides and enabled packages. `available` describes the requested date/time and includes duration conflicts. No private contact, admin note, PIN or location. |
| `GET /landmarks` | Configured landmark ID, service area, description, access note, schematic X/Y. **Not GPS coordinates.** |
| `GET /slots?guideId=1&packageId=2&date=2026-10-09` | Future available start timestamps at 30-minute increments from configured availability windows. Package must belong to guide. |
| `GET /management` | Assigned guide's packages and future availability windows. Approved GUIDE only. |
| `PUT /management/packages` | `{id?, name, features, durationMinutes, pricePerVisitor, minVisitors, maxVisitors, enabled}`. Prices: positive LKR, max 2 decimal places. Duration 15–480 minutes; capacity 1–100. Existing booking amount/package name/duration are snapshots and do not change when rates change. |
| `POST /management/windows` | `{startsAt, endsAt}`. Future window, max 24 hours, within next year. |
| `DELETE /management/windows/{id}` | Removes own future bookable window. Existing reservations remain valid. |

The original `/api/guides/approved?area=...` contract is unchanged for old callers. New discovery uses a separate minimal DTO and adds filtering without exposing `GuideProfile` entities.

## Booking and tracking

| Method/path | Request / behavior |
|---|---|
| `POST /` | `{guideId, packageId, landmarkId, startsAt, visitors, requestKey}` → BookingView with `HELD` state and 10-minute expiry. No client amount is accepted. TOURIST only. |
| `GET /` | Current user's reservations, including history, used for app-restart recovery. |
| `GET /{id}` | Booking and latest tracking snapshot. Only traveler or assigned guide; outsider gets 404. |
| `GET /{id}/checkout` | Typed Checkout contract below; only booking traveler, unexpired HELD reservation. |
| `POST /{id}/demo-checkout` | `{outcome: "success" | "failure" | "cancel"}`. Only enabled when both Spring profile `demo` and `historia.booking.demo-payments=true` are set. Disabled otherwise (404). |
| `POST /{id}/state` | `{state}`; transitions below. |
| `POST /{id}/location` | `{latitude, longitude, eta?}`; assigned GUIDE only, in EN_ROUTE/ARRIVED/IN_PROGRESS service window. Finite geographic bounds; future ETA within 4 hours. Timestamp is server generated. |
| `POST /{id}/verify-pin` | `{pin: "1234"}`; assigned guide confirms after in-person comparison. Returns `{verified, message}`. Wrong attempts return a normal response so their counter transaction commits. |

`requestKey` is a random client attempt identifier. Retries with the same traveler/key and identical payload return the same booking, even after expiry; they do not renew a hold. Reusing the key with changed details gives 409. New selections require a new key. A unique database constraint provides a second guard.

Booking creation serializes on the traveler row (retry identity) then guide profile row (all reservations for that guide). Overlap is checked with `existing.start < requested.end AND existing.end > requested.start`, including package duration. Adjacent intervals are allowed. Expired holds are excluded immediately when finding slots; reads label them EXPIRED. No scheduler is required to release their capacity. All package/window writes lock the same guide row. Concurrent overlap was tested using real PostgreSQL, not H2.

Transitions:

```text
HELD -> CONFIRMED only through verified payment / explicit demo adapter
HELD -> EXPIRED on elapsed hold or past start
HELD / CONFIRMED / EN_ROUTE / ARRIVED -> CANCELLED by either participant
CONFIRMED -> EN_ROUTE -> ARRIVED -> IN_PROGRESS -> COMPLETED by assigned guide
ARRIVED -> IN_PROGRESS requires successful online PIN confirmation
```

Guide activity is allowed from two hours before scheduled start until one hour after scheduled end. Terminal bookings reject publishing. Cancellation of PAID or DEMO_PAID reservations becomes `REFUND_REQUIRED`; this records a dependency on the payment team and **does not issue a refund**.

Transport: authenticated HTTP polling every **10 seconds** while the tracker screen is foreground. Location snapshots older than **30 seconds** are stale. Guide publishing uses a freshly requested device fix; the user-entered ETA is stored as a timestamp and is not reset by each poll. Turning off sharing, leaving the screen, backgrounding, completion, cancellation or logout stops publishing. A previous fix may remain visible as last-known until stale. No location history is collected. Existing buddy STOMP/SockJS rules remain tourist-only and unchanged; there are no booking subscriptions or public PIN broadcasts.

The distance option measures a straight line between the traveler's requested fix and guide's latest fix. It is not walking distance or navigation. Landmark walking/access text is a configured estimate. Message uses an explicit SMS compose handoff containing the booking reference/location/time, not buddy chat. No message is sent automatically.

PIN: random four digits per booking; only active participants can retrieve it; five online attempts; valid through one hour after tour end; single successful use. Offline code comparison saves a secure per-user provisional request and retries on reconnection. It cannot start a tour until accepted online. Four digits are a meeting aid, not strong or replay-proof identity verification. Participants already know the code, so this is not independent proof of physical presence.

## Member IT23687646 payment boundary

Frontend `CheckoutContract` / backend `BookingDto.Checkout`:

```json
{
  "bookingId": "server UUID",
  "reference": "HS-xxxxxxxx",
  "amount": 7500.00,
  "currency": "LKR",
  "guide": "assigned guide name",
  "packageName": "Full Heritage Walk",
  "meetingPoint": {"id": "clock", "name": "Clock Tower Gate"},
  "startsAt": "2026-10-09T05:00:00Z",
  "visitors": 3,
  "expiresAt": "server hold expiry",
  "demoEnabled": false
}
```

1. Obtain this contract from the backend; do not calculate a gateway amount from the Flutter subtotal.
2. Create the gateway checkout server-side. Associate the gateway order/reference with booking ID. Authenticate checkout ownership.
3. On trusted webhook or server-to-server verification, validate the provider signature, order identity, settlement status, amount, LKR currency and replay/idempotency rules.
4. Only then call `BookingService.confirmVerifiedPayment(bookingId, settledAmount, currency, gatewayReference)` **inside the backend**. There is deliberately no HTTP endpoint accepting these as unverified client claims. The method rechecks amount/currency/hold/eligibility, locks the booking, and stores a unique gateway reference. Duplicate verified callbacks with the same reference are idempotent.
5. A settlement received after expiry/cancellation must be reconciled/refunded by the payment module, not forced into the unavailable interval. The method rejects it.
6. Flutter must re-fetch booking state after return from payment. Failure leaves the hold retryable until expiry; cancel releases it. Only backend CONFIRMED state permits active tracking.

No real gateway, card form, refund engine or rating submission was found or replaced. Demo ratings are stored separately, clearly labeled, and have zero real reviews. Certification evidence is separate from HISTORIA approval; guides cannot self-award certification through management endpoints. Real review/certification aggregation remains an admin/payment-team integration.

Error conventions: validation 400, ownership/role 403, hidden/nonexistent booking 404, expired/unavailable/illegal state 409. Expired JWT requires sign-in again. Avoid logging request credentials, full booking DTOs or location/PIN response bodies in production.
