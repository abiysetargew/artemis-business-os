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

  /// Returns the API base URL, resolving relative paths against the current
  /// browser origin so a single host can serve both the Flutter web app
  /// and the API (e.g. on Render). For absolute URLs, returns them unchanged.
  static String get apiBaseUrl {
    final env = _envApiBaseUrl;
    if (env.startsWith('/')) {
      // In a web context, resolve against window.location.origin.
      try {
        // ignore: avoid_print
        return '${Uri.base.origin}$env';
      } catch (_) {
        return env;
      }
    }
    return env;
  }

  static List<String> get fallbackUrls => _envFallbackUrlsCsv.split(',');

  static const String appName = 'Artemis Business OS';
  static const String appVersion = '1.1.0';

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
