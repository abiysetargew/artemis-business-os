import 'package:artemis_business_os/core/network/api_client.dart';
import 'package:artemis_business_os/core/storage/secure_storage.dart';
import 'package:artemis_business_os/features/auth/domain/entities/user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository({required ApiClient apiClient, required SecureStorage storage})
    : _apiClient = apiClient,
      _storage = storage;

  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await _storage.saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.saveUserData(user.name);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _storage.clear();
  }

  Future<User?> getStoredUser() async {
    // For simplicity, return null - user will need to re-login
    return null;
  }
}
