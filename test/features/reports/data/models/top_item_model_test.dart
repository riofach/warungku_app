import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/reports/data/models/top_item_model.dart';

void main() {
  group('TopItem Model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'item_id': '123',
        'item_name': 'Kopi',
        'total_quantity': 10,
        'total_revenue': 50000,
      };

      final item = TopItem.fromJson(json);

      expect(item.itemId, '123');
      expect(item.itemName, 'Kopi');
      expect(item.totalQuantity, 10);
      expect(item.totalRevenue, 50000);
    });

    test('fromJson handles num types correctly', () {
      final json = {
        'item_id': '123',
        'item_name': 'Kopi',
        'total_quantity': 10.5, // RPC might return float/numeric?
        'total_revenue': 50000.0,
      };
      
      // Though my code casts as num then toInt, so it should handle doubles by truncating/rounding via toInt()
      
      final item = TopItem.fromJson(json);
      expect(item.totalQuantity, 10);
      expect(item.totalRevenue, 50000);
    });
  });
}
