class AppConfig {
  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4040/api/v1',
  );

  static const String _envFallbackUrlsCsv = String.fromEnvironment(
    'API_FALLBACK_URLS',
    defaultValue:
        'http://10.0.2.2:4040/api/v1,https://kilobyte-enactment-bounding.ngrok-free.dev/api/v1',
  );

  static String get apiBaseUrl => _envApiBaseUrl;

  static List<String> get fallbackUrls => _envFallbackUrlsCsv.split(',');

  static const String appName = 'Artemis Business OS';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // API timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
}
