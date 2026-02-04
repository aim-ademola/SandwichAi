import 'package:hive/hive.dart';

class DrawerOnboardingCache {
  static final DrawerOnboardingCache _instance =
      DrawerOnboardingCache._internal();
  static DrawerOnboardingCache get instance => _instance;

  DrawerOnboardingCache._internal();

  static const String _onboardingBox = 'onboarding_box';
  static const String _keyDrawerOnboarding = 'drawer_onboarding_seen';
  static const String _keyStockControlDrawerOnboarding =
      'stock_control_drawer_onboarding_seen';
  static const String _keyProcurementDrawerOnboarding =
      'procurement_drawer_onboarding_seen';

  Box<dynamic> get _box => Hive.box(_onboardingBox);

  /// Check if user has seen drawer onboarding
  Future<bool> hasSeenDrawerOnboarding() async {
    return _box.get(_keyDrawerOnboarding, defaultValue: false);
  }

  /// Mark drawer onboarding as seen
  Future<void> markDrawerOnboardingSeen() async {
    await _box.put(_keyDrawerOnboarding, true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetDrawerOnboarding() async {
    await _box.delete(_keyDrawerOnboarding);
  }

  Future<bool> hasSeenStockControlDrawerOnboarding() async {
    return _box.get(_keyStockControlDrawerOnboarding, defaultValue: false);
  }

  Future<void> markStockControlDrawerOnboardingSeen() async {
    await _box.put(_keyStockControlDrawerOnboarding, true);
  }

  Future<void> resetStockControlDrawerOnboarding() async {
    await _box.delete(_keyStockControlDrawerOnboarding);
  }

  Future<bool> hasSeenProcurementDrawerOnboarding() async {
    return _box.get(_keyProcurementDrawerOnboarding, defaultValue: false);
  }

  Future<void> markProcurementDrawerOnboardingSeen() async {
    await _box.put(_keyProcurementDrawerOnboarding, true);
  }

  Future<void> resetProcurementDrawerOnboarding() async {
    await _box.delete(_keyProcurementDrawerOnboarding);
  }
}
