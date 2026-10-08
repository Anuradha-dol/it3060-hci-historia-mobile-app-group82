# Codex implementation brief — HISTORIA Component 4

Implement the complete component assigned to IT23667778 — Siriwardhana H L: Tour Guider Booking, Scheduling, Meeting Logistics & Live Guide Tracking. Work inside this existing repository. Execute the implementation, integration, and verification; do not stop after producing a plan or UI mockups.

## 1. Read the project and authoritative references first

Read any applicable AGENTS.md, root README.md, backend/pom.xml, backend configuration, frontend/pubspec.yaml, and relevant existing code before editing. Inspect the working tree and preserve unrelated changes. Use an isolated feature branch when this is a git checkout; do not initialize a replacement repository or switch to an older user-management branch.

Read docs/component4/proposal.pdf and visually inspect every PNG in docs/component4/reference/. PDF physical page numbers:
- 1: member ownership.
- 2: FR13, FR14, FR15.
- 10: alternative sketches.
- 14: chosen Variant A and rationale, including offline operation.
- 19: low-fidelity component 4 wireframes.
- 27–28: final high-fidelity screens, the primary UI authority.
- 28–29: user-testing tasks; particularly tasks 6, 7, and 9.

The five PNGs are original images extracted from the proposal, not redesigned references. Build real Flutter widgets matching them. Do not render a screen image as the actual UI. Do not substitute a generic booking dashboard. Do not reproduce fake phone status bars, home indicators, Figma arrows, or captions outside the app canvas.

Existing stack: Flutter/Dart, Provider, Dio, secure storage, Spring Boot/Java 17, Spring Data JPA, PostgreSQL, JWT, STOMP/SockJS. Preserve the pinned dependencies initially. Dart constraint is ^3.12.2, Spring Boot parent is 4.1.1. Diagnose compatibility using actual local build output before changing versions. Do not convert the app to React, React Native, Firebase, MongoDB, or Node.js.

## 2. Inspect and reuse these integration points

Frontend:
- frontend/lib/main.dart and screens/home_router.dart
- frontend/lib/providers/auth_provider.dart
- frontend/lib/config/api_config.dart
- frontend/lib/services/api_service.dart, storage_service.dart, guide_service.dart
- frontend/lib/models/guide_model.dart
- frontend/lib/profile/approved_guides_screen.dart and profile_screen.dart
- frontend/lib/tourist/tourist_home_screen.dart and tour_planner_screen.dart
- frontend/lib/guide/guide_home_screen.dart
- frontend/lib/tourist/buddy_chat_screen.dart for existing transport patterns
- frontend/lib/theme/ and widgets/historia_components.dart, historia_header.dart, historia_bottom_nav.dart

Backend package: com.historia.backend. Inspect GuideController, GuideService and implementation, GuideProfile, User, guide repositories, authentication/security code, DTO patterns, GlobalExceptionHandler, WebSocketConfig, WebSocketAuthChannelInterceptor, and buddy chat authorization.

Known findings to verify locally:
1. The tourist home passes `onTouristGuides: () {}` to RoleProfileContent. This suppresses the profile screen's fallback navigation. Wire it to the new directory.
2. Existing approved-guide search requires the `area` parameter and currently matches service areas case-insensitively. Preserve backward compatibility while adding discovery/filtering.
3. GuideProfile already has languages, specialties, service areas, experience and approval status. It lacks booking packages, pricing, availability, certification evidence, ratings aggregate, and tracking records.
4. The current WebSocketAuthChannelInterceptor rejects every role except TOURIST and authorizes buddy destinations only. Do not simply reuse it unchanged for GUIDE connections or remove its checks globally.
5. The existing Tour model describes the historical multi-place itinerary, not a paid guide booking. Introduce a separate booking domain with an optional itinerary reference if appropriate.
6. No payment implementation or component 4 booking/tracking implementation was found in the supplied snapshot. Reinspect in case teammates have added these since the review.
7. There are no frontend/test or backend/src/test directories in the supplied snapshot, and the backend lacks explicit test dependencies. Add compatible testing support for this component. Do not report a no-tests Maven build as passing behavioral tests.

## 3. Scope and decisions

Deliver FR13–FR15 end to end. Preserve members 1–3's authentication, profiles, approval workflow, historical discovery, community posts, tour planner, buddy matching/chat, and any newly added payment/reviews code. Member 3 owns real payment processing and rating/review submission. Add explicit integration contracts rather than replacing their module.

The proposal's demonstration data is internally inconsistent. Record these assumptions in docs/component4/IMPLEMENTATION_NOTES.md and implement coherent behavior:
- The customization/summary example charges LKR 2,500 per visitor for the 2-hour Full Heritage Walk: 3 visitors = LKR 7,500. Use per-person package pricing as the initial documented demo rule; the directory must label it consistently rather than silently using its conflicting `/hr` label. Keep pricing data-driven and easy to revise.
- Point to Point is a 45-minute assistance package, initially LKR 1,500 per visitor in demo data. Its prototype says “Self guided” despite the guide-booking context. Preserve the card structure, document that wording conflict, and avoid promising both a self-guided service and a fully guided tour.
- A selected 10:30 AM booking must not become a 09:45 AM meeting on the next page. Carry a single selected date/time throughout. Use Asia/Colombo for service schedules and unambiguous timezone-aware API timestamps.
- Kamal Perera, Sunil Fernando, ratings, review counts, 08 MINS, 450m and #4821 are prototype examples, not real runtime constants. Only use clearly identified demo fixtures; generate actual booking references and passcodes. Derive live values from data.
- Keep the “Create account” secondary action for a guest preview, routing to existing registration. Authenticated travelers do not need to create another account; conditionally hide it and record this small state-dependent deviation.

Make routine implementation decisions and document them. Do not request repeated confirmation. If a genuine external dependency is unavailable, finish everything that can run locally, supply a clearly isolated demo path, and report the exact blocker without claiming production integration.

## 4. Implement the five traveler screens

### A. Find a guide — FR13

Match 01-find-guide.png: HISTORIA header, Galle Fort site badge, “Find a guide.” title, subtitle, search field, rounded filter chips and vertically stacked detailed guide cards. Reuse existing brand assets and green/off-white theme. Preserve card hierarchy, language badges, credentials, availability badge, rating row, price and full-width “Select Guide” action.

Implement search by name/interests or specialty, language filtering including EN/SI/TA, service-area filtering, certified-only filter and top-rated filter. The screenshot's “All Guides (14)” count must be computed. Filters must actually affect results and combine predictably. Use existing approved guide records; pending/rejected/deleted/disabled accounts are not bookable. HISTORIA approval alone is not proof of SLTDA certification: model certification separately and display that badge only from verified data or clearly labeled demo data. Show honest unrated states until ratings integration supplies data. Include initial loading, retry, empty results and no-availability states.

Selecting a guide passes its real ID into the next screen. Keep existing profile/service-area guide-search entry points working.

### B. Customize visit — FR14

Match 02-customize-visit.png: two radio-style package cards, selected green outline/checkmark, popular badge, duration/features, time-slot chips, visitor minus/plus stepper, subtotal and “Review booking details” button.

Provide date selection as a compact extension because actual scheduling needs a date. Retrieve enabled packages and guide availability from the backend. Disable unavailable/past slots; validate visitor count against configurable capacity; recalculate pricing when package/party changes. Changing package duration/date must revalidate the slot. Keep selections when navigating back. The next step is meeting-location selection, followed by review.

### C. Meeting Location — FR15

Match 03-meeting-location.png: landmark chips (Clock Tower Gate, Sun Bastion, Moon Bastion), light schematic map with green pin, zoom controls, walkway/distance row, checkpoint card and “Confirm Meeting Point” button.

Bundle a lightweight schematic of Galle Fort locally (Flutter CustomPainter or an existing compatible vector/image asset). It must be available without network; do not require satellite tiles to complete this flow. Chip selection and zoom must work and update the corresponding marker/details. Represent the map as schematic, not surveyed turn-by-turn navigation. Store landmark IDs, label, description, access instructions, coordinates when reliable, and configured walking route/distance information. Do not invent precise geographic accuracy. Distinguish configured/estimated walking distances from live GPS distance; straight-line distance is not a walking route.

Show the selected guide, consistent rendezvous time and access instructions. Cache the map and authorized confirmed-booking meeting details for offline access. Provide clear permission-denied/location-unavailable fallback directions. Request location only when the feature needs it.

### D. Review & pay — FR14/FR15 boundary

Match 04-review-pay.png: header, “Review & pay.” title, booking summary card, order-reference badge, schematic/meeting label, package, assigned guide, schedule, party size, total, and “Pay Now”. Ensure guide, meeting point, date/time, visitors, rate basis and total match the preceding screens. Let users go back and edit without losing valid choices.

Persist a server-authoritative booking/temporary slot hold before payment. Prevent duplicate taps/retries from creating duplicate bookings. Validate availability atomically on the backend. The client sends IDs and choices, not a trusted total. A time-limited hold must expire/release if payment is abandoned or fails; do not block slots indefinitely.

Define a typed checkout contract containing booking ID/reference, guide/package summary, meeting point, date/time, party size, currency LKR, server-calculated amount, and a result type for success/failure/cancellation/pending. Connect to member 3's module if present. A frontend “success” flag must not authorize a production paid booking; verify payment through the trusted backend integration.

If payment is absent, provide an explicit local/dev-only demo checkout with success/failure/cancel outcomes so this component can be evaluated. Disable demo payment mutation in production. Do not collect real card data or create a real payment gateway. A failure/cancellation returns safely with understandable feedback. Start the tracker only for an eligible confirmed booking. Document the exact handoff API for member 3.

### E. Guide is on the way — FR15

Match 05-guide-tracker.png: title/subtitle, prominent arrival countdown, distance/ETA pill, dashed meeting-passcode card, assigned-guide card with rating, filled “Call Guide” and outlined “Message” buttons.

Track the assigned guide for the specific booking, not a travel buddy. Implement guide-supplied status/location/ETA updates and consume them in the tourist app. Prefer foreground location tracking while the guide has an active booking; stop on completion/cancellation/logout. Implement the Android/iOS permission configuration required by any chosen location package. No background tracking service is required unless unavoidable; explain any platform restriction honestly.

Use authorized STOMP destinations or a documented authenticated polling transport with bounded interval. If extending STOMP, permit the necessary GUIDE connections while preserving tourist-only buddy routes; check booking membership for every subscription/send and restrict location publishing to the assigned guide. Never broadcast private positions or passcodes to all users. If polling, disclose the refresh interval and manage foreground/background lifecycle and cancellation.

Show last update time and stale/offline indicators. When offline, do not animate fake movement or claim live arrival updates; cached ETA is an estimate. Countdown derives from timestamped ETA rather than a hardcoded eight-minute timer. Handle reconnect/resume and app restart by reloading the persisted active booking. Provide a discoverable way to reopen an active booking, e.g. a small My guide bookings entry within existing navigation.

Generate a random booking-specific PIN and cache the authorized meeting credential before connection is lost. Make it available to the two booking participants so an in-person comparison can work offline. Keep it in protected per-user storage with expiry; clear sensitive cache on logout/account change. Offline comparison is a provisional local handshake, not a claim of server-confirmed identity or replay-proof authentication. Queue reconciliation on reconnect; online verification must enforce booking membership, expiry, single-use semantics and attempt limits. Never hardcode #4821 for real bookings.

Call Guide should open the assigned guide's dialer contact using existing url_launcher support, with a useful unsupported-device fallback. Message should use a working minimal booking-specific chat or a documented SMS compose handoff to that guide. Do not create a travel-buddy request or reuse an unrelated conversation as guide messaging. Configure platform schemes/visibility as needed.

## 5. Minimal supporting guide workflow

The five proposal screens are traveler-facing, but real scheduling/tracking requires a guide-side data source. Extend the existing GuideHomeScreen with modest sections, preserving its profile/feed workflows:
- Manage enabled packages/rates, party capacity and available dates/time windows.
- View only the guide's own upcoming/active bookings and their meeting details.
- Update allowed states such as confirmed, en route, arrived, in progress, completed/cancelled.
- Start/stop foreground location sharing and update an ETA when appropriate.
- Participate in the meeting-code handshake and offline reconciliation.

Do not redesign the entire guide dashboard. Treat these additions as supporting implementation, not screens explicitly shown in the proposal.

## 6. Backend and persistence

Design a small maintainable model consistent with existing entity/repository/service/controller/DTO conventions: guide packages; availability windows; landmarks; guide bookings; tracking snapshot/status; minimal handshake data. Avoid unnecessary microservices. Use PostgreSQL and existing User/GuideProfile references. Optional itinerary links must not change Tour ownership.

Use BigDecimal or minor currency units for amounts. Define valid booking/payment states and server-enforced transitions. Protect against concurrent overlapping reservations using a transaction and database locking/constraints covering the entire guide-duration interval (not just equal start times). Reject closed slots, non-approved guides, mismatched packages/landmarks, past dates, invalid counts and tampered prices. Include expired holds in availability calculation correctly.

Derive identity from authenticated principal; never trust a supplied user ID as authorization. Tourists see their own bookings; guides see only their assignments; admins retain appropriate existing access. Use minimal public discovery DTOs rather than exposing private addresses, email, admin notes or tracking data. Protect rate changes and location updates by guide ownership. Return useful validation and conflict responses without leaking sensitive information.

Create compatible additions to existing schema/configuration; do not drop databases or overwrite teammate records. Ensure new entities fit existing account lifecycle conventions and cancellation/retention decisions. Add an explicit idempotent local/demo seed mode containing the two prototype guides, approval/certification demo metadata, packages, landmarks and future availability. Never seed on normal production startup. Document exactly how to create/use development test accounts; do not silently disable normal email verification.

## 7. Flutter implementation and usability

Use typed models/services and Provider/ChangeNotifier consistent with the existing project. Keep network/business logic out of large widget build methods. Reuse Dio/JWT handling and secure storage; handle expired sessions clearly. Add API_BASE_URL via --dart-define with the current emulator/web defaults and preserve resolveImageUrl. Do not hardcode a laptop IP in committed code.

Preserve the bottom navigation labels Home, Tour, Create, Explore, Profile and actual destinations. Correct the dead “Find guides” callback. Route component 4 from that existing entry; optionally add a compact tour-context entry. Avoid duplicate bottom nav bars and avoid replacing the existing Tour planner.

Match visual spacing, green/cream palette, borders, hierarchy and button shapes. Screens must work at approximately 360–430 logical-pixel widths, with SafeArea, scrollable content, readable text scaling, keyboard handling, accessible semantics and generous touch targets. Exact tiny prototype text should be scaled for readability without changing the visual composition. Include loading, retry, no results, invalid input, expired session, denied location, offline and stale tracking states. Dispose timers/listeners/streams and check mounted after asynchronous operations.

## 8. Delivery and evidence

First record a brief implementation plan and baseline tool/build status, then implement incrementally. Do not stop after scaffolding. Verify only what this environment actually supports and report external blockers accurately.

Run flutter pub get, flutter analyze, meaningful flutter tests, and an Android debug build when SDK/device prerequisites permit. Run Maven compilation/tests using the wrapper. Add focused backend tests for correct pricing, ownership, status transitions, concurrent interval booking conflicts, idempotency/hold expiry, payment boundary, and PIN rules. Add focused Flutter tests for selection/stepper totals, retained state, pay outcomes, and offline/stale display. Use PostgreSQL-compatible integration testing for locking behavior rather than assuming an in-memory database proves it.

Exercise a full demo with separate traveler and guide sessions: discover → choose package/date/time/visitors → choose meeting point → review → demo or integrated payment → guide en route → tracker update → offline meeting details/PIN → reconnect → completion. Verify unrelated users cannot fetch/subscribe to the booking. Verify two travelers cannot book overlapping durations with the same guide. Smoke-check login, existing guide approval, guide profile edit, historical tour planning and buddy chat.

Capture app screenshots of the five implemented screens and visually compare them to docs/component4/reference/. Check clipping, scrolling and navigation on a small mobile viewport. Screenshots alone do not replace behavioral verification. Report any remaining visual deviation.

Deliver:
1. Complete working component 4 frontend/backend code.
2. docs/component4/IMPLEMENTATION_NOTES.md mapping FR13–FR15 to screens/files, assumptions and visual deviations.
3. docs/component4/API_AND_PAYMENT_CONTRACT.md for member 3 and guide transport consumers.
4. docs/component4/RUN_AND_DEMO.md with exact setup, seed, account, run and evaluation steps.
5. docs/component4/TEST_RESULTS.md listing actual commands/results and any untested claims/blockers.

At completion summarize changed files, how to launch and reach the component, how to run the two-role demo, successful checks, and genuine outstanding dependencies. Never describe simulated checkout/location as a live production integration.
