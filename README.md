# HISTORIA

HISTORIA is our final project for the IT3060 Human Computer Interaction module in Year 3, Semester 2. We built it as a mobile heritage travel app for Sri Lanka, with a focus on helping travelers discover historical places, plan tours, connect with travel buddies, and book approved local guides.

<p align="center">
  <img src="docs/screenshots/landing-page.png" alt="HISTORIA mobile landing page" width="340">
</p>

This app was developed step by step through the HCI assignment process. In the first evaluation, we selected the project idea, studied the problem area, identified the main users, and planned the key workflows. In the second evaluation, we created wireframes and designed the UI in Figma. After those two evaluations, we implemented the final working project using a real mobile frontend, backend REST APIs, authentication, database storage, file uploads, booking logic, and testing.

The main actors in the system are tourists, local guides, and admins. Tourists use the app to explore heritage places and book guide support. Guides manage their profile, packages, availability, and live booking updates. Admins review guide applications and manage important platform content.

Technically, HISTORIA is a full-stack mobile application. The frontend is built with Flutter, and the backend is a Spring Boot REST API connected to PostgreSQL.

## Project Summary

| Area | Details |
| --- | --- |
| Project name | HISTORIA |
| Project type | Mobile app with REST API backend |
| Main domain | Historical place discovery, tour planning, guide booking, and travel community |
| Frontend | Flutter, Dart, Provider, Dio |
| Backend | Java 17, Spring Boot 4.1.1, Spring Security, Spring Data JPA |
| Database | PostgreSQL |
| Authentication | JWT access/refresh tokens, BCrypt password hashing, email OTP, Google Sign-In support |
| Realtime | Spring WebSocket/STOMP for travel buddy chat |
| File handling | Local upload storage served from `/uploads/**` |
| Default backend port | `8081` |

## What The App Does

HISTORIA is designed around three main user roles.

### Tourist

- Register and verify the account through email OTP.
- Log in with email/password or Google Sign-In.
- Explore curated Sri Lankan historical places.
- Search historical places and open detailed place information.
- Build multi-place tour plans and mark tour places as completed.
- Create community posts with images.
- Like posts and comments.
- Find travel buddies and chat with accepted buddies.
- Discover approved local guides by area, language, specialty, certification, rating, date, and time.
- Choose a guide package, visit time, party size, and meeting landmark.
- Review the booking amount and complete checkout.
- Track guide status, ETA, location freshness, and meeting PIN state.
- Submit reviews after paid bookings.
- View account notifications and profile details.

### Guide

- Register through the guide application flow.
- Wait for admin review before becoming visible in the guide directory.
- Update guide profile details such as display name, service areas, languages, specialties, experience, headline, and bio.
- Manage guide booking packages, prices, visitor limits, and available time windows.
- View assigned bookings.
- Progress booking state from confirmed to en route, arrived, in progress, and completed.
- Share live location/ETA during the active service window.
- Verify the tourist's meeting PIN before starting the guided service.
- Participate in the community feed.

### Admin

- Review guide applications.
- Move applications between pending, needs work, approved, and rejected states.
- Add admin notes when asking for changes or rejecting an application.
- Manage historical places.
- Publish community posts.
- View notifications and account profile information.

## Main Features

- Full-screen mobile landing page with Sri Lankan heritage branding.
- Role-based startup routing for tourist, guide, and admin accounts.
- Secure account registration with OTP email verification.
- JWT login with access and refresh token handling.
- Google Sign-In support through Google OAuth ID token verification.
- Forgot-password OTP flow.
- Local image uploads for profiles, covers, places, and posts.
- Historical place listing, search, detail view, and admin place management.
- Community feed with posts, likes, comments, and image support.
- Tour planner with multi-place tour progress tracking.
- Travel buddy search, request, accept/reject, conversations, and STOMP chat.
- Approved guide directory with practical filters.
- Guide booking flow with package pricing, availability windows, schedule conflict protection, meeting landmarks, checkout, tracking, and meeting PIN validation.
- Mock/demo payment flow for academic evaluation.
- Guide reviews and rating summaries.
- Notification records for booking, payment, and status changes.
- Backend integration tests for booking concurrency, idempotency, access control, payment boundaries, and PIN handling.
- Flutter tests for booking state, retry behavior, cache behavior, stale tracking state, and responsive booking screens.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile frontend | Flutter, Dart |
| Frontend state | Provider, ChangeNotifier |
| HTTP client | Dio |
| Local secure storage | flutter_secure_storage |
| Authentication UI integration | google_sign_in |
| Maps/location support | flutter_map, latlong2, geolocator |
| External actions | url_launcher |
| Realtime client | stomp_dart_client |
| Backend framework | Spring Boot 4.1.1 |
| Backend language | Java 17 |
| REST layer | Spring Web MVC |
| Security | Spring Security, JWT, BCrypt |
| Persistence | Spring Data JPA, Hibernate |
| Database | PostgreSQL |
| Email | Spring Mail with SMTP |
| Realtime backend | Spring WebSocket/STOMP |
| Build tools | Maven Wrapper, Flutter tooling |
| Testing | JUnit, embedded PostgreSQL, Flutter test |

## System Architecture

```text
Flutter Mobile App
        |
        | Dio HTTP requests with Bearer JWT
        v
Spring Security JWT Filter
        |
        v
Spring Boot REST Controllers
        |
        v
Service Layer
        |
        v
Spring Data JPA Repositories / EntityManager
        |
        v
PostgreSQL Database

Uploads
        |
        v
Local uploads folder served through /uploads/**

Travel Buddy Chat
        |
        v
Flutter STOMP client -> /ws SockJS endpoint -> /app messages -> /topic updates
```

The backend is stateless for normal API authentication. The Flutter app stores JWTs locally, sends the access token in the `Authorization: Bearer <token>` header, and refreshes the session when protected requests return `401`.

## Repository Structure

```text
it3060-hci-historia-mobile-app-group82/
|-- backend/
|   |-- src/main/java/com/historia/backend/
|   |   |-- booking/       # guide booking, schedule, meeting and tracking module
|   |   |-- config/        # security, CORS, WebSocket, startup config
|   |   |-- controller/    # REST controllers
|   |   |-- dto/           # request/response DTOs
|   |   |-- entity/        # JPA entities
|   |   |-- enums/         # roles, statuses and payment enums
|   |   |-- exception/     # global exception handling
|   |   |-- repository/    # Spring Data repositories
|   |   |-- security/      # JWT, Google token verification, user details
|   |   |-- service/       # service interfaces
|   |   |-- service/serviceImpl/
|   |   `-- utils/
|   |-- src/main/resources/
|   |   |-- application.yml
|   |   `-- application-local.example.yml
|   |-- src/test/java/
|   |-- pom.xml
|   |-- mvnw
|   `-- mvnw.cmd
|
|-- frontend/
|   |-- lib/
|   |   |-- admin/
|   |   |-- auth/
|   |   |-- booking/
|   |   |-- config/
|   |   |-- guide/
|   |   |-- models/
|   |   |-- profile/
|   |   |-- providers/
|   |   |-- screens/
|   |   |-- services/
|   |   |-- theme/
|   |   |-- tourist/
|   |   `-- widgets/
|   |-- assets/images/
|   |-- test/
|   |-- pubspec.yaml
|   `-- README.md
|
|-- docs/
|   |-- screenshots/
|   |   `-- landing-page.png
|   `-- component4/
|       |-- proposal.pdf
|       |-- API_AND_PAYMENT_CONTRACT.md
|       |-- IMPLEMENTATION_NOTES.md
|       |-- MANUAL_SETUP.md
|       |-- RUN_AND_DEMO.md
|       `-- TEST_RESULTS.md
|
|-- scripts/
|   `-- Run-Flutter.ps1
|-- uploads/
|-- START_HERE.md
|-- README.md
`-- LICENSE
```

## Backend Overview

The backend lives in `backend/` and uses the package:

```text
com.historia.backend
```

It exposes REST APIs for authentication, users, guides, admin guide review, places, posts, tours, bookings, payments, reviews, notifications, uploads, and travel buddy workflows.

Important backend areas:

- `controller/` exposes the REST API endpoints.
- `service/` and `service/serviceImpl/` contain the business logic.
- `repository/` contains Spring Data JPA repositories.
- `entity/` contains the main JPA database models.
- `booking/` contains the advanced guide booking, schedule, checkout, meeting landmark, tracking, and PIN workflow.
- `security/` contains JWT generation/validation, Google ID token verification, and user loading.
- `config/SecurityConfig.java` defines stateless JWT security and public/protected endpoint rules.
- `config/WebSocketConfig.java` exposes `/ws` for STOMP/SockJS messaging.
- `exception/GlobalExceptionHandler.java` formats validation and runtime errors.

### Backend Security

The backend uses Spring Security with stateless JWT authentication.

- Passwords are hashed with BCrypt.
- Login returns access and refresh JWTs.
- Refresh tokens are stored as hashes in the database.
- Protected requests use `Authorization: Bearer <accessToken>`.
- Method-level authorization uses `@PreAuthorize`.
- Public routes include authentication routes, uploaded image reads, guide registration/resubmission, approved guide search, and the WebSocket endpoint.
- Admin guide review is restricted to `ADMIN`.
- Tourist booking/payment/review flows are restricted to `TOURIST`.
- Guide profile management is restricted to `GUIDE`.
- Travel buddy chat is restricted to tourist accounts.

### Email OTP

Registration and forgot-password flows use email OTPs. The backend expects SMTP settings in local configuration. The example configuration uses Gmail SMTP, but any valid SMTP provider can be wired through Spring Mail.

### Google Sign-In

The Flutter app obtains a Google ID token. The backend verifies that ID token through `GoogleTokenService`, creates or updates a tourist account, and returns normal HISTORIA JWT tokens. Admin registration through Google is blocked, and guide account creation must use the guide registration form.

### File Uploads

The backend accepts multipart uploads for:

- post images
- historical place images
- profile images
- cover images

Uploaded files are stored under the local `uploads/` folder and are served through:

```text
/uploads/**
```

For a real deployment, this local storage should be replaced or backed by object storage such as S3, Cloudflare R2, or another durable media store.

## Database Overview

HISTORIA uses PostgreSQL with Spring Data JPA and Hibernate.

The local development database name used by the setup guide is:

```text
historia
```

The active local JDBC URL should normally be:

```text
jdbc:postgresql://localhost:5432/historia
```

Hibernate is configured with:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: update
```

This means the local database schema is created or updated from the JPA entities when the backend starts. That is convenient for development, but production should use reviewed migrations instead of relying only on automatic schema updates.

### Main Database Tables

| Table | Purpose |
| --- | --- |
| `users` | Tourist, guide, and admin accounts, credentials, profile fields, provider data, OTP fields, token hashes, status flags |
| `guide_profiles` | Guide application/profile data, service areas, languages, specialties, approval status, admin notes |
| `historical_places` | Historical place catalogue used by discovery and tour planning |
| `posts` | Community feed posts |
| `post_comments` | Comments on community posts |
| `tours` | Tourist-created tour plans |
| `tour_places` | Historical places attached to a tour and their progress state |
| `bookings` | Legacy/demo booking records used by checkout and review flow |
| `payments` | Payment attempts for `bookings`; stores amount, status, transaction ref and masked card details only |
| `reviews` | Tourist reviews for paid bookings and guides |
| `buddy_requests` | Travel buddy requests and acceptance/rejection state |
| `buddy_messages` | Travel buddy conversation messages |
| `app_notifications` | Stored in-app notifications |
| `forgot_password` | Password reset OTP data |
| `guide_booking_packages` | Guide-owned package definitions, duration, price, and visitor limits |
| `guide_booking_windows` | Guide availability windows |
| `guide_meeting_landmarks` | Configured meeting landmarks |
| `guide_bookings` | Advanced guide reservations with hold/payment/tracking/PIN state |
| `guide_booking_evidence` | Demo/certification/rating evidence records for guide discovery |

## Guide Booking Workflow

The advanced booking module is under:

```text
backend/src/main/java/com/historia/backend/booking
frontend/lib/booking
```

It covers the FR13-FR15 guide booking requirements.

### Traveler Flow

1. The tourist opens the guide directory.
2. The app loads approved, enabled guides.
3. The tourist filters by area, language, specialty, certification, rating, date, and time.
4. The tourist chooses a guide package.
5. The app loads available slots for the selected package/date.
6. The tourist chooses party size and meeting landmark.
7. The backend creates a temporary hold with an idempotency request key.
8. The tourist reviews checkout details and pays.
9. A confirmed booking receives a meeting PIN.
10. The guide can move through en route, arrived, in progress, and completed states.
11. The tourist can see guide ETA/location freshness while tracking is active.

### Backend Rules

- Times are handled in the `Asia/Colombo` zone for booking display logic.
- Guide availability is built from `GuideWindow` records.
- Slots are generated in 30-minute increments.
- A hold expires after 10 minutes.
- Overlapping active reservations are rejected.
- Concurrent overlapping bookings are protected with database locking.
- Repeated hold retries reuse the same booking only when the request payload matches the original request key.
- Booking amount, package name, and end time are snapshotted so later package edits do not change existing reservations.
- A guide must be approved and enabled to receive bookings.
- Meeting landmarks must match the guide service area.
- The guide can publish location only during active tracking states.
- The meeting PIN is random, expires, has an attempt limit, and is single-use.
- Terminal booking states hide live location and PIN data.

### Payment Boundary

The app has two payment paths:

- `/api/bookings/{bookingId}/payments` supports the existing checkout/payment flow for `bookings`.
- `/api/guide-bookings/{id}/payments` supports the advanced guide booking checkout flow.

Payment in this academic project is a controlled mock/demo flow. Card details are validated in memory. The backend stores only masked card information, amount, currency, payment status, failure reason if any, and a generated transaction reference.

For production, the payment success state should come only from a trusted server-side payment gateway callback. The booking module already includes an internal `confirmVerifiedPayment` boundary for that direction.

## Frontend Overview

The Flutter app lives in `frontend/`.

The app starts from:

```text
frontend/lib/main.dart
```

`HomeRouter` decides the first authenticated screen by role:

| Role | Screen |
| --- | --- |
| Not logged in | `LaunchScreen` |
| `TOURIST` | `TouristHomeScreen` |
| `GUIDE` | `GuideHomeScreen` |
| `ADMIN` | `AdminHomeScreen` |

### Frontend Areas

- `auth/` contains launch, login, signup, OTP, forgot password, account type, guide signup, guide pending, and guide resubmission screens.
- `tourist/` contains tourist home, historical search/details, tour planner, travel buddy, buddy chat, checkout, payment result, reviews, posts, and notifications.
- `booking/` contains the advanced guide directory, booking flow, booking provider, booking models, guide management, guide payment, guide tracker, and my bookings screens.
- `guide/` contains guide home and pending states.
- `admin/` contains admin home and place management.
- `services/` wraps backend API calls.
- `providers/` stores app-level auth state.
- `theme/` contains the shared HISTORIA visual theme.
- `widgets/` contains reusable UI components.

### API Configuration

The frontend reads the backend URL from the `API_BASE_URL` dart define.

Defaults:

| Target | Base URL |
| --- | --- |
| Flutter web | `http://localhost:8081` |
| Android emulator | `http://10.0.2.2:8081` |
| Other local targets | `http://localhost:8081` |

The helper script `scripts/Run-Flutter.ps1` sets the correct URL for emulator, Chrome, USB, and Wi-Fi testing.

### Token Handling

The frontend stores:

- access token
- refresh token
- current user profile

`ApiService` attaches the access token to protected requests. If a protected request returns `401`, it attempts token refresh and retries the original request once.

## REST API Overview

The backend base URL during local development is:

```text
http://localhost:8081
```

### Authentication

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| POST | `/api/auth/register` | Register a tourist account and send verification OTP | Public |
| POST | `/api/auth/verify-email` | Verify account email with OTP | Public |
| POST | `/api/auth/resend-otp` | Resend signup OTP | Public |
| POST | `/api/auth/login` | Log in with username/email/phone and password | Public |
| POST | `/api/auth/refresh` | Refresh access and refresh JWT pair | Public with refresh token |
| POST | `/api/auth/google` | Verify Google ID token and log in | Public |
| POST | `/api/auth/password/forgot` | Send forgot-password OTP | Public |
| POST | `/api/auth/password/verify` | Verify forgot-password OTP | Public |
| POST | `/api/auth/password/resend` | Resend forgot-password OTP | Public |
| POST | `/api/auth/password/reset` | Reset password after OTP verification | Public |

### Users

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/users/me` | Get current user profile | JWT |
| PUT | `/api/users/me` | Update profile fields | JWT |
| PUT | `/api/users/me/password` | Change current password | JWT |
| POST | `/api/users/logout` | Clear stored refresh token / mark offline | JWT |
| DELETE | `/api/users/me` | Soft-delete current account | JWT |

### Guides And Admin Review

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| POST | `/api/guides/register` | Submit a guide application | Public |
| POST | `/api/guides/resubmit` | Resubmit a needs-work guide application | Public |
| GET | `/api/guides/me` | Get current guide profile | GUIDE |
| PUT | `/api/guides/me` | Update current guide profile | GUIDE |
| GET | `/api/guides/approved` | Search approved guides | Public |
| GET | `/api/admin/guides` | List guide applications by status | ADMIN |
| PUT | `/api/admin/guides/{guideProfileId}/review` | Approve, reject, or request changes | ADMIN |

### Historical Places

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/places` | List places | JWT |
| GET | `/api/places/trending` | List top tour/trending places | JWT |
| GET | `/api/places/top-tours` | Alternative top-tour mapping | JWT |
| GET | `/api/places/{id}` | Get one place | JWT |
| GET | `/api/places/search` | Search places | JWT |
| POST | `/api/places` | Create place | ADMIN |
| PUT | `/api/places/{id}` | Update place | ADMIN |
| DELETE | `/api/places/{id}` | Delete place | ADMIN |

### Uploads

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| POST | `/api/uploads/post-image` | Upload community post image | JWT |
| POST | `/api/uploads/place-image` | Upload historical place image | ADMIN |
| POST | `/api/uploads/profile-image` | Upload profile image | TOURIST, GUIDE, ADMIN |
| POST | `/api/uploads/cover-image` | Upload cover image | TOURIST, GUIDE, ADMIN |
| GET | `/uploads/**` | Read uploaded file | Public |

### Community Posts

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/posts` | List posts | TOURIST, GUIDE, ADMIN |
| GET | `/api/posts/{id}` | Get one post | TOURIST, GUIDE, ADMIN |
| POST | `/api/posts` | Create post | TOURIST, GUIDE, ADMIN |
| PUT | `/api/posts/{id}/like` | Like/unlike post | TOURIST, GUIDE, ADMIN |
| GET | `/api/posts/{id}/comments` | List comments | TOURIST, GUIDE, ADMIN |
| POST | `/api/posts/{id}/comments` | Add comment | TOURIST, GUIDE, ADMIN |
| PUT | `/api/posts/{postId}/comments/{commentId}/like` | Like/unlike comment | TOURIST, GUIDE, ADMIN |
| DELETE | `/api/posts/{id}` | Delete post | TOURIST, GUIDE, ADMIN |

### Tours

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| POST | `/api/tours` | Create tour plan | TOURIST |
| GET | `/api/tours/{id}` | Get one tour | TOURIST |
| GET | `/api/tours/user/{userId}` | List tours for user | TOURIST |
| PUT | `/api/tours/{tourId}/places/{historicalPlaceId}/complete` | Mark tour place complete | TOURIST |
| PUT | `/api/tours/{tourId}/places/{historicalPlaceId}/status` | Update tour place status | TOURIST |
| PUT | `/api/tours/{tourId}/complete` | Complete a tour | TOURIST |
| DELETE | `/api/tours/{id}` | Delete tour | TOURIST |

### Travel Buddy

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/buddies/search` | Search tourist buddy matches | TOURIST |
| POST | `/api/buddies/requests` | Send buddy request | TOURIST |
| GET | `/api/buddies/requests/received` | List received requests | TOURIST |
| GET | `/api/buddies/requests/sent` | List sent requests | TOURIST |
| GET | `/api/buddies/conversations` | List accepted conversations | TOURIST |
| PUT | `/api/buddies/requests/{requestId}/accept` | Accept request | TOURIST |
| PUT | `/api/buddies/requests/{requestId}/reject` | Reject request | TOURIST |
| POST | `/api/buddies/{requestId}/messages` | Send REST buddy message | TOURIST |
| GET | `/api/buddies/{requestId}/messages` | List messages | TOURIST |
| PUT | `/api/buddies/{requestId}/read` | Mark conversation read | TOURIST |
| WS | `/ws` with `/app/buddies/{requestId}/send` | Send STOMP buddy message | TOURIST |
| Topic | `/topic/buddies/{requestId}` | Receive buddy messages | TOURIST participants |

### Basic Booking, Payment, Reviews

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/bookings/{id}` | Get checkout summary for a booking | TOURIST |
| GET | `/api/bookings/me` | List current tourist bookings | TOURIST |
| POST | `/api/bookings/demo` | Create sample booking for checkout/review testing | TOURIST |
| POST | `/api/bookings/{bookingId}/payments` | Pay for a booking | TOURIST |
| POST | `/api/reviews` | Submit review | TOURIST |
| GET | `/api/reviews/me` | List my reviews | TOURIST |
| GET | `/api/reviews/guide/{guideProfileId}` | List guide reviews | JWT |
| GET | `/api/reviews/guide/{guideProfileId}/summary` | Get guide rating summary | JWT |
| PUT | `/api/reviews/{reviewId}` | Update own review | TOURIST |
| DELETE | `/api/reviews/{reviewId}` | Delete own review | TOURIST |

### Advanced Guide Booking

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/guide-bookings/guides` | Discover bookable guides with filters | JWT |
| GET | `/api/guide-bookings/landmarks` | List meeting landmarks | JWT |
| GET | `/api/guide-bookings/slots` | List available start times for guide/package/date | JWT |
| GET | `/api/guide-bookings` | List my guide booking reservations | JWT |
| POST | `/api/guide-bookings` | Create booking hold | TOURIST account required in service |
| GET | `/api/guide-bookings/{id}` | Get reservation details | Participant only |
| GET | `/api/guide-bookings/{id}/checkout` | Get checkout data for a held reservation | Tourist owner only |
| POST | `/api/guide-bookings/{id}/payments` | Pay for held guide reservation | Tourist owner only |
| POST | `/api/guide-bookings/{id}/demo-checkout` | Demo checkout success/failure/cancel when enabled | Tourist owner only |
| POST | `/api/guide-bookings/{id}/state` | Change booking state | Guide for service transitions; tourist can cancel allowed states |
| POST | `/api/guide-bookings/{id}/location` | Publish guide location and ETA | Assigned guide only |
| POST | `/api/guide-bookings/{id}/verify-pin` | Verify meeting PIN | Assigned guide only |
| GET | `/api/guide-bookings/management` | Get guide packages and availability windows | GUIDE |
| PUT | `/api/guide-bookings/management/packages` | Create/update guide package | GUIDE |
| POST | `/api/guide-bookings/management/windows` | Add availability window | GUIDE |
| DELETE | `/api/guide-bookings/management/windows/{id}` | Remove availability window | GUIDE |

### Notifications

| Method | Endpoint | Description | Auth |
| --- | --- | --- | --- |
| GET | `/api/notifications/me` | List current user's notifications | JWT |
| GET | `/api/notifications/me/unread-count` | Get unread count | JWT |
| PATCH | `/api/notifications/{id}/read` | Mark one notification as read | JWT |
| PATCH | `/api/notifications/read-all` | Mark all notifications as read | JWT |

## Local Setup

### Prerequisites

Install these before running the project:

- Git
- Java JDK 17
- PostgreSQL
- Flutter SDK with Dart 3.12.2 or newer
- Android Studio with Android SDK and an emulator
- Gmail account with an app password, if testing OTP email
- Google Cloud OAuth Web client ID, if testing Google Sign-In

After installing Flutter, run:

```powershell
flutter doctor
```

Fix any required Android/Flutter toolchain issues before running the mobile app.

### Clone The Repository

```powershell
git clone https://github.com/Anuradha-dol/it3060-hci-historia-mobile-app-group82.git
cd it3060-hci-historia-mobile-app-group82
```

## Backend Setup

### 1. Create PostgreSQL Database

Start PostgreSQL, then create a database named `historia`.

```powershell
psql -U postgres
```

Inside the PostgreSQL shell:

```sql
CREATE DATABASE historia;
\q
```

### 2. Create Local Backend Configuration

Copy the example file:

```powershell
Copy-Item backend\src\main\resources\application-local.example.yml backend\src\main\resources\application-local.yml
```

Update the copied file with your local values.

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/historia
    username: postgres
    password: YOUR_POSTGRES_PASSWORD
  mail:
    username: YOUR_GMAIL_ADDRESS
    password: YOUR_GMAIL_APP_PASSWORD

jwt:
  secret: YOUR_BASE64_JWT_SECRET

google:
  oauth:
    client-id: YOUR_GOOGLE_WEB_CLIENT_ID

admin:
  username: admin
  email: admin@historia.com
  phone: "0700000000"
  password: CHANGE_THIS_ADMIN_PASSWORD
```

`application-local.yml` is for your own machine and should not be committed.

Generate a strong Base64 JWT secret in PowerShell:

```powershell
$bytes = New-Object byte[] 64
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

### 3. Run The Backend

```powershell
cd backend
.\mvnw.cmd clean test
.\mvnw.cmd spring-boot:run
```

The backend runs at:

```text
http://localhost:8081
```

## Frontend Setup

Open a second terminal in the project root.

### Android Emulator

```powershell
.\scripts\Run-Flutter.ps1 -Target emulator
```

This uses:

```text
http://10.0.2.2:8081
```

### Chrome

```powershell
.\scripts\Run-Flutter.ps1 -Target chrome
```

This uses:

```text
http://localhost:8081
```

and runs Chrome on:

```text
http://localhost:5300
```

### Android Phone Over USB

```powershell
.\scripts\Run-Flutter.ps1 -Target usb
```

The script runs:

```text
adb reverse tcp:8081 tcp:8081
```

and uses:

```text
http://127.0.0.1:8081
```

### Android Phone On Same Wi-Fi

```powershell
.\scripts\Run-Flutter.ps1 -Target wifi -LaptopIp 192.168.1.10
```

Replace `192.168.1.10` with your laptop's LAN IP address. Make sure Windows Firewall allows inbound traffic to backend port `8081`.

### Optional Google Client Override

```powershell
.\scripts\Run-Flutter.ps1 -Target emulator -GoogleWebClientId YOUR_GOOGLE_WEB_CLIENT_ID
```

The same Web client ID must be configured in the backend `application-local.yml`.

## Useful Commands

Backend:

```powershell
cd backend
.\mvnw.cmd test
.\mvnw.cmd spring-boot:run
```

Frontend:

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
```

Run the app from the repository root:

```powershell
.\scripts\Run-Flutter.ps1 -Target emulator
.\scripts\Run-Flutter.ps1 -Target chrome
.\scripts\Run-Flutter.ps1 -Target usb
.\scripts\Run-Flutter.ps1 -Target wifi -LaptopIp 192.168.1.10
```

## Tests And Verification

Backend tests are under:

```text
backend/src/test/java
```

Important backend test coverage:

- guide booking pricing and capacity rules
- booking hold idempotency
- concurrent overlapping reservation protection
- expired hold behavior
- participant-only read/tracking/PIN access
- payment success/failure/cancel behavior
- trusted payment boundary validation
- guide state transitions
- meeting PIN attempt limit, expiry, and single-use behavior
- guide discovery filters
- existing route smoke checks

Frontend tests are under:

```text
frontend/test
```

Important frontend test coverage:

- booking package pricing and visitor limits
- preserved selections between booking steps
- double-tap protection and retry idempotency key reuse
- out-of-order slot response protection
- secure booking cache owner scoping
- stale location and local PIN expiry handling
- responsive booking flow at narrow mobile widths

Detailed component verification notes are stored in:

```text
docs/component4/TEST_RESULTS.md
```

## Project Documents

| Document | Purpose |
| --- | --- |
| `START_HERE.md` | Detailed clean-laptop setup and component 4 guidance |
| `docs/component4/proposal.pdf` | Supplied project/component proposal |
| `docs/component4/IMPLEMENTATION_NOTES.md` | Technical implementation notes for guide booking |
| `docs/component4/API_AND_PAYMENT_CONTRACT.md` | Guide booking API and payment integration contract |
| `docs/component4/MANUAL_SETUP.md` | Manual setup notes |
| `docs/component4/RUN_AND_DEMO.md` | Demo run instructions |
| `docs/component4/TEST_RESULTS.md` | Recorded test and verification evidence |

## Common Problems

### Backend cannot connect to PostgreSQL

Check that:

- PostgreSQL is running.
- The `historia` database exists.
- The username and password in `application-local.yml` are correct.
- Port `5432` is available.

### Backend starts but OTP email does not arrive

Check that:

- `spring.mail.username` is set.
- `spring.mail.password` is a Gmail app password or valid SMTP password.
- The email provider allows SMTP access.

### Google Sign-In fails

Check that:

- The backend `google.oauth.client-id` is set to the Web client ID.
- The Flutter app uses the same Web client ID.
- For Android, the Google Cloud Android client has package name `com.example.frontend`.
- Your emulator/device debug SHA-1 is registered in Google Cloud.
- For Chrome, `http://localhost:5300` is an authorized JavaScript origin.

### Flutter app cannot reach backend

Check that:

- The backend is running on port `8081`.
- You used the correct `Run-Flutter.ps1` target.
- Android emulator uses `10.0.2.2`.
- USB mode ran `adb reverse`.
- Wi-Fi mode uses the laptop LAN IP and firewall allows port `8081`.

### Uploaded images do not show

Check that:

- The backend has the file under `uploads/`.
- The API image URL resolves through the same backend host used by the app.
- `ApiConfig.resolveImageUrl` can rewrite local image URLs for emulator/phone targets.

## Current Status

The repository contains a working Flutter + Spring Boot + PostgreSQL application with the main HISTORIA workflows implemented:

- authentication and profile management
- tourist, guide, and admin role routing
- historical place discovery
- tour planning
- community feed
- travel buddy matching and messaging
- guide application review
- guide booking, scheduling, meeting logistics, checkout, tracking, and PIN validation
- payment and review support
- notifications

The app is suitable for local academic demonstration. Before production deployment, the project should add explicit database migrations, production media storage, real payment gateway integration, production SMTP/OAuth configuration, deployment profiles, and broader device testing.

## Security Notes

Do not commit real secrets.

Keep these values local or in deployment secrets:

- PostgreSQL passwords
- JWT secret
- Gmail app password or SMTP password
- Google OAuth credentials
- payment gateway keys
- production host/domain secrets

The repository includes `application-local.example.yml` so another developer can see the required configuration shape without exposing private values.

## Future Improvements

- Add Swagger/OpenAPI documentation for all REST endpoints.
- Replace automatic schema updates with reviewed database migrations.
- Move uploaded media to durable object storage.
- Integrate a real payment gateway and refund workflow.
- Add production deployment configuration.
- Add more end-to-end tests on Android devices.
- Add richer admin dashboards for bookings, places, posts, users, and payment status.
- Expand guide certification/rating evidence beyond demo records.

## About This Project

HISTORIA was developed to demonstrate a complete mobile HCI project, not only static screens. The app connects Flutter UI flows to real Spring Boot APIs, persists data in PostgreSQL, protects workflows with JWT roles, handles image uploads, supports live buddy messaging, and includes an advanced guide booking flow with realistic constraints such as schedule conflicts, idempotent booking holds, meeting logistics, and secure guide arrival confirmation.
