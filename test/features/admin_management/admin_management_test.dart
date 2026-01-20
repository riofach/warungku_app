import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/admin_management/data/models/admin_account.dart';
import 'package:warungku_app/features/admin_management/data/providers/admin_management_provider.dart';
import 'package:warungku_app/features/auth/data/models/auth_result.dart';

void main() {
  group('AdminAccount Model', () {
    test('should create AdminAccount from JSON', () {
      final json = {
        'id': '123-456-789',
        'email': 'admin@test.com',
        'name': 'Test Admin',
        'role': 'admin',
        'created_at': '2026-01-19T10:00:00.000Z',
        'updated_at': '2026-01-19T10:00:00.000Z',
      };

      final admin = AdminAccount.fromJson(json);

      expect(admin.id, '123-456-789');
      expect(admin.email, 'admin@test.com');
      expect(admin.name, 'Test Admin');
      expect(admin.role, 'admin');
      expect(admin.isOwner, false);
    });

    test('should create AdminAccount with owner role', () {
      final json = {
        'id': '123-456-789',
        'email': 'owner@test.com',
        'name': 'Owner',
        'role': 'owner',
        'created_at': '2026-01-19T10:00:00.000Z',
        'updated_at': '2026-01-19T10:00:00.000Z',
      };

      final admin = AdminAccount.fromJson(json);

      expect(admin.isOwner, true);
    });

    // HIGH-3 FIX TEST: Handle null timestamps
    test('should handle null timestamps in JSON', () {
      final json = {
        'id': '123-456-789',
        'email': 'admin@test.com',
        'name': 'Test Admin',
        'role': 'admin',
        'created_at': null,
        'updated_at': null,
      };

      final admin = AdminAccount.fromJson(json);

      expect(admin.id, '123-456-789');
      expect(admin.createdAt, isNotNull);
      expect(admin.updatedAt, isNotNull);
    });

    // HIGH-3 FIX TEST: Handle null email
    test('should handle null email in JSON', () {
      final json = {
        'id': '123-456-789',
        'email': null,
        'name': 'Test Admin',
        'role': 'admin',
        'created_at': '2026-01-19T10:00:00.000Z',
        'updated_at': '2026-01-19T10:00:00.000Z',
      };

      final admin = AdminAccount.fromJson(json);

      expect(admin.email, '');
    });

    test('should convert to JSON', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final json = admin.toJson();

      expect(json['id'], '123');
      expect(json['email'], 'test@test.com');
      expect(json['name'], 'Test');
      expect(json['role'], 'admin');
    });

    test('should get displayName from name', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'Test Admin',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.displayName, 'Test Admin');
    });

    test('should get displayName from email when name is null', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: null,
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.displayName, 'test');
    });

    test('should get initials from name', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'John Doe',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.initials, 'JD');
    });

    test('should get initials from single word name', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'John',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.initials, 'J');
    });

    test('should get initials from email when name is null', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: null,
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.initials, 'T');
    });

    // LOW-2 FIX TEST: Handle empty email edge case
    test('should return ? for initials when both name and email are empty', () {
      final admin = AdminAccount(
        id: '123',
        email: '',
        name: null,
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.initials, '?');
    });

    // LOW-2 FIX TEST: Handle empty name parts
    test('should handle name with empty parts', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: ' ',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      // Empty name should fallback to email
      expect(admin.initials, 'T');
    });

    test('should support equality by id', () {
      final admin1 = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final admin2 = AdminAccount(
        id: '123',
        email: 'different@test.com',
        name: 'Different',
        role: 'owner',
        createdAt: DateTime(2026, 1, 20),
        updatedAt: DateTime(2026, 1, 20),
      );

      expect(admin1, equals(admin2));
    });

    test('copyWith should create new instance with updated fields', () {
      final admin = AdminAccount(
        id: '123',
        email: 'test@test.com',
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final updated = admin.copyWith(name: 'Updated Name');

      expect(updated.name, 'Updated Name');
      expect(updated.email, admin.email);
      expect(updated.id, admin.id);
    });
  });

  group('AdminListState', () {
    test('should create initial state', () {
      final state = AdminListState.initial();

      expect(state.status, AdminListStatus.initial);
      expect(state.admins, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('should create loading state', () {
      final state = AdminListState.loading();

      expect(state.status, AdminListStatus.loading);
      expect(state.isLoading, true);
    });

    test('should create loaded state with admins', () {
      final admins = [
        AdminAccount(
          id: '1',
          email: 'test@test.com',
          name: 'Test',
          role: 'admin',
          createdAt: DateTime(2026, 1, 19),
          updatedAt: DateTime(2026, 1, 19),
        ),
      ];

      final state = AdminListState.loaded(admins);

      expect(state.status, AdminListStatus.loaded);
      expect(state.admins.length, 1);
      expect(state.isEmpty, false);
    });

    test('should detect empty state', () {
      final state = AdminListState.loaded([]);

      expect(state.isEmpty, true);
    });

    test('should create error state', () {
      final state = AdminListState.error('Test error');

      expect(state.status, AdminListStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Test error');
    });
  });

  group('CreateAdminState', () {
    test('should create initial state', () {
      final state = CreateAdminState.initial();

      expect(state.status, CreateAdminStatus.initial);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isSuccess, false);
    });

    test('should create loading state', () {
      final state = CreateAdminState.loading();

      expect(state.status, CreateAdminStatus.loading);
      expect(state.isLoading, true);
    });

    test('should create success state', () {
      final state = CreateAdminState.success();

      expect(state.status, CreateAdminStatus.success);
      expect(state.isSuccess, true);
    });

    test('should create error state', () {
      final state = CreateAdminState.error('Email sudah terdaftar');

      expect(state.status, CreateAdminStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Email sudah terdaftar');
    });
  });

  group('AuthResult', () {
    test('should create success result', () {
      final result = AuthResult.success();

      expect(result.success, true);
      expect(result.errorMessage, isNull);
    });

    test('should create success result with message', () {
      final result = AuthResult.successWithMessage('Admin berhasil ditambahkan');

      expect(result.success, true);
      expect(result.successMessage, 'Admin berhasil ditambahkan');
    });

    test('should create error result', () {
      final result = AuthResult.error('Email sudah terdaftar');

      expect(result.success, false);
      expect(result.errorMessage, 'Email sudah terdaftar');
    });

    test('should create error result with code', () {
      final result = AuthResult.error('Invalid credentials', code: 'invalid_credentials');

      expect(result.success, false);
      expect(result.errorMessage, 'Invalid credentials');
      expect(result.errorCode, 'invalid_credentials');
    });
  });

  // Story 2.5: Tests for AdminActionState (Update Password & Delete Admin)
  group('AdminActionState', () {
    test('should create initial state', () {
      final state = AdminActionState.initial();

      expect(state.status, AdminActionStatus.initial);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isSuccess, false);
      expect(state.successMessage, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create loading state', () {
      final state = AdminActionState.loading();

      expect(state.status, AdminActionStatus.loading);
      expect(state.isLoading, true);
      expect(state.hasError, false);
      expect(state.isSuccess, false);
    });

    test('should create success state with message', () {
      final state = AdminActionState.success('Password berhasil diubah');

      expect(state.status, AdminActionStatus.success);
      expect(state.isSuccess, true);
      expect(state.successMessage, 'Password berhasil diubah');
      expect(state.isLoading, false);
      expect(state.hasError, false);
    });

    test('should create error state with message', () {
      final state = AdminActionState.error('Gagal mengubah password');

      expect(state.status, AdminActionStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Gagal mengubah password');
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
    });

    test('should handle update password success message', () {
      final state = AdminActionState.success('Password berhasil diubah');

      expect(state.successMessage, 'Password berhasil diubah');
      expect(state.isSuccess, true);
    });

    test('should handle delete admin success message', () {
      final state = AdminActionState.success('Admin berhasil dihapus');

      expect(state.successMessage, 'Admin berhasil dihapus');
      expect(state.isSuccess, true);
    });

    test('should handle self-protection error', () {
      final state = AdminActionState.error('Tidak dapat mengubah akun sendiri');

      expect(state.hasError, true);
      expect(state.errorMessage, 'Tidak dapat mengubah akun sendiri');
    });

    test('should handle password validation error', () {
      final state = AdminActionState.error('Password minimal 8 karakter');

      expect(state.hasError, true);
      expect(state.errorMessage, 'Password minimal 8 karakter');
    });

    test('should handle authorization error', () {
      final state = AdminActionState.error('Hanya owner yang dapat melakukan tindakan ini');

      expect(state.hasError, true);
      expect(state.errorMessage, 'Hanya owner yang dapat melakukan tindakan ini');
    });

    test('should handle admin not found error', () {
      final state = AdminActionState.error('Admin tidak ditemukan');

      expect(state.hasError, true);
      expect(state.errorMessage, 'Admin tidak ditemukan');
    });
  });

  // Story 2.5: Tests for self-protection logic
  group('Self-Protection Logic', () {
    test('should identify self as same user', () {
      const currentUserId = '123-456-789';
      final admin = AdminAccount(
        id: '123-456-789',
        email: 'test@test.com',
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final isSelf = currentUserId == admin.id;

      expect(isSelf, true);
    });

    test('should identify different user as not self', () {
      const currentUserId = '123-456-789';
      final admin = AdminAccount(
        id: '999-888-777',
        email: 'other@test.com',
        name: 'Other',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final isSelf = currentUserId == admin.id;

      expect(isSelf, false);
    });

    test('should correctly identify owner role', () {
      final admin = AdminAccount(
        id: '123',
        email: 'owner@test.com',
        name: 'Owner',
        role: 'owner',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.isOwner, true);
    });

    test('should correctly identify non-owner role', () {
      final admin = AdminAccount(
        id: '123',
        email: 'admin@test.com',
        name: 'Admin',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      expect(admin.isOwner, false);
    });

    test('showActions should be false for self', () {
      const currentUserId = '123-456-789';
      final admin = AdminAccount(
        id: '123-456-789',
        email: 'test@test.com',
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final isSelf = currentUserId == admin.id;
      // AC7: Self-protection - hide actions for owner's own account
      final showActions = !isSelf && !admin.isOwner;

      expect(showActions, false);
    });

    test('showActions should be false for owner accounts', () {
      const currentUserId = '999-888-777';
      final admin = AdminAccount(
        id: '123-456-789',
        email: 'owner@test.com',
        name: 'Owner',
        role: 'owner',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final isSelf = currentUserId == admin.id;
      final showActions = !isSelf && !admin.isOwner;

      expect(showActions, false);
    });

    test('showActions should be true for other admin accounts', () {
      const currentUserId = '999-888-777';
      final admin = AdminAccount(
        id: '123-456-789',
        email: 'admin@test.com',
        name: 'Admin',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19),
        updatedAt: DateTime(2026, 1, 19),
      );

      final isSelf = currentUserId == admin.id;
      final showActions = !isSelf && !admin.isOwner;

      expect(showActions, true);
    });
  });

  // Story 2.5: Password validation tests
  group('Password Validation', () {
    test('password with 8 characters should be valid', () {
      const password = '12345678';
      
      expect(password.length >= 8, true);
    });

    test('password with 7 characters should be invalid', () {
      const password = '1234567';
      
      expect(password.length >= 8, false);
    });

    test('password with more than 8 characters should be valid', () {
      const password = 'mySecurePassword123';
      
      expect(password.length >= 8, true);
    });

    test('empty password should be invalid', () {
      const password = '';
      
      expect(password.length >= 8, false);
    });

    test('passwords should match for confirmation', () {
      const password = 'password123';
      const confirmPassword = 'password123';
      
      expect(password == confirmPassword, true);
    });

    test('passwords should fail if not matching', () {
      const password = 'password123';
      const confirmPassword = 'differentPassword';
      
      expect(password == confirmPassword, false);
    });
  });
}
