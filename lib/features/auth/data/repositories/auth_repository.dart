import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/admin_user.dart';
import '../models/auth_result.dart';

/// Repository for authentication operations
/// Handles all Supabase Auth interactions
class AuthRepository {
  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await SupabaseService.signIn(
        email: email,
        password: password,
      );
      return AuthResult.success();
    } catch (e) {
      return AuthResult.fromException(e);
    }
  }

  /// Sign out current user
  Future<AuthResult> signOut() async {
    try {
      await SupabaseService.signOut();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.fromException(e);
    }
  }

  /// Get current authenticated user
  AdminUser? getCurrentUser() {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    return AdminUser.fromSupabaseUser(user);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;

  /// Update user metadata
  Future<AuthResult> updateUserMetadata({
    String? name,
  }) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            if (name != null) 'name': name,
          },
        ),
      );
      return AuthResult.success();
    } catch (e) {
      return AuthResult.fromException(e);
    }
  }

  /// Change password
  Future<AuthResult> changePassword(String newPassword) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult.success();
    } catch (e) {
      return AuthResult.fromException(e);
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return AuthResult.success();
    } catch (e) {
      return AuthResult.fromException(e);
    }
  }
}
