import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/admin_user.dart';
import '../repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for current user
/// Returns AdminUser if logged in, null otherwise
final currentUserProvider = Provider<AdminUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUser();
});

/// Provider for auth state
/// Returns true if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.isAuthenticated;
});

/// Stream provider for Supabase auth state changes
final supabaseAuthStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Auth status enum for UI
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state class for the app
class AppAuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AppAuthState({
    required this.status,
    this.errorMessage,
  });

  factory AppAuthState.initial() => const AppAuthState(status: AuthStatus.initial);
  factory AppAuthState.loading() => const AppAuthState(status: AuthStatus.loading);
  factory AppAuthState.authenticated() =>
      const AppAuthState(status: AuthStatus.authenticated);
  factory AppAuthState.unauthenticated() =>
      const AppAuthState(status: AuthStatus.unauthenticated);
  factory AppAuthState.error(String message) =>
      AppAuthState(status: AuthStatus.error, errorMessage: message);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;
}

/// Auth notifier using Notifier (Riverpod 2.0+ style)
class AuthNotifier extends Notifier<AppAuthState> {
  @override
  AppAuthState build() {
    final authRepo = ref.watch(authRepositoryProvider);
    if (authRepo.isAuthenticated) {
      return AppAuthState.authenticated();
    }
    return AppAuthState.unauthenticated();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = AppAuthState.loading();

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signIn(
      email: email,
      password: password,
    );

    if (result.success) {
      state = AppAuthState.authenticated();
      return true;
    } else {
      state = AppAuthState.error(result.errorMessage ?? 'Terjadi kesalahan');
      return false;
    }
  }

  Future<void> signOut() async {
    state = AppAuthState.loading();
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    state = AppAuthState.unauthenticated();
  }

  void clearError() {
    if (state.hasError) {
      state = AppAuthState.unauthenticated();
    }
  }
}

/// Provider for AuthNotifier
final authNotifierProvider = NotifierProvider<AuthNotifier, AppAuthState>(() {
  return AuthNotifier();
});
