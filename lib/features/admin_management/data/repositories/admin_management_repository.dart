import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/admin_account.dart';
import '../../../auth/data/models/auth_result.dart';

/// Repository for admin account management
/// Handles CRUD operations for admin users
class AdminManagementRepository {
  /// Get all admin accounts from users table
  Future<List<AdminAccount>> getAdmins() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => AdminAccount.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar admin: $e');
    }
  }

  /// Create new admin account
  /// 1. Verify current user is owner
  /// 2. Create user in Supabase Auth
  /// 3. Insert into users table
  /// 
  /// WARNING: Supabase signUp() will log in the new user, replacing the owner's session.
  /// The owner will need to re-login after creating an admin.
  Future<AuthResult> createAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // HIGH-2 FIX: Verify current user is owner before proceeding
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return AuthResult.error('Tidak ada sesi aktif');
      }
      
      final currentRole = currentUser.userMetadata?['role'] as String?;
      if (currentRole != 'owner') {
        return AuthResult.error('Hanya owner yang dapat menambah admin');
      }

      // Step 1: Create user in Supabase Auth using a temporary client
      // This prevents the current session (owner) from being replaced by the new user
      final tempClient = SupabaseClient(
        SupabaseService.url,
        SupabaseService.anonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      User? newUser;

      try {
        final response = await tempClient.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'role': 'admin',
          },
        );
        newUser = response.user;
      } finally {
        // Always dispose the temporary client
        await tempClient.dispose();
      }

      if (newUser == null) {
        return AuthResult.error('Gagal membuat akun admin');
      }

      // Step 2: Insert into users table using the MAIN client (Owner)
      // We assume the Owner has RLS permissions to insert into users table for other users
      await SupabaseService.client.from('users').insert({
        'id': newUser.id,
        'email': email,
        'name': name,
        'role': 'admin',
        'email_verified_at': DateTime.now().toIso8601String(),
      });
      
      return AuthResult.successWithMessage(
        'Admin berhasil ditambahkan.',
      );
    } catch (e) {
      // Handle specific Supabase errors
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('already registered') ||
          errorMessage.contains('user already exists') ||
          errorMessage.contains('already been registered')) {
        return AuthResult.error('Email sudah terdaftar');
      }
      
      if (errorMessage.contains('invalid email')) {
        return AuthResult.error('Format email tidak valid');
      }
      
      if (errorMessage.contains('password')) {
        // Check if it's specifically a length issue
        if (errorMessage.contains('length') || 
            errorMessage.contains('short') || 
            errorMessage.contains('at least 6 characters') ||
            errorMessage.contains('at least 8 characters')) {
           return AuthResult.error('Password minimal 8 karakter');
        }
        // Otherwise return the original error message to help debug
        // Common issues: weak password, compromise detection, etc.
        return AuthResult.error('Masalah pada password: $errorMessage');
      }

      return AuthResult.error('Gagal membuat admin: ${e.toString()}');
    }
  }

  /// Update admin password via Edge Function
  /// Only owner can update other admin's password
  /// Self-protection: Cannot update own password through this method
  Future<AuthResult> updateAdminPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      // Verify current user is owner before proceeding
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return AuthResult.error('Tidak ada sesi aktif');
      }

      final currentRole = currentUser.userMetadata?['role'] as String?;
      if (currentRole != 'owner') {
        return AuthResult.error('Hanya owner yang dapat mengubah password admin');
      }

      // Self-protection check
      if (userId == currentUser.id) {
        return AuthResult.error('Tidak dapat mengubah password akun sendiri');
      }

      // Validate password length
      if (newPassword.length < 8) {
        return AuthResult.error('Password minimal 8 karakter');
      }

      // Ensure session is valid before calling Edge Function
      await _ensureValidSession();

      // Call Edge Function
      final response = await SupabaseService.client.functions.invoke(
        'admin-management',
        body: {
          'action': 'update-password',
          'targetUserId': userId,
          'newPassword': newPassword,
        },
      );

      // HIGH-2 FIX: Use >= 400 to properly detect error status codes
      // This handles 4xx client errors and 5xx server errors correctly
      if (response.status >= 400) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] as String? ?? 'Gagal mengubah password';
        return AuthResult.error(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Password berhasil diubah';

      if (success) {
        return AuthResult.successWithMessage(message);
      } else {
        return AuthResult.error(message);
      }
    } on FunctionException catch (e) {
      // Handle Edge Function specific errors (JWT expired, unauthorized, etc.)
      if (e.status == 401) {
        return AuthResult.error('Sesi telah berakhir. Silakan login kembali.');
      }
      return AuthResult.error('Gagal mengubah password: ${e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      return AuthResult.error('Gagal mengubah password: ${e.toString()}');
    }
  }

  /// Delete admin via Edge Function
  /// Only owner can delete admin accounts
  /// Self-protection: Cannot delete own account
  Future<AuthResult> deleteAdmin({
    required String userId,
  }) async {
    try {
      // Verify current user is owner before proceeding
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return AuthResult.error('Tidak ada sesi aktif');
      }

      final currentRole = currentUser.userMetadata?['role'] as String?;
      if (currentRole != 'owner') {
        return AuthResult.error('Hanya owner yang dapat menghapus admin');
      }

      // Self-protection check
      if (userId == currentUser.id) {
        return AuthResult.error('Tidak dapat menghapus akun sendiri');
      }

      // Ensure session is valid before calling Edge Function
      await _ensureValidSession();

      // Call Edge Function
      final response = await SupabaseService.client.functions.invoke(
        'admin-management',
        body: {
          'action': 'delete-admin',
          'targetUserId': userId,
        },
      );

      // HIGH-2 FIX: Use >= 400 to properly detect error status codes
      if (response.status >= 400) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] as String? ?? 'Gagal menghapus admin';
        return AuthResult.error(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? 'Admin berhasil dihapus';

      if (success) {
        return AuthResult.successWithMessage(message);
      } else {
        return AuthResult.error(message);
      }
    } on FunctionException catch (e) {
      // Handle Edge Function specific errors (JWT expired, unauthorized, etc.)
      if (e.status == 401) {
        return AuthResult.error('Sesi telah berakhir. Silakan login kembali.');
      }
      return AuthResult.error('Gagal menghapus admin: ${e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      return AuthResult.error('Gagal menghapus admin: ${e.toString()}');
    }
  }

  /// Ensure the current session is valid by refreshing if needed
  Future<void> _ensureValidSession() async {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      throw Exception('Tidak ada sesi aktif');
    }

    // Check if token is expired or about to expire (within 60 seconds)
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final now = DateTime.now();
      final bufferTime = now.add(const Duration(seconds: 60));

      if (expiryTime.isBefore(bufferTime)) {
        // Token expired or about to expire, refresh it
        await SupabaseService.client.auth.refreshSession();
      }
    }
  }
}
