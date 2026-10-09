# Component 4 — IT23667778, Siriwardhana H L

## Reference and architecture inspection

Read the supplied brief, CODEX_PROMPT, README, current manifests/configuration and relevant authentication, guide, navigation, theme and buddy authorization code. Read proposal physical pages 1, 2, 14, 19, 27–29. Visually inspected all five supplied PNGs, which are the extracted final designs. No applicable AGENTS.md was found in the project or checked ancestor locations.

The project already contained real Flutter/Spring code. No `flutter create`, repository initialization, framework downgrade, database reset or teammate module replacement was performed. There was no existing guide booking/payment implementation. The historical `Tour` entity remains separate and unchanged.

## FR13–FR15 traceability

| Requirement | Frontend | Backend / behavior |
|---|---|---|
| FR13 discovery | `frontend/lib/booking/guide_directory_screen.dart` | `BookingService.discover`: approved enabled guides; combined name/interest/language/specialty/area/certification/rating/date/time filters; actual package prices/count/availability; honest absent rating and certification states. |
| FR14 customization | `booking_flow_screen.dart`, `booking_provider.dart`, `booking_models.dart` | GuidePackage and GuideWindow persistence; stored rates/capacity; authoritative amount; 30-minute start choices; full-duration interval conflicts; retained selections; retry-key holds and expiry. |
| FR15 meeting logistics | Meeting step, `booking_widgets.dart` → MeetingMap | MeetingLandmark persistence, selectable pins and offline CustomPainter map; working zoom, configured access notes, consistent schedule. |
| Review/pay handoff | Review step, CheckoutContract | Typed checkout and internal trusted payment boundary; disabled-by-default demo adapter; success/failure/cancel. |
| FR15 tracking / handshake | `guide_tracker_screen.dart`, `my_bookings_screen.dart`, BookingCache | Participant-restricted polling/location APIs, fresh foreground geolocation, timestamp ETA, stale state, random PIN, attempt limits/expiry/single use, secure cached provisional comparison/reconciliation. |
| Supporting guide actions | `guide_management_screen.dart` and existing GuideHome entry | Own rates/packages/capacity/windows, own bookings, state progression and meeting verification. |

Navigation: existing tourist Profile → Find guides callback now opens the directory. Directory header's booking icon opens My guide bookings. Existing profile fallback also opens the directory. Guide Home adds “Guide bookings & availability.” Component pages retain one Home/Tour/Create/Explore/Profile navigation bar pointing to existing destinations; the historical planner was not replaced. Existing guide dashboard/feed/profile/approval and buddy routes were retained.

## Decisions resolving prototype conflicts

- All prices consistently mean **LKR per visitor**. Demo Full Heritage Walk = 120 minutes × LKR 2,500 per visitor; 3 visitors = LKR 7,500. Point to Point = 45 minutes × LKR 1,500 per visitor.
- Point to Point means short guide assistance. The prototype's “Self guided” wording was omitted because it contradicts this component's assigned guide.
- One timestamp is carried from selection through meeting, summary and tracker. All display times explicitly use Sri Lanka time, regardless of the device time zone.
- Demo Kamal Perera / Sunil Fernando records, certification and numeric ratings are explicitly labeled DEMO. No real reviews or certifications are invented; review count is zero. Ordinary approved guides remain uncertified/unrated until real evidence is added.
- “From” discovery price is the lowest enabled package price, not an hourly rate. Duration and exact amount appear after package selection.
- The map is a lightweight schematic with normalized drawing positions. It contains no invented GPS destinations, turn-by-turn directions, or claim that a straight-line measurement is walking distance.
- The three Galle Fort landmarks are idempotently configured on startup. Access notes explicitly say when an estimate needs local confirmation. Guides outside the landmark service area cannot book those landmarks; more sites require real landmark configuration.
- Guest booking preview was not part of the existing authenticated entry. Authenticated users are not shown a redundant Create account action; normal app registration remains available from login.
- New transport is authenticated polling rather than changing buddy WebSocket access. This prevents widening tourist-only buddy permissions just to support guides.

## Storage and lifecycle

New tables: `guide_booking_packages`, `guide_booking_windows`, `guide_meeting_landmarks`, `guide_bookings`, `guide_booking_evidence`. Existing User/GuideProfile identities are referenced. Existing PostgreSQL `ddl-auto: update` is preserved for local development; do not use the test runner's isolated create-schema setting on a real database. Back up existing data before deploying additive Hibernate schema updates. For production, capture/review an explicit migration under the team's migration process.

Holds have unique traveler/request keys; money is BigDecimal; booking amount, package name and end time are snapshots. Expiry releases capacity through every availability query and is reflected on reads. Latest tracking location only is persisted; terminal responses hide location and PIN. No unrelated user can fetch tracking or verify the PIN.

Secure cache contains owner ID, last authorized booking snapshots and provisional PIN requests. Logout/account changes clear it. Cold startup with an unreachable refresh endpoint may restore the cached user for offline access; the backend still requires a valid JWT for all online operations. Authentication failures do not authorize new operations. Live cache timestamps are never advanced while offline. Browser storage is origin-specific, so use the same host/port to recover cached details.

Web offline limitations: Flutter's compiled app/assets must already be available to the browser to reopen with the network absent. Browser cache/service-worker behavior varies and is not equivalent to an installed native app guarantee. Once open, the schematic and previously cached meeting details need no API connection. Native device storage/location behavior requires device verification.

## Configuration improvements

`API_BASE_URL` dart-define preserves original web/emulator defaults and image URL resolution. CORS permits configured local development origins. Missing Google client ID or SMTP sender now disables the affected feature with a clear message instead of crashing all backend startup. Ordinary OTP validation was not bypassed. Only an explicitly enabled demo seed creates preverified demonstration accounts.

Seed requires both profile `demo`, `historia.booking.seed=true`, and a user-supplied `HISTORIA_DEMO_PASSWORD` of at least 12 characters. Seed checks fixture usernames before reusing records, preserves existing rates/accounts, and extends a 14-day schedule. It does not run in normal startup. `LocalDemoServer` is test-source only and supplies temporary random credentials for an isolated loopback demo database.

## Visual differences to acknowledge

Actual Flutter UI uses the project's shared logo, theme and navigation, readable 11–25px text, larger touch targets and scrolling. It is not a screenshot background. Status bars, device frames and external Figma captions are omitted. More filter controls, date selection, honest demo labels, precise price units and recovery controls increase content height compared with the compact reference. Directory cards therefore may require scrolling to the second guide. The schematic is deliberately simplified. Missing live ETA/location shows pending/stale states rather than the prototype's hardcoded 08 MINS/450m. Meeting codes and references are random.

See `screenshots/` and `TEST_RESULTS.md` for the actual verification evidence and remaining device/integration checks.
