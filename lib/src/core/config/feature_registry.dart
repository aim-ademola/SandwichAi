import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_environment.dart';

class FeatureRegistry {
  FeatureRegistry._();

  static const String _overridesBoxName = 'feature_overrides_box';
  static Box? _box;

  /// Initialize the Feature Registry, opening the Hive box for persistent overrides
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_overridesBoxName);
    } catch (e) {
      debugPrint('Failed to initialize feature registry box: $e');
    }
  }

  /// Check if a feature is enabled, accounting for active environment settings and overrides
  static bool isEnabled(AppFeature feature) {
    // Check if there is a persistent override
    final override = _box?.get(feature.name);
    if (override is bool) {
      return override;
    }

    // Default to the environment feature config
    return AppEnvironment.current.isFeatureEnabled(feature);
  }

  /// Override a feature value at runtime (persists across app restarts)
  static Future<void> setOverride(AppFeature feature, bool? enabled) async {
    if (enabled == null) {
      await _box?.delete(feature.name);
    } else {
      await _box?.put(feature.name, enabled);
    }
  }

  /// Clear all overrides, reverting to environment defaults
  static Future<void> clearAllOverrides() async {
    await _box?.clear();
  }

  /// Get the override value for a feature, if any
  static bool? getOverride(AppFeature feature) {
    return _box?.get(feature.name) as bool?;
  }
}
