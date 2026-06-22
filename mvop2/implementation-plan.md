# SandwichAi Mobile App Developer Plan

This document is the working developer guide for the SandwichAi Flutter app. It explains what the app is, how the current codebase is organized, how new work should be implemented, and which generated or private files should stay out of Git.

## App Summary

SandwichAi is a Flutter operations app for restaurant or food-business workflows. The current app includes authentication and five main business areas:

- Auth: employee login, forgot password, reset password, change password, logout.
- POS: menu, customers, orders, payments, tables, staff, complaints, receipts, printer settings.
- Kitchen: kitchen dashboard, kitchen orders, kitchen shifts, order details.
- Procurement: suppliers, purchase orders, procurement requests, goods received, order lists.
- Processing: product intake, processing tasks, recipe compliance, output verification, stock requests, AI wastage analysis.
- Stock control: branch stock, stock catalogue, stock movement, stock adjustments, wastage logs, stock requisitions, delivery validation.

The app uses Flutter with BLoC, repositories, GoRouter, Dio networking, Hive/local storage, local notifications, file/image tools, printing/PDF, Bluetooth/USB support, QR scanning, and connectivity helpers.

## Current Technical Stack

- Flutter app name: `sandwich_ai`
- Version: `1.1.1+34`
- Dart SDK constraint: `^3.9.0`
- Routing: `go_router`
- State management: `flutter_bloc`, `equatable`
- Networking: `dio`
- Local persistence: `hive`, `hive_flutter`, `shared_preferences`, `flutter_secure_storage`
- Offline support: `connectivity_plus`, `internet_connection_checker_plus`, custom pending request queue
- Notifications: `flutter_local_notifications`, `timezone`
- POS/peripheral support: `printing`, `pdf`, `flutter_blue_plus`, `usb_serial`, `qr_flutter`, `mobile_scanner`
- App assets: `assets/svg/`, `assets/img/`, `assets/font/`

## Runtime Startup Flow

Main entry point: `lib/main.dart`

Startup sequence:

1. Ensure Flutter binding is initialized.
2. Attach the global navigator key to `NotificationService`.
3. Initialize local notifications.
4. Initialize Hive.
5. Open these Hive boxes:
   - `auth_box`
   - `onboarding_box`
   - `pending_requests`
6. Wrap the app with `AppBlocProviders`.
7. Wrap the app with `AppInitializer`.
8. Start `MaterialApp.router` using `AppRouter.router`.

Important note: `AppInitializer` already contains offline sync listener code, but it is commented out. When the offline queue is ready for production behavior, this is the natural place to re-enable connectivity-driven retries.

## Main Folder Map

```text
lib/
  main.dart                         App bootstrap and MaterialApp.router
  app_initializer.dart              App-level initialization hooks
  router/                           GoRouter routes and not-found screen
  src/
    core/
      config/                       Responsive config and production print helpers
      constant/                     Colors, image constants, text styles, DI providers
      globals/                      Shared navbars, drawer, chat, notifications, helpers
      local_sandbox/                Cache/onboarding helpers
      network/                      Dio client, interceptors, API constants, response handling
      offline/                      Pending request model, offline queue manager, sync snacks
    features/
      auth/                         Login and password flows
      kitchen/                      Kitchen dashboard, shifts, order handling
      pos/                          POS dashboard, orders, payments, customers, tables, printer
      procurement/                  Suppliers, procurement orders, purchase orders, goods received
      processing/                   Processing tasks, stock requests, compliance, output verification
      splash/                       Splash screen
      stock_control/                Stock dashboard, inventory, stock movement, wastage, requisitions
assets/
  font/                             Work Sans font files
  img/                              App images and launcher icon inputs
  svg/                              SVG icons
android/, ios/, linux/, macos/, web/, windows/
  Platform-specific Flutter projects
test/
  Flutter tests
```

## Architecture Pattern

Most features follow this shape:

```text
feature/
  data/
    model/ or models/               API/data models
    repo/ or repository/            Repository interfaces and implementations
  bloc/ or blocs/                   Events, states, blocs/cubits
  presentation/                     Screens, widgets, tabs, dialogs
```

Shared dependencies are registered in:

```text
lib/src/core/constant/di/app_providers.dart
```

When adding a new feature, follow the existing BLoC + repository pattern:

1. Create model classes for the API response/request.
2. Create a repository interface and implementation.
3. Add BLoC event/state/bloc files.
4. Register the repository and BLoC in `AppBlocProviders`.
5. Create the presentation screens/widgets.
6. Add the route in `lib/router/router.dart`.
7. Connect navigation from the relevant navbar/drawer/dashboard.
8. Add validation, loading, empty, success, and error states.
9. Add tests for model parsing, repository behavior, and BLoC state transitions when possible.

## API And Network Notes

API constants live in:

```text
lib/src/core/network/api_engine_public/api_constants.dart
```

Current endpoints:

- Main API base URL: `https://sandwichai-api-3wcql.ondigitalocean.app/`
- AI API base URL: `https://lionfish-app-o5cz2.ondigitalocean.app/api/ai/`

Network configuration:

- Connect timeout: 30 seconds
- Receive timeout: 30 seconds
- Send timeout: 30 seconds
- Max retries: 3
- Retry delay: 1 second
- Cache timeout: 5 minutes
- Max upload size: 10 MB
- Allowed image formats: `jpg`, `jpeg`, `png`, `gif`
- Allowed document formats: `pdf`, `doc`, `docx`

Implementation rule: keep raw HTTP/Dio work in repositories or network helpers. Screens should call BLoCs, not Dio directly.

## Routing Map

Routing lives in `lib/router/router.dart`.

Key routes:

- `/splash`: splash screen
- `/`: employee login
- `/forgot-password`: forgot password
- `/reset-password`: reset password
- `/Processing-nav`: processing main shell
- `/processing-req`: validate stock transfer to processing
- `/output-ver-proc`: processing output verification
- `/recipe-compl`: recipe compliance
- `/Pos-nav`: POS main shell
- `/customer-dtls`: create/edit customer
- `/customer-list`: customer list
- `/pos-dash`: POS dashboard
- `/pos-request`: POS requisition
- `/my-task`: POS task screen
- `/order-screen`: POS order screen
- `/order-summary`: POS order summary
- `/pos-staff-screen`: POS staff screen
- `/complaints`: complaints
- `/table-mgt`: table management
- `/Procurement-nav`: procurement main shell
- `/procuremnt-dash`: procurement dashboard
- `/order-form`: order form
- `/order-list`: order list
- `/procurement_orders`: procurement orders
- `/procurement_requests`: procurement requests
- `/Stock-control-nav`: stock control main shell
- `/stock-req`: stock transfer to processing/kitchen
- `/Kitchen-nav`: kitchen main shell
- `/kitchen-shift`: kitchen shift tabs
- `/kitchen-order-dtls/:orderNumber`: kitchen order details

Route naming currently has mixed spelling and casing, for example `procuremnt` and uppercase route paths. New routes should be consistent and should avoid typos when possible, while existing routes should not be renamed without checking every navigation call.

## Feature Implementation Plan

Use this sequence when building new app work.

### Phase 1: Stabilize Developer Setup

- Keep Flutter and Dart versions consistent across developers.
- Ensure Android builds use Android Studio JBR or a configured `JAVA_HOME`.
- Keep `android/local.properties` local only.
- Keep signing files out of Git.
- Run `flutter pub get` after dependency changes.
- Run `flutter analyze` before merging feature work.
- Run `flutter build apk --debug` after Android config changes.

### Phase 2: Authentication And Session

- Confirm `auth_box` stores only the minimum session data needed.
- Move sensitive tokens to `flutter_secure_storage` where possible.
- Add a single auth/session service if token handling is repeated across repos.
- Confirm logout clears Hive, secure storage, queued auth headers, and navigation stack.
- Add guards/redirects around protected routes if users can navigate without a valid session.

### Phase 3: API Layer Hardening

- Centralize headers, auth token injection, retry, timeout, and error handling in the Dio client/interceptors.
- Keep repository methods typed and return predictable success/error models.
- Standardize file upload validation using `ApiConstants`.
- Add clear user-facing messages for timeout, offline, validation, auth-expired, and server errors.

### Phase 4: Offline Queue

- Review `lib/src/core/offline/`.
- Define which requests can safely be retried.
- Store pending requests in `pending_requests`.
- Re-enable the `ConnectivityService` listener in `AppInitializer` when retry behavior is production-ready.
- Add conflict rules for duplicate stock movements, payments, orders, and procurement requests.

### Phase 5: Module Completion

- Auth: complete login, password reset, change password, logout, route protection.
- POS: complete menu flow, cart/order summary, payment, receipt, table handling, printer/Bluetooth/USB paths.
- Kitchen: complete order list, order details, status updates, shift management.
- Procurement: complete supplier management, order creation, goods received, procurement request history.
- Processing: complete product intake, processing tasks, stock requests, output verification, recipe compliance, AI wastage analysis.
- Stock control: complete stock catalogue, stock movement, adjustments, wastage logs, branch stock, stock requisitions.

### Phase 6: Quality Gates

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Release build with valid signing files before Play Store/internal distribution.
- Manual smoke test on a real Android device for camera, scanner, notifications, storage, printer/Bluetooth/USB, and offline sync.

## Android Build Notes

Two Android build issues were fixed in this workspace:

1. `android/app/build.gradle.kts` no longer crashes debug builds when release keystore properties are missing.
2. `android/gradle.properties` has `kotlin.incremental=false` to avoid the Windows cross-drive Kotlin cache failure when the project is on `D:` and Pub cache plugins are on `C:`.

For release builds, create `android/key.properties` locally with:

```properties
keyAlias=your-key-alias
keyPassword=your-key-password
storeFile=path/to/your-release-key.jks
storePassword=your-store-password
```

Do not commit `android/key.properties`, `.jks`, or `.keystore` files.

## Git Ignore Plan

Git should keep source code, assets, configuration templates, tests, docs, and lockfiles that the team needs. Git should ignore generated outputs, local machine paths, caches, secrets, signing files, and editor/build temporary files.

### Ignore These Root Folders And Files

- `.dart_tool/`
- `.pub-cache/`
- `.pub/`
- `build/`
- `coverage/`
- `.gradle/`
- `.idea/`
- `.history/`
- `.env`
- `.env.*`
- `*.local`
- `*.log`
- `*.tmp`
- `*.temp`
- `tmp/`
- `temp/`
- `reports/`
- `*.iml`
- `*.ipr`
- `*.iws`
- `.DS_Store`
- `app.*.symbols`
- `app.*.map.json`

### Ignore Android Generated Or Private Files

- `android/local.properties`
- `android/.gradle/`
- `android/app/build/`
- `android/app/debug/`
- `android/app/profile/`
- `android/app/release/`
- `android/key.properties`
- `key.properties`
- `*.jks`
- `*.keystore`

### Ignore iOS Generated Or Private Files

- `ios/Pods/`
- `ios/.symlinks/`
- `ios/Flutter/ephemeral/`
- `ios/Flutter/Generated.xcconfig`
- `ios/Flutter/flutter_export_environment.sh`
- `ios/Flutter/App.framework`
- `ios/Flutter/Flutter.framework`
- `ios/Flutter/flutter_assets/`
- `ios/Runner/GeneratedPluginRegistrant.*`
- `ios/DerivedData/`
- `ios/xcuserdata/`

### Ignore Desktop Platform Build Artifacts

- `linux/flutter/ephemeral/`
- `macos/Flutter/ephemeral/`
- `windows/flutter/ephemeral/`
- `windows/flutter/generated_plugin_registrant.cc` if the team chooses not to track generated desktop registrants
- `windows/flutter/generated_plugin_registrant.h` if the team chooses not to track generated desktop registrants
- `linux/flutter/generated_plugin_registrant.cc` if the team chooses not to track generated desktop registrants
- `linux/flutter/generated_plugin_registrant.h` if the team chooses not to track generated desktop registrants
- `macos/Flutter/GeneratedPluginRegistrant.swift` if the team chooses not to track generated desktop registrants

Note: Flutter desktop generated registrant files are sometimes committed depending on project policy. This repo already has tracked generated registrant files, so do not remove them unless the team decides to stop tracking them across all desktop platforms.

### Do Not Ignore These Important Project Files

- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `.metadata`
- `lib/`
- `assets/`
- `test/`
- `android/`, except local/generated/private files above
- `ios/`, except local/generated/private files above
- `web/`
- `linux/`, `macos/`, `windows/` if desktop targets remain supported
- `README.md`
- `mvop2/`

## Daily Development Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Clean rebuild:

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

Android Gradle daemon stop on this machine:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
cd android
.\gradlew.bat --stop
```

## Release Checklist

- App name, package name, launcher icons, and splash assets are final.
- `version` in `pubspec.yaml` is bumped.
- Android signing files exist locally and are not committed.
- Production API URLs are confirmed.
- Debug logs and test-only routes are removed or guarded.
- `flutter analyze` passes.
- `flutter test` passes.
- Debug APK build passes.
- Release APK/AAB build passes.
- Real-device smoke test passes.
- Offline queue behavior is tested with network on/off.
- Login/logout/session expiry are tested.
- POS payment and receipt/printer flows are tested.
- Camera/scanner permissions are tested.
- Notification permissions are tested.

## Suggested Next Refactors

- Standardize typo-heavy names over time, for example `procuremnt`, `chnage`, `cnage`, `reciet`, `dashboradd`, and `wasage`.
- Keep route names lowercase and consistent.
- Split `AppBlocProviders` when it becomes too large, for example one provider file per module.
- Add environment configuration instead of hard-coded production URLs.
- Add BLoC tests for high-risk flows: login, payment, stock movement, procurement orders, offline sync.
- Add repository tests around error handling and model parsing.
- Add a lightweight app README that points to this plan.
