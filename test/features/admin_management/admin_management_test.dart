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
}
