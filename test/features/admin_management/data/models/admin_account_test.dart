import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/admin_management/data/models/admin_account.dart';
import 'package:warungku_app/features/auth/data/models/user_role.dart';

void main() {
  group('AdminAccount.fromJson', () {
    test('parses owner role', () {
      final account = AdminAccount.fromJson({
        'id': 'abc',
        'email': 'owner@warung.com',
        'name': 'Owner',
        'role': 'owner',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
      expect(account.role, UserRole.owner);
      expect(account.isOwner, isTrue);
    });

    test('parses kasir role', () {
      final account = AdminAccount.fromJson({
        'id': 'abc',
        'email': 'kasir@warung.com',
        'role': 'kasir',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
      expect(account.role, UserRole.kasir);
      expect(account.isKasir, isTrue);
    });

    test('falls back to kasir (least-privilege) for unknown role', () {
      final account = AdminAccount.fromJson({
        'id': 'abc',
        'email': 'legacy@warung.com',
        'role': 'admin',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
      expect(account.role, UserRole.kasir,
          reason: 'defensive fallback prefers least privilege');
    });
  });

  group('AdminAccount.initials', () {
    test('two-word name returns first letters of first two parts', () {
      final account = AdminAccount(
        id: 'abc',
        email: 'a@b.com',
        name: 'Owner Warung',
        role: UserRole.owner,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(account.initials, 'OW');
    });

    test('single-name returns first letter', () {
      final account = AdminAccount(
        id: 'abc',
        email: 'a@b.com',
        name: 'Rio',
        role: UserRole.kasir,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(account.initials, 'R');
    });

    test('null name falls back to email initial', () {
      final account = AdminAccount(
        id: 'abc',
        email: 'kasir@warung.com',
        role: UserRole.kasir,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(account.initials, 'K');
    });
  });
}
