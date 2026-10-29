# StudentGig

StudentGig currently uses a local JSON database for temporary account storage.
The JSON is stored in the platform's local preferences (browser storage on web)
and remains available after restarting the app on that same browser or device.
It is not shared across devices and is not a production authentication system.

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Register a student or employer account in the app, then log in. The forgot
password screen updates the password stored for that local account; it does not
send email. To clear the temporary web database, clear this site's browser
storage.

## Dashboards

Student accounts can search and filter sample gigs, save opportunities, and
record an application in the current session. Employer accounts can create and
remove sample gig listings. Dashboard listings and student actions are
demonstration data held in app memory; only account/session data is persisted
in the JSON database.

## Data format

The app stores user records as JSON under the `studentgig_json_database`
preference key. Passwords are stored as salted SHA-256 hashes, not plaintext.
Local browser/device storage can still be inspected or modified by its owner,
so do not use real or sensitive credentials.

The StudentGig logo asset is `assets/branding/studentgig_icon.png`; the web
favicon and installable app icons use the same supplied artwork.

## Files
- lib/main.dart
- lib/core/error/auth_failure.dart
- lib/core/utils/validators.dart
- lib/core/utils/snackbar.dart
- lib/core/router/app_router.dart
- lib/domain/entities/app_user.dart
- lib/domain/repositories/auth_repository.dart
- lib/data/repositories/json_auth_repository.dart
- lib/features/auth/application/auth_providers.dart
- lib/features/auth/presentation/login_screen.dart
- lib/features/auth/presentation/register_screen.dart
- lib/features/auth/presentation/forgot_password_screen.dart
- test/core/auth_and_validators_test.dart
- test/data/json_auth_repository_test.dart
- test/widget_test.dart
- pubspec_dependencies.yaml
