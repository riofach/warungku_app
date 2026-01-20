import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/admin_user.dart';
import '../repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for Supabase auth state changes
/// This is the SOURCE OF TRUTH for auth state
final supabaseAuthStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Provider for current user - REACTIVE to Supabase auth stream
/// Returns AdminUser if logged in, null otherwise
/// Uses Supabase stream for reliable updates after login/logout
final currentUserProvider = Provider<AdminUser?>((ref) {
  // Watch Supabase auth stream for reliable updates
  final supabaseAuthState = ref.watch(supabaseAuthStateProvider);
  
  return supabaseAuthState.when(
    data: (authState) {
      // Get user from session (most reliable)
      final user = authState.session?.user;
      if (user == null) {
        debugPrint('currentUserProvider: No user in session');
        return null;
      }
      final adminUser = AdminUser.fromSupabaseUser(user);
      debugPrint('currentUserProvider: User loaded - ${adminUser.email}, role: ${adminUser.role}');
      return adminUser;
    },
    loading: () {
      // During initial load, try to get from current session
      debugPrint('currentUserProvider: Loading, checking current session...');
      final authRepo = ref.read(authRepositoryProvider);
      return authRepo.getCurrentUser();
    },
    error: (error, stack) {
      debugPrint('currentUserProvider: Error - $error');
      return null;
    },
  );
});

/// Provider for auth state
/// Returns true if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser != null;
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
/// Manages login/logout actions and loading/error states
/// Note: currentUserProvider uses Supabase stream directly for user data
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
      // Supabase stream will automatically update currentUserProvider
      // with the new user data from the session
      debugPrint('AuthNotifier: signIn success for $email');
      state = AppAuthState.authenticated();
      return true;
    } else {
      state = AppAuthState.error(result.errorMessage ?? 'Terjadi kesalahan');
      return false;
    }
  }

  /// Sign out current user
  /// Returns true if successful, false if error occurred
  Future<bool> signOut() async {
    state = AppAuthState.loading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signOut();
    
    if (result.success) {
      // Supabase stream will automatically clear user data
      debugPrint('AuthNotifier: signOut success');
      state = AppAuthState.unauthenticated();
      return true;
    } else {
      // Logout failed - show error but stay in current state
      state = AppAuthState.error(result.errorMessage ?? 'Gagal keluar dari aplikasi');
      return false;
    }
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
