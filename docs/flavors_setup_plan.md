# Flutter Flavors Setup Plan

Source brief: set up SandwichAi Flutter flavors using the Dev / Staging / Prod pattern from the linked video: https://www.youtube.com/watch?v=EyQfuKvVUGY

Official references:
- Android flavors: https://docs.flutter.dev/deployment/flavors
- iOS and macOS flavors: https://docs.flutter.dev/deployment/flavors-ios

## Goal

Create three buildable app flavors for SandwichAi:

- `dev`: daily development and test accounts.
- `staging`: release-candidate testing against staging backend services.
- `prod`: store/release builds against production services, with dev login disabled.

Each flavor should have its own Dart entrypoint, app name, package/bundle identifier, API base URLs, AI base URL, dev-login behavior, and launch/build command.

## Implementation Status

- Dart entrypoints and shared bootstrap: implemented.
- Android product flavors and launcher labels: implemented.
- Feature flags by flavor: implemented for dev login, AI recipe forecast, AI wastage analysis, payment, printer, and scanner.
- PowerShell helper scripts: implemented.
- iOS schemes/build configurations: pending Xcode/macOS setup.

## Current Repo State

- The app currently has one entrypoint: `lib/main.dart`.
- API URLs are hard-coded in `lib/src/core/network/api_engine_public/api_constants.dart`.
- Dev-login values are hard-coded in `lib/src/core/config/dev_login_config.dart`.
- Android uses Kotlin Gradle DSL in `android/app/build.gradle.kts`.
- Android currently has one `applicationId`: `com.sandwichai.app`.
- iOS currently has one shared `Runner` scheme.
- `flutter_launcher_icons` is already present and can be reused for flavor-specific icons if needed.

## Proposed Flavor Matrix

| Flavor | App Name | Android Application ID | iOS Bundle ID | Purpose |
| --- | --- | --- | --- | --- |
| `dev` | SandwichAi Dev | `com.sandwichai.app.dev` | `com.sandwichai.app.dev` | Local/dev testing with dev-login shortcuts. |
| `staging` | SandwichAi Staging | `com.sandwichai.app.staging` | `com.sandwichai.app.staging` | QA/UAT and release-candidate testing. |
| `prod` | SandwichAi | `com.sandwichai.app` | `com.sandwichai.app` | Real production release. |

Final IDs can be adjusted before implementation if app-store records or backend OAuth/callback constraints require different values.

## Phase 1: Dart Entrypoints and Environment Layer

1. Extract the current bootstrapping in `lib/main.dart` into a shared app runner, for example `lib/src/core/config/app_bootstrap.dart`.
2. Keep one shared app widget and one shared initialization path so Hive boxes, notifications, theme loading, providers, and routing do not get copied across entrypoints.
3. Add separate entrypoint files:
   - `lib/main_dev.dart`
   - `lib/main_staging.dart`
   - `lib/main_prod.dart`
4. Each entrypoint should call the shared bootstrap with an explicit environment object instead of relying only on command-line flags.
5. Add `lib/src/core/config/app_environment.dart`.
6. Define an enum: `AppFlavor.dev`, `AppFlavor.staging`, `AppFlavor.prod`.
7. Centralize:
   - `flavor`
   - `appName`
   - `apiBaseUrl`
   - `aiBaseUrl`
   - `devLoginEnabled`
   - optional default dev organization code and user credentials
8. Update `ApiConstants.baseUrl` and `ApiConstants.aiBaseUrl` to read from `AppEnvironment`.
9. Update `DevLoginConfig` so production builds cannot expose dev-login shortcuts.
10. Update `MaterialApp.router(title: ...)` to use the environment app name.

Expected command shape:

```powershell
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Entrypoint shape:

```dart
// lib/main_dev.dart
Future<void> main() {
  return bootstrapSandwichAi(AppEnvironment.dev());
}
```

The existing `lib/main.dart` can either become a safe alias to production or be reduced to a short comment directing developers to use the flavor entrypoints. Recommended: keep it as a production alias so existing tooling does not break unexpectedly.

## Phase 2: Android Flavor Setup

1. Edit `android/app/build.gradle.kts`.
2. Add a flavor dimension, for example `environment`.
3. Add product flavors:
   - `dev`
   - `staging`
   - `prod`
4. Set per-flavor values:
   - `applicationIdSuffix` for `dev` and `staging`
   - `resValue("string", "app_name", "...")`
   - optional `manifestPlaceholders`
5. Update `android/app/src/main/AndroidManifest.xml` so the app label reads `@string/app_name`.
6. Keep the existing release signing config, but ensure only prod release builds are treated as store-ready.
7. Verify commands:

```powershell
flutter run --flavor dev -t lib/main_dev.dart
flutter build apk --flavor staging -t lib/main_staging.dart --release
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
```

## Phase 3: iOS Flavor Setup

1. Open `ios/Runner.xcworkspace` in Xcode on macOS.
2. Create schemes:
   - `dev`
   - `staging`
   - `prod`
3. Add build configurations for each environment:
   - `Debug-dev`, `Profile-dev`, `Release-dev`
   - `Debug-staging`, `Profile-staging`, `Release-staging`
   - `Debug-prod`, `Profile-prod`, `Release-prod`
4. Add `.xcconfig` files for each flavor if needed, or extend the current Flutter configs.
5. Configure:
   - `PRODUCT_BUNDLE_IDENTIFIER`
   - `APP_DISPLAY_NAME`
   - signing team/provisioning profiles
6. Update `ios/Runner/Info.plist` display name to use a build setting such as `$(APP_DISPLAY_NAME)`.
7. Verify commands:

```powershell
flutter run --flavor dev -t lib/main_dev.dart
flutter build ios --flavor staging -t lib/main_staging.dart --release
flutter build ipa --flavor prod -t lib/main_prod.dart --release
```

## Phase 4: Local Run Scripts

Add small scripts or documented commands so the team does not have to remember the full flavor command each time.

Recommended files:

- `scripts/run_dev.ps1`
- `scripts/run_staging.ps1`
- `scripts/build_prod_android.ps1`

Each script should pass the same flavor every time. With separate entrypoints, scripts should always pass both `--flavor` and `-t`.

Implemented scripts:

- `scripts/run_dev.ps1`
- `scripts/run_staging.ps1`
- `scripts/build_prod_android.ps1`

## Phase 5: Launcher Icons and Names

1. Decide if flavors need visually distinct icons.
2. If yes, configure `flutter_launcher_icons` per flavor or add separate Android/iOS icon assets manually.
3. Use simple labels:
   - Dev: `SandwichAi Dev`
   - Staging: `SandwichAi Staging`
   - Prod: `SandwichAi`
4. Keep production branding clean and free of internal environment labels.

## Phase 6: Verification Checklist

Run after implementation:

```powershell
dart analyze lib/src/core/config lib/src/core/network lib/main.dart
dart analyze lib/main_dev.dart lib/main_staging.dart lib/main_prod.dart
flutter run --flavor dev -t lib/main_dev.dart
flutter build apk --flavor staging -t lib/main_staging.dart --release
flutter build apk --flavor prod -t lib/main_prod.dart --release
```

Manual checks:

- Dev and staging can install beside production on Android.
- App names are distinct on the launcher.
- Dev login appears only in allowed flavors.
- Production points to production backend URLs.
- Staging points to staging backend URLs.
- Login, notifications, POS, kitchen, and branch cache still work after flavor switching.

## Feature Flag Defaults

Feature flags live in `lib/src/core/config/app_environment.dart`.

Current defaults:

| Flavor | Disabled Features |
| --- | --- |
| `dev` | None |
| `staging` | `aiForecast`, `wastageAnalysis`, `payment`, `printer`, `scanner` |
| `prod` | `devLogin` |

The Processing bottom nav keeps the AI tabs in place, but disabled flavors show a feature-unavailable screen instead of loading the AI workflow. The repositories also block disabled AI requests so direct calls cannot bypass the UI.
POS payment calls, kitchen printing, printer testing, and printer discovery are also blocked at their service/repository layers when disabled. The POS drawer routes disabled Printer Settings to the shared feature-unavailable screen.

## Implementation Order

1. Extract shared bootstrap code from `lib/main.dart`.
2. Add `AppEnvironment` and the three explicit entrypoints.
3. Migrate API/dev-login reads to `AppEnvironment`.
4. Add Android product flavors and app label wiring.
5. Add command documentation/scripts.
6. Verify Android dev/staging/prod.
7. Add iOS schemes/configurations on macOS.
8. Verify iOS dev/staging/prod.
9. Add flavor-specific icons only after the build identities are stable.

## Risks and Decisions Needed

- Staging backend URL is not currently visible in the repo; confirm it before wiring staging.
- AI backend staging URL is not currently visible in the repo; confirm whether it differs by environment.
- iOS setup requires Xcode/macOS access.
- Production dev-login must be disabled even if a developer forgets a `--dart-define`.
- Any backend services that key off package name, bundle ID, deep links, notification credentials, or OAuth redirects may need new dev/staging registrations.
