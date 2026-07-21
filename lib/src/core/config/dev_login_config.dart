import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/config/feature_registry.dart';

class DevLoginConfig {
  const DevLoginConfig._();

  static bool get enabled => FeatureRegistry.isEnabled(AppFeature.devLogin);
  static String get organizationCode =>
      AppEnvironment.current.devOrganizationCode;

  static List<DevLoginUser> get users => AppEnvironment.current.devUsers
      .map(
        (user) => DevLoginUser(
          department: user.department,
          email: user.email,
          password: user.password,
        ),
      )
      .toList();
}

class DevLoginUser {
  const DevLoginUser({
    required this.department,
    required this.email,
    required this.password,
  });

  final String department;
  final String email;
  final String password;
}
