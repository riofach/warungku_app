import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/auth/data/models/auth_result.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';

void main() {
  group('AuthResult', () {
    test('should create success result', () {
      final result = AuthResult.success();
      
      expect(result.success, true);
      expect(result.errorMessage, null);
      expect(result.errorCode, null);
    });

    test('should create error result with message', () {
      final result = AuthResult.error('Test error');
      
      expect(result.success, false);
      expect(result.errorMessage, 'Test error');
    });

    test('should create error result with code', () {
      final result = AuthResult.error('Test error', code: 'test_code');
      
      expect(result.success, false);
      expect(result.errorMessage, 'Test error');
      expect(result.errorCode, 'test_code');
    });

    test('should handle invalid credentials exception', () {
      final exception = Exception('Invalid login credentials');
      final result = AuthResult.fromException(exception);
      
      expect(result.success, false);
      expect(result.errorMessage, 'Email atau password salah');
      expect(result.errorCode, 'invalid_credentials');
    });

    test('should handle network exception', () {
      final exception = Exception('SocketException: Connection refused');
      final result = AuthResult.fromException(exception);
      
      expect(result.success, false);
      expect(result.errorMessage, 'Tidak ada koneksi internet');
      expect(result.errorCode, 'network_error');
    });

    test('should handle rate limit exception', () {
      final exception = Exception('Too many requests');
      final result = AuthResult.fromException(exception);
      
      expect(result.success, false);
      expect(result.errorMessage, 'Terlalu banyak percobaan. Coba lagi nanti.');
      expect(result.errorCode, 'rate_limit');
    });

    test('should handle unknown exception with default message', () {
      final exception = Exception('Unknown error');
      final result = AuthResult.fromException(exception);
      
      expect(result.success, false);
      expect(result.errorMessage, 'Terjadi kesalahan. Silakan coba lagi.');
    });
  });

  group('AdminUser', () {
    test('should create AdminUser from JSON', () {
      final json = {
        'id': 'test-id-123',
        'email': 'admin@warungku.com',
        'name': 'Admin Test',
        'role': 'owner',
        'created_at': '2026-01-19T10:00:00Z',
        'last_sign_in_at': '2026-01-19T12:00:00Z',
      };

      final user = AdminUser.fromJson(json);
      
      expect(user.id, 'test-id-123');
      expect(user.email, 'admin@warungku.com');
      expect(user.name, 'Admin Test');
      expect(user.role, 'owner');
      expect(user.isOwner, true);
    });

    test('should return correct display name', () {
      final userWithName = AdminUser(
        id: '1',
        email: 'admin@test.com',
        name: 'John Doe',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      final userWithoutName = AdminUser(
        id: '2',
        email: 'admin@test.com',
        name: null,
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      expect(userWithName.displayName, 'John Doe');
      expect(userWithoutName.displayName, 'admin');
    });

    test('should return correct initials', () {
      final userWithFullName = AdminUser(
        id: '1',
        email: 'admin@test.com',
        name: 'John Doe',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      final userWithSingleName = AdminUser(
        id: '2',
        email: 'admin@test.com',
        name: 'John',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      final userWithoutName = AdminUser(
        id: '3',
        email: 'admin@test.com',
        name: null,
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      expect(userWithFullName.initials, 'JD');
      expect(userWithSingleName.initials, 'J');
      expect(userWithoutName.initials, 'A');
    });

    test('should identify owner role', () {
      final owner = AdminUser(
        id: '1',
        email: 'owner@test.com',
        role: 'owner',
        createdAt: DateTime.now(),
      );
      
      final admin = AdminUser(
        id: '2',
        email: 'admin@test.com',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      expect(owner.isOwner, true);
      expect(admin.isOwner, false);
    });

    test('should convert to JSON correctly', () {
      final user = AdminUser(
        id: 'test-id',
        email: 'admin@test.com',
        name: 'Test Admin',
        role: 'admin',
        createdAt: DateTime(2026, 1, 19, 10, 0, 0),
      );
      
      final json = user.toJson();
      
      expect(json['id'], 'test-id');
      expect(json['email'], 'admin@test.com');
      expect(json['name'], 'Test Admin');
      expect(json['role'], 'admin');
    });

    test('should support equality comparison', () {
      final user1 = AdminUser(
        id: 'same-id',
        email: 'admin@test.com',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      final user2 = AdminUser(
        id: 'same-id',
        email: 'different@test.com',
        role: 'owner',
        createdAt: DateTime.now(),
      );
      
      final user3 = AdminUser(
        id: 'different-id',
        email: 'admin@test.com',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      expect(user1 == user2, true); // Same ID
      expect(user1 == user3, false); // Different ID
    });

    test('should create copy with updated fields', () {
      final original = AdminUser(
        id: 'test-id',
        email: 'admin@test.com',
        name: 'Original',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      
      final copy = original.copyWith(name: 'Updated');
      
      expect(copy.id, original.id);
      expect(copy.email, original.email);
      expect(copy.name, 'Updated');
      expect(copy.role, original.role);
    });
  });
}
