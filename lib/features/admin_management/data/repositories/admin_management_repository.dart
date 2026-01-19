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

      // Step 1: Create user in Supabase Auth
      // NOTE: This will replace the current session with the new user's session
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': 'admin',
        },
      );

      if (response.user == null) {
        return AuthResult.error('Gagal membuat akun admin');
      }

      // Step 2: Insert into users table
      await SupabaseService.client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': 'admin',
      });

      // HIGH-1 FIX: Sign out the newly created admin to clear their session
      // The owner will need to re-login, but this prevents confusing state
      await SupabaseService.client.auth.signOut();

      return AuthResult.successWithMessage(
        'Admin berhasil ditambahkan. Silakan login kembali.',
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
        return AuthResult.error('Password minimal 8 karakter');
      }

      return AuthResult.error('Gagal membuat admin: ${e.toString()}');
    }
  }
}
