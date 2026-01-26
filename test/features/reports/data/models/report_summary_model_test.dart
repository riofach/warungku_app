import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/reports/data/models/report_summary_model.dart';

void main() {
  group('ReportSummary', () {
    test('fromJson should parse valid json correctly', () {
      // Arrange
      final json = {
        'total_revenue': 1500000,
        'total_profit': 500000,
        'transaction_count': 15,
        'average_value': 100000,
      };

      // Act
      final result = ReportSummary.fromJson(json);

      // Assert
      expect(result.totalRevenue, 1500000);
      expect(result.totalProfit, 500000);
      expect(result.transactionCount, 15);
      expect(result.averageValue, 100000);
    });

    test('fromJson should handle null values by using defaults', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final result = ReportSummary.fromJson(json);

      // Assert
      expect(result.totalRevenue, 0);
      expect(result.totalProfit, 0);
      expect(result.transactionCount, 0);
      expect(result.averageValue, 0);
    });

    test('empty factory should return zero values', () {
      // Act
      final result = ReportSummary.empty();

      // Assert
      expect(result.totalRevenue, 0);
      expect(result.totalProfit, 0);
      expect(result.transactionCount, 0);
      expect(result.averageValue, 0);
    });
  });
}
