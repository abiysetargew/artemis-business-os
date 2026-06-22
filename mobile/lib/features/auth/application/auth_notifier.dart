import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/features/auth/data/repositories/auth_repository.dart';
import 'package:artemis_business_os/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.read(apiClientProvider),
    storage: ref.read(secureStorageProvider),
  );
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool initialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.initialized = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? initialized,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.login(email, password);
      if (result != null) {
        state = AuthState(user: result, initialized: true);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(initialized: true);
  }

  Future<void> checkAuth() async {
    try {
      final user = await _repository.getStoredUser();
      state = AuthState(user: user, initialized: true);
    } catch (_) {
      state = const AuthState(initialized: true);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
