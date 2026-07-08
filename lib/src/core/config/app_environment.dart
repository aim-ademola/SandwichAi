enum AppFlavor { dev, staging, prod }

enum AppFeature {
  devLogin,
  aiForecast,
  wastageAnalysis,
  payment,
  printer,
  scanner,
}

class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.aiBaseUrl,
    required this.devOrganizationCode,
    required this.devUsers,
    required this.disabledFeatures,
  });

  factory AppEnvironment.dev() {
    return const AppEnvironment(
      flavor: AppFlavor.dev,
      appName: 'SandwichAi Dev',
      apiBaseUrl: _productionApiBaseUrl,
      aiBaseUrl: _productionAiBaseUrl,
      devOrganizationCode: 'ORG-005',
      devUsers: [
        AppEnvironmentUser(
          department: 'Customer Service',
          email: 'thedanielsdev+250@gmail.com',
          password: '12345678',
        ),
        AppEnvironmentUser(
          department: 'Kitchen Manager',
          email: 'thedanielsdev+444@gmail.com',
          password: '12345678',
        ),
      ],
      disabledFeatures: {},
    );
  }

  factory AppEnvironment.staging() {
    return const AppEnvironment(
      flavor: AppFlavor.staging,
      appName: 'SandwichAi Staging',
      apiBaseUrl: _productionApiBaseUrl,
      aiBaseUrl: _productionAiBaseUrl,
      devOrganizationCode: 'ORG-005',
      devUsers: [
        AppEnvironmentUser(
          department: 'Customer Service',
          email: 'thedanielsdev+250@gmail.com',
          password: '12345678',
        ),
        AppEnvironmentUser(
          department: 'Kitchen Manager',
          email: 'thedanielsdev+444@gmail.com',
          password: '12345678',
        ),
      ],
      disabledFeatures: {
        AppFeature.aiForecast,
        AppFeature.wastageAnalysis,
        AppFeature.payment,
        AppFeature.printer,
        AppFeature.scanner,
      },
    );
  }

  factory AppEnvironment.prod() {
    return const AppEnvironment(
      flavor: AppFlavor.prod,
      appName: 'SandwichAi',
      apiBaseUrl: _productionApiBaseUrl,
      aiBaseUrl: _productionAiBaseUrl,
      devOrganizationCode: '',
      devUsers: [],
      disabledFeatures: {AppFeature.devLogin},
    );
  }

  static const _productionApiBaseUrl =
      'https://sandwichai-api-3wcql.ondigitalocean.app/';
  static const _productionAiBaseUrl =
      'https://lionfish-app-o5cz2.ondigitalocean.app/api/ai/';

  static AppEnvironment current = AppEnvironment.prod();

  final AppFlavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String aiBaseUrl;
  final String devOrganizationCode;
  final List<AppEnvironmentUser> devUsers;
  final Set<AppFeature> disabledFeatures;

  bool get isProduction => flavor == AppFlavor.prod;

  bool isFeatureEnabled(AppFeature feature) {
    return !disabledFeatures.contains(feature);
  }

  String disabledFeatureMessage(AppFeature feature) {
    return switch (feature) {
      AppFeature.devLogin => 'Dev login is not available in this app version.',
      AppFeature.aiForecast =>
        'AI recipe forecast is not available in this app version.',
      AppFeature.wastageAnalysis =>
        'AI wastage analysis is not available in this app version.',
      AppFeature.payment =>
        'Payment processing is not available in this app version.',
      AppFeature.printer =>
        'Printer setup and printing are not available in this app version.',
      AppFeature.scanner =>
        'Scanner discovery is not available in this app version.',
    };
  }

  static void configure(AppEnvironment environment) {
    current = environment;
  }
}

class AppEnvironmentUser {
  const AppEnvironmentUser({
    required this.department,
    required this.email,
    required this.password,
  });

  final String department;
  final String email;
  final String password;
}
