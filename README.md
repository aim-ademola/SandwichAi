# SandwichAi Mobile Application

A multi-flavor Flutter application integrated with Firebase Analytics, Crashlytics, and interactive manager dashboard visualizations.

---

## 🚀 Running the App with Flavors

The project supports three build flavors: **Development**, **Staging**, and **Production**. 

You can run the app directly using the main file (`lib/main.dart`) by passing the `--flavor` argument. The app will dynamically detect the flavor and initialize the correct configuration.

### Simplified Running Commands (Recommeded)
```bash
# Run Development Environment (Staging API + Dev Features enabled)
flutter run --flavor dev

# Run Staging Environment (Staging API + Restricted Features)
flutter run --flavor staging

# Run Production Environment (Production API + Live Features)
flutter run --flavor prod
```
*Note: If you run the app without specifying a flavor (e.g. `flutter run`), it will default to the **Development (`dev`)** configuration.*

### Explicit Target File Running Commands
Alternatively, you can run target-specific entrypoint files explicitly:
```bash
# Run Development flavor
flutter run --flavor dev -t lib/main_dev.dart

# Run Staging flavor
flutter run --flavor staging -t lib/main_staging.dart

# Run Production flavor
flutter run --flavor prod -t lib/main_prod.dart
```

---

## 🛠️ Feature Registry (Feature Management)

The app uses a **Feature Registry** pattern to manage features dynamically across different environment configurations.

### 1. Checking if a Feature is Enabled
Instead of checking static environment files directly, query the `FeatureRegistry`:
```dart
import 'package:sandwich_ai/src/core/config/feature_registry.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';

if (FeatureRegistry.isEnabled(AppFeature.aiForecast)) {
  // Execute feature logic...
}
```

### 2. Runtime Feature Overrides (For QA & Testing)
During development or QA testing, you can dynamically override feature behaviors on a test device. These settings are persisted locally in Hive and remain active across app restarts:
```dart
// Force enable a feature
await FeatureRegistry.setOverride(AppFeature.aiForecast, true);

// Force disable a feature
await FeatureRegistry.setOverride(AppFeature.devLogin, false);

// Revert to flavor default settings (remove override)
await FeatureRegistry.setOverride(AppFeature.aiForecast, null);

// Clear all overrides
await FeatureRegistry.clearAllOverrides();
```

### 3. How to Register a New Feature
1. **Add it to the `AppFeature` enum** inside [app_environment.dart](file:///D:/Project/SandwichAi/lib/src/core/config/app_environment.dart):
   ```dart
   enum AppFeature {
     ...,
     myStagingExperiment, // Add your feature enum here
   }
   ```
2. **Define its disabled message** inside the `disabledFeatureMessage` switch cases in [app_environment.dart](file:///D:/Project/SandwichAi/lib/src/core/config/app_environment.dart):
   ```dart
   AppFeature.myStagingExperiment => 'This experiment is currently disabled.',
   ```
3. **Configure its default state per flavor**:
   - If it should be disabled by default in certain environments (e.g., prod), add it to `disabledFeatures` inside the factory methods (`AppEnvironment.prod()`, etc.).
   - If left out of `disabledFeatures`, it remains **enabled** by default.
4. **Guard your screens in GoRouter**:
   Define the route in [router.dart](file:///D:/Project/SandwichAi/lib/router/router.dart) using `FeatureRoute` instead of `GoRoute`:
   ```dart
   FeatureRoute(
     path: '/experiment',
     feature: AppFeature.myStagingExperiment,
     builder: (context) => const MyStagingExperimentScreen(),
   )
   ```

---

## 📊 Dashboard Visualizations (`fl_chart`)

Visual dashboard representations have been added for the respective department manager dashboards using the `fl_chart` library:
- **Kitchen Dashboard**: Pie chart showing **Ongoing** vs **Delivered** vs **Received** orders.
- **Processing Dashboard**: Pie chart showing daily task distribution of **Pending** vs **In Process** vs **Completed** tasks.
- **Procurement Dashboard**: Pie chart showing supplier verification distribution of **Active** vs **Pending** vs **Verified** suppliers.
- **Stock Control Dashboard**: Pie chart showing inventory status breakdown of **In Stock** vs **Expired** items.

---

## 🛡️ Environment Visual Verification

A visual environment info badge has been added at the bottom of the employee login screen. This badge dynamically displays:
- The active build configuration (e.g. `SandwichAi Dev` / `SandwichAi Staging` / `SandwichAi`).
- The API base URL the app is currently sending requests to.
- It displays in **green** for dev/staging environments and **red** for production, letting you instantly verify your configuration status at a glance.
