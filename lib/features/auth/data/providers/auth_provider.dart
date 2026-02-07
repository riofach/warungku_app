import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/supabase_service.dart';
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
/// Also fetches latest role from public.users table
final currentUserProvider = StreamProvider<AdminUser?>((ref) async* {
  // Watch auth repository for reliable updates
  final authRepo = ref.watch(authRepositoryProvider);
  
  await for (final authState in authRepo.authStateChanges) {
    final user = authState.session?.user;
    if (user == null) {
      debugPrint('currentUserProvider: No user in session');
      yield null;
      continue;
    }

    // 1. Create user from metadata (fast)
    final adminUser = AdminUser.fromSupabaseUser(user);
    yield adminUser;

    // 2. Fetch latest role from database (async)
    try {
      final supabase = SupabaseService.client;
      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = data['role'] as String?;
      if (role != null && role != adminUser.role) {
        debugPrint('currentUserProvider: Updated role from DB: $role');
        yield adminUser.copyWith(role: role);
      } else {
        debugPrint('currentUserProvider: Role from DB matches metadata: ${adminUser.role}');
      }
    } catch (e) {
      debugPrint('currentUserProvider: Error fetching role from DB: $e');
      // Keep yielding the metadata-based user
    }
  }
});

/// Provider for auth state
/// Returns true if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.asData?.value != null;
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
