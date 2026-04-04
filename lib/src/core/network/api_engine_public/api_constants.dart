class ApiConstants {
  static const String baseUrl =
      'https://sandwichai-api-3wcql.ondigitalocean.app/';
  static const String aiBaseUrl =
      'https://lionfish-app-o5cz2.ondigitalocean.app/api/ai/';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configurationss
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Cache configurations
  static const Duration cacheTimeout = Duration(minutes: 5);

  // File upload configurations
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];
}
