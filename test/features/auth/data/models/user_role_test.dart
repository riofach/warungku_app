import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/auth/data/models/user_role.dart';

void main() {
  group('UserRole.fromString', () {
    test('parses "owner"', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
    });

    test('parses "kasir"', () {
      expect(UserRole.fromString('kasir'), UserRole.kasir);
    });

    test('returns null for legacy "admin"', () {
      expect(UserRole.fromString('admin'), isNull);
    });

    test('returns null for null input', () {
      expect(UserRole.fromString(null), isNull);
    });

    test('returns null for empty string', () {
      expect(UserRole.fromString(''), isNull);
    });

    test('returns null for unknown role', () {
      expect(UserRole.fromString('superadmin'), isNull);
      expect(UserRole.fromString('OWNER'), isNull); // case-sensitive
    });
  });

  group('UserRole.value', () {
    test('owner.value == "owner"', () {
      expect(UserRole.owner.value, 'owner');
    });

    test('kasir.value == "kasir"', () {
      expect(UserRole.kasir.value, 'kasir');
    });
  });

  group('UserRole.label', () {
    test('owner.label == "Owner"', () {
      expect(UserRole.owner.label, 'Owner');
    });

    test('kasir.label == "Kasir"', () {
      expect(UserRole.kasir.label, 'Kasir');
    });
  });
}
