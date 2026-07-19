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
    required this.docsUrl,
    required this.devOrganizationCode,
    required this.devUsers,
    required this.disabledFeatures,
  });
  static const _stagingApiBaseUrl = 'https://api-staging.sandwichai.co/';
  static const _stagingAiBaseUrl = 'https://ai-staging.sandwichai.co/api/ai/';
  static const _stagingAiDocsUrl = 'https://ai-staging.sandwichai.co/docs';

  factory AppEnvironment.dev() {
    return const AppEnvironment(
      flavor: AppFlavor.dev,
      appName: 'SandwichAi Dev',
      apiBaseUrl: _stagingApiBaseUrl,
      aiBaseUrl: _stagingAiBaseUrl,
      docsUrl: _stagingAiDocsUrl,
      devOrganizationCode: 'ORG-001',
      devUsers: [
        AppEnvironmentUser(
          department: 'Customer Service',
          email: 'thedanielsdev+222@gmail.com',
          password: '12345678',
        ),
        AppEnvironmentUser(
          department: 'Kitchen Manager',
          email: 'hybiekay2@gmail.com',
          password: 'password@1',
        ),
        AppEnvironmentUser(
          department: 'STOCK CONTROL',
          email: 'hybiekay2+3@gmail.com',
          password: 'SecurePass123!',
        ),

        AppEnvironmentUser(
          department: '	Procurement Department',
          email: 'hybiekay2+2@gmail.com',
          password: 'password@1',
        ),
      ],
      disabledFeatures: {},
    );
  }

  factory AppEnvironment.staging() {
    return const AppEnvironment(
      flavor: AppFlavor.staging,
      appName: 'SandwichAi Staging',
      apiBaseUrl: _stagingApiBaseUrl,
      aiBaseUrl: _stagingAiBaseUrl,
      docsUrl: _stagingAiDocsUrl,
      devOrganizationCode: 'ORG-005',
      devUsers: [],
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
      docsUrl: 'https://sandwichai-api-3wcql.ondigitalocean.app/api/docs',
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
  final String docsUrl;
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

  static AppEnvironment fromFlavor(String? flavorName) {
    switch (flavorName) {
      case 'staging':
        return AppEnvironment.staging();
      case 'prod':
        return AppEnvironment.prod();
      case 'dev':
      default:
        return AppEnvironment.dev();
    }
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
