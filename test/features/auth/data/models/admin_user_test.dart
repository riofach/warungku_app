import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';
import 'package:warungku_app/features/auth/data/models/user_role.dart';

void main() {
  group('AdminUser.fromJson', () {
    test('parses owner role correctly', () {
      final user = AdminUser.fromJson({
        'id': 'abc-123',
        'email': 'owner@warung.com',
        'name': 'Owner Warung',
        'role': 'owner',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(user.role, UserRole.owner);
      expect(user.isOwner, isTrue);
      expect(user.isKasir, isFalse);
      expect(user.isRoleUnknown, isFalse);
    });

    test('parses kasir role correctly', () {
      final user = AdminUser.fromJson({
        'id': 'abc-123',
        'email': 'kasir@warung.com',
        'name': 'Kasir Satu',
        'role': 'kasir',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(user.role, UserRole.kasir);
      expect(user.isKasir, isTrue);
      expect(user.isOwner, isFalse);
    });

    test('AE7: null role does NOT default to owner', () {
      final user = AdminUser.fromJson({
        'id': 'abc-123',
        'email': 'unknown@warung.com',
        'name': null,
        'role': null,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(user.role, isNull);
      expect(user.isOwner, isFalse,
          reason: 'default-deny: null role must not be treated as owner');
      expect(user.isKasir, isFalse);
      expect(user.isRoleUnknown, isTrue);
    });

    test('legacy "admin" role parses as null (not owner)', () {
      final user = AdminUser.fromJson({
        'id': 'abc-123',
        'email': 'legacy@warung.com',
        'role': 'admin',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(user.role, isNull);
      expect(user.isOwner, isFalse);
    });
  });

  group('AdminUser.copyWith', () {
    final base = AdminUser(
      id: 'abc',
      email: 'a@b.com',
      name: 'Name',
      role: UserRole.kasir,
      createdAt: DateTime(2026, 1, 1),
    );

    test('updates role from kasir to owner', () {
      final updated = base.copyWith(role: UserRole.owner);
      expect(updated.role, UserRole.owner);
      expect(updated.id, base.id);
    });

    test('clearRole sets role to null', () {
      final updated = base.copyWith(clearRole: true);
      expect(updated.role, isNull);
      expect(updated.isRoleUnknown, isTrue);
    });

    test('without role param keeps existing role', () {
      final updated = base.copyWith(name: 'New Name');
      expect(updated.role, UserRole.kasir);
      expect(updated.name, 'New Name');
    });
  });

  group('AdminUser.toJson', () {
    test('serializes role.value', () {
      final user = AdminUser(
        id: 'abc',
        email: 'a@b.com',
        role: UserRole.owner,
        createdAt: DateTime(2026, 1, 1),
      );
      final json = user.toJson();
      expect(json['role'], 'owner');
    });

    test('serializes null role as null', () {
      final user = AdminUser(
        id: 'abc',
        email: 'a@b.com',
        role: null,
        createdAt: DateTime(2026, 1, 1),
      );
      final json = user.toJson();
      expect(json['role'], isNull);
    });
  });
}
