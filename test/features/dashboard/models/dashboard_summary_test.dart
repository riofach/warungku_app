import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/dashboard/data/models/dashboard_summary.dart';

void main() {
  group('DashboardSummary', () {
    test('should create instance with all fields', () {
      // Arrange & Act
      final date = DateTime(2026, 1, 24);
      final summary = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );

      // Assert
      expect(summary.omset, 1000000);
      expect(summary.profit, 250000);
      expect(summary.transactionCount, 12);
      expect(summary.date, date);
    });

    test('should create instance from JSON', () {
      // Arrange
      final json = {
        'omset': 1500000,
        'profit': 350000,
        'transaction_count': 15,
        'date': '2026-01-24',
      };

      // Act
      final summary = DashboardSummary.fromJson(json);

      // Assert
      expect(summary.omset, 1500000);
      expect(summary.profit, 350000);
      expect(summary.transactionCount, 15);
      expect(summary.date, DateTime(2026, 1, 24));
    });

    test('should handle null values in JSON with defaults', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final summary = DashboardSummary.fromJson(json);

      // Assert
      expect(summary.omset, 0);
      expect(summary.profit, 0);
      expect(summary.transactionCount, 0);
      expect(summary.date, isA<DateTime>());
    });

    test('should create empty instance', () {
      // Act
      final summary = DashboardSummary.empty();

      // Assert
      expect(summary.omset, 0);
      expect(summary.profit, 0);
      expect(summary.transactionCount, 0);
      expect(summary.date, isA<DateTime>());
    });

    test('should convert to JSON', () {
      // Arrange
      final date = DateTime(2026, 1, 24);
      final summary = DashboardSummary(
        omset: 2000000,
        profit: 500000,
        transactionCount: 20,
        date: date,
      );

      // Act
      final json = summary.toJson();

      // Assert
      expect(json['omset'], 2000000);
      expect(json['profit'], 500000);
      expect(json['transaction_count'], 20);
      expect(json['date'], date.toIso8601String());
    });

    test('should implement equality correctly', () {
      // Arrange
      final date = DateTime(2026, 1, 24);
      final summary1 = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );
      final summary2 = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );
      final summary3 = DashboardSummary(
        omset: 2000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );

      // Assert
      expect(summary1, equals(summary2));
      expect(summary1, isNot(equals(summary3)));
    });

    test('should have consistent hashCode for equal objects', () {
      // Arrange
      final date = DateTime(2026, 1, 24);
      final summary1 = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );
      final summary2 = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );

      // Assert
      expect(summary1.hashCode, equals(summary2.hashCode));
    });

    test('should have readable toString', () {
      // Arrange
      final date = DateTime(2026, 1, 24);
      final summary = DashboardSummary(
        omset: 1000000,
        profit: 250000,
        transactionCount: 12,
        date: date,
      );

      // Act
      final string = summary.toString();

      // Assert
      expect(string, contains('DashboardSummary'));
      expect(string, contains('1000000'));
      expect(string, contains('250000'));
      expect(string, contains('12'));
    });
  });
}
