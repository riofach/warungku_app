import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/services/supabase_service.dart';
import '../models/admin_user.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for Supabase auth state changes (source of truth for session)
final supabaseAuthStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Current authenticated user — REACTIVE to Supabase auth stream + role
/// resolution from public.users.
///
/// Emits in this order on every session change:
///   1. `null` when no session.
///   2. AdminUser built from auth metadata (role may be null if metadata
///      doesn't carry it — DO NOT default to owner; default-deny).
///   3. AdminUser with role updated from public.users (authoritative).
///
/// If the public.users row doesn't exist yet (e.g. immediately after signUp
/// before the handle_new_user trigger has visible commit, or during
/// migration), the second emit carries `role: null` — UI uses
/// [isRoleUnknown] to suppress owner-only affordances.
final currentUserProvider = StreamProvider<AdminUser?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);

  await for (final authState in authRepo.authStateChanges) {
    final user = authState.session?.user;
    if (user == null) {
      debugPrint('currentUserProvider: No session');
      yield null;
      continue;
    }

    // Phase 1: emit metadata-based user immediately so UI can render.
    final fromMetadata = AdminUser.fromSupabaseUser(user);
    yield fromMetadata;

    // Phase 2: fetch authoritative role from public.users.
    try {
      final client = SupabaseService.client;
      final data = await client
          .from('users')
          .select('role, name')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // Row not (yet) in public.users — keep metadata-derived user.
        // If metadata role was also null, AdminUser stays role-unknown and
        // UI/router defaults to deny.
        debugPrint('currentUserProvider: no public.users row for ${user.id}');
        continue;
      }

      final dbRole = UserRole.fromString(data['role'] as String?);
      final dbName = data['name'] as String?;

      if (dbRole != fromMetadata.role ||
          (dbName != null && dbName != fromMetadata.name)) {
        debugPrint(
          'currentUserProvider: refreshing from DB '
          '(role=${dbRole?.value}, name=$dbName)',
        );
        yield fromMetadata.copyWith(
          role: dbRole,
          clearRole: dbRole == null,
          name: dbName ?? fromMetadata.name,
        );
      } else {
        debugPrint(
          'currentUserProvider: DB role matches metadata (${dbRole?.value})',
        );
      }
    } catch (e) {
      // Network/RLS error — keep metadata-derived user. If metadata role
      // was null, app stays in default-deny state until next auth event.
      debugPrint('currentUserProvider: error fetching public.users: $e');
    }
  }
});

/// True when a session exists.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).asData?.value != null;
});

/// Resolved role of the current user, or null when no session OR role still
/// loading. UI/router treats null as default-deny.
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider).asData?.value?.role;
});

/// Convenience: true iff role is explicitly resolved to owner.
final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.owner;
});

/// Convenience: true iff role is explicitly resolved to kasir.
final isKasirProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.kasir;
});

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

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
      debugPrint('AuthNotifier: signIn success for $email');
      state = AppAuthState.authenticated();
      return true;
    } else {
      state = AppAuthState.error(result.errorMessage ?? 'Terjadi kesalahan');
      return false;
    }
  }

  Future<bool> signOut() async {
    state = AppAuthState.loading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signOut();

    if (result.success) {
      debugPrint('AuthNotifier: signOut success');
      state = AppAuthState.unauthenticated();
      return true;
    } else {
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

final authNotifierProvider = NotifierProvider<AuthNotifier, AppAuthState>(() {
  return AuthNotifier();
});
