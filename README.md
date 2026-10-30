# SparkDate – Mobile (Flutter)

Sprint 1: splash, onboarding (2 pages), WhatsApp OTP login and verify, Google sign-in stub, complete profile (mock or real API).

## Run
```bash
flutter pub get
flutter run                                   # mock backend (default)
flutter run --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   # real Node API
flutter analyze && flutter test
```
Mock login: any valid Indian number → OTP **123456**. `+910000000000` simulates PROVIDER_UNAVAILABLE.

## API contract
Follows `docs/api/AUTH_PROFILE_MEDIA.md`:
- POST /auth/otp/request `{phone}` → `{expiresInSec, resendAfterSec}`; POST /auth/otp/verify `{phone, code}` → `{user, accessToken, refreshToken}`.
- Photo upload: multipart field `file` to POST /media/photos → `{key}` (≤8 MB, jpeg/png/webp).
- PUT /profile/me `{fullName, gender, interestedIn, dob, city, interests, photos:[key]}`.
- Profile reads return `photos:[{key, order, url}]`. The `url` is signed and valid for 15 min, so never persist it; cache images by `key`.
- Billing (Play Billing, `event_ticket_199`, `chat_pass_monthly`) is only a stub interface in Sprint 1.

## Structure (GetX)
```
lib/
  main.dart                 # GetMaterialApp + InitialBinding
  app/routes/               # app_routes.dart (names), app_pages.dart (GetPage + Bindings)
  app/bindings/             # InitialBinding (ApiClient, repos: mock/real), feature bindings
  core/{theme,widgets,network}
  features/<feature>/
    controllers/            # GetxController (Rx state)
    views/                  # Obx / GetView screens
    data/                   # models, repository interfaces, mock_* and remote_* impls
test/
```
State: GetX (`get`). Repositories are registered with `Get.lazyPut(fenix: true)`; `USE_MOCK` chooses mock vs remote.
