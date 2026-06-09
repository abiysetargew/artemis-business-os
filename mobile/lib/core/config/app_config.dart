class AppConfig {
  // API Base URL
  // For Web (Chrome/Edge on same computer): http://localhost:3000/api/v1
  // For Android with ADB Reverse: http://localhost:3000/api/v1 (after adb reverse tcp:3000 tcp:3000)
  // For Android Emulator: http://10.0.2.2:3000/api/v1
  // For real device on same WiFi: http://YOUR_COMPUTER_IP:3000/api/v1
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

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
