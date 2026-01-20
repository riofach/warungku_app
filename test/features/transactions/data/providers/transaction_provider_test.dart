import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/transactions/data/providers/transaction_provider.dart';

void main() {
  group('TransactionFilterState', () {
    test('should create with default values', () {
      const filter = TransactionFilterState();

      expect(filter.fromDate, isNull);
      expect(filter.toDate, isNull);
      expect(filter.adminId, isNull);
      expect(filter.limit, TransactionConstants.defaultPageLimit);
      expect(filter.offset, 0);
    });

    test('should create with custom values', () {
      final fromDate = DateTime(2026, 1, 1);
      final toDate = DateTime(2026, 1, 31);
      final filter = TransactionFilterState(
        fromDate: fromDate,
        toDate: toDate,
        adminId: 'admin-123',
        limit: 50,
        offset: 10,
      );

      expect(filter.fromDate, fromDate);
      expect(filter.toDate, toDate);
      expect(filter.adminId, 'admin-123');
      expect(filter.limit, 50);
      expect(filter.offset, 10);
    });

    test('copyWith should update specified fields', () {
      final original = TransactionFilterState(
        fromDate: DateTime(2026, 1, 1),
        limit: 20,
      );

      final updated = original.copyWith(
        limit: 50,
        offset: 10,
      );

      expect(updated.fromDate, original.fromDate);
      expect(updated.limit, 50);
      expect(updated.offset, 10);
    });

    test('copyWith with clear flags should set values to null', () {
      final original = TransactionFilterState(
        fromDate: DateTime(2026, 1, 1),
        toDate: DateTime(2026, 1, 31),
        adminId: 'admin-123',
      );

      final updated = original.copyWith(
        clearFromDate: true,
        clearAdminId: true,
      );

      expect(updated.fromDate, isNull);
      expect(updated.toDate, original.toDate);
      expect(updated.adminId, isNull);
    });

    test('two filters with same values should be equal', () {
      final fromDate = DateTime(2026, 1, 1);
      final toDate = DateTime(2026, 1, 31);

      final filter1 = TransactionFilterState(
        fromDate: fromDate,
        toDate: toDate,
        adminId: 'admin-123',
        limit: 20,
        offset: 0,
      );

      final filter2 = TransactionFilterState(
        fromDate: fromDate,
        toDate: toDate,
        adminId: 'admin-123',
        limit: 20,
        offset: 0,
      );

      expect(filter1, equals(filter2));
      expect(filter1.hashCode, equals(filter2.hashCode));
    });

    test('two filters with different values should not be equal', () {
      final filter1 = TransactionFilterState(
        fromDate: DateTime(2026, 1, 1),
        limit: 20,
      );

      final filter2 = TransactionFilterState(
        fromDate: DateTime(2026, 1, 2),
        limit: 20,
      );

      expect(filter1, isNot(equals(filter2)));
    });
  });

  group('TransactionConstants', () {
    test('should have expected default values', () {
      expect(TransactionConstants.defaultPageLimit, 20);
      expect(TransactionConstants.maxFetchLimit, 100);
    });
  });
}
