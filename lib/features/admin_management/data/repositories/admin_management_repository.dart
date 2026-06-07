import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/data/models/auth_result.dart';
import '../../../auth/data/models/user_role.dart';
import '../models/admin_account.dart';

/// Repository for account management (owner & kasir).
///
/// All mutations go through the `admin-management` Edge Function so that:
///   - owner verification happens server-side with the service role,
///   - public.users and auth.users stay consistent in one round trip,
///   - the owner's local session is never replaced by signUp side effects.
class AdminManagementRepository {
  static const _edgeFunction = 'admin-management';

  /// List all accounts in public.users, ordered by creation time.
  Future<List<AdminAccount>> getAdmins() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => AdminAccount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar akun: $e');
    }
  }

  /// Create a new account (owner or kasir) via the admin-management Edge
  /// Function. The function uses the service role to:
  ///   1. createUser in auth (with email_confirm=true)
  ///   2. UPDATE public.users to the requested role/name
  /// On any failure, the function rolls back the auth user.
  Future<AuthResult> createAdmin({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      await _ensureValidSession();

      final response = await SupabaseService.client.functions.invoke(
        _edgeFunction,
        body: {
          'action': 'create-user',
          'email': email,
          'password': password,
          'name': name,
          'role': role.value,
        },
      );

      return _interpretResponse(response, defaultSuccess: 'Akun berhasil ditambahkan');
    } on FunctionException catch (e) {
      if (e.status == 401) {
        return AuthResult.error('Sesi telah berakhir. Silakan login kembali.');
      }
      return AuthResult.error('Gagal membuat akun: ${e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      return AuthResult.error('Gagal membuat akun: ${e.toString()}');
    }
  }

  /// Update an account's password (owner-only, cannot target self or owner).
  Future<AuthResult> updateAdminPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return AuthResult.error('Tidak ada sesi aktif');
      }

      if (userId == currentUser.id) {
        return AuthResult.error('Tidak dapat mengubah password akun sendiri');
      }

      if (newPassword.length < 8) {
        return AuthResult.error('Password minimal 8 karakter');
      }

      await _ensureValidSession();

      final response = await SupabaseService.client.functions.invoke(
        _edgeFunction,
        body: {
          'action': 'update-password',
          'targetUserId': userId,
          'newPassword': newPassword,
        },
      );

      return _interpretResponse(response, defaultSuccess: 'Password berhasil diubah');
    } on FunctionException catch (e) {
      if (e.status == 401) {
        return AuthResult.error('Sesi telah berakhir. Silakan login kembali.');
      }
      return AuthResult.error('Gagal mengubah password: ${e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      return AuthResult.error('Gagal mengubah password: ${e.toString()}');
    }
  }

  /// Delete an account (owner-only, cannot target self or owner).
  Future<AuthResult> deleteAdmin({
    required String userId,
  }) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        return AuthResult.error('Tidak ada sesi aktif');
      }

      if (userId == currentUser.id) {
        return AuthResult.error('Tidak dapat menghapus akun sendiri');
      }

      await _ensureValidSession();

      final response = await SupabaseService.client.functions.invoke(
        _edgeFunction,
        body: {
          'action': 'delete-admin',
          'targetUserId': userId,
        },
      );

      return _interpretResponse(response, defaultSuccess: 'Akun berhasil dihapus');
    } on FunctionException catch (e) {
      if (e.status == 401) {
        return AuthResult.error('Sesi telah berakhir. Silakan login kembali.');
      }
      return AuthResult.error('Gagal menghapus akun: ${e.reasonPhrase ?? e.toString()}');
    } catch (e) {
      return AuthResult.error('Gagal menghapus akun: ${e.toString()}');
    }
  }

  /// Decode an edge-function response into an [AuthResult].
  ///
  /// Status >= 400 is treated as an error; the function's `message` field is
  /// surfaced to the user. Success uses the function's `message` when present,
  /// otherwise the provided [defaultSuccess].
  AuthResult _interpretResponse(
    FunctionResponse response, {
    required String defaultSuccess,
  }) {
    if (response.status >= 400) {
      final data = response.data as Map<String, dynamic>?;
      final message = data?['message'] as String? ?? 'Terjadi kesalahan';
      return AuthResult.error(message);
    }

    final data = response.data as Map<String, dynamic>;
    final success = data['success'] as bool? ?? false;
    final message = data['message'] as String? ?? defaultSuccess;

    return success
        ? AuthResult.successWithMessage(message)
        : AuthResult.error(message);
  }

  /// Refresh the Supabase session if it expires within 60 seconds so the
  /// Edge Function call doesn't fail with 401.
  Future<void> _ensureValidSession() async {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      throw Exception('Tidak ada sesi aktif');
    }

    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final bufferTime = DateTime.now().add(const Duration(seconds: 60));

      if (expiryTime.isBefore(bufferTime)) {
        await SupabaseService.client.auth.refreshSession();
      }
    }
  }
}
