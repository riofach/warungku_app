import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Order Model', () {
    test('should parse from json correctly', () {
      final json = {
        'id': '123',
        'code': 'WRG-2023-001',
        'housing_block_id': 'block-1',
        'housing_block': {'name': 'Block A'},
        'customer_name': 'John Doe',
        'payment_method': 'cash',
        'delivery_type': 'delivery',
        'status': 'pending',
        'total': 50000,
        'notes': 'Spicy',
        'created_at': '2023-01-01T10:00:00.000Z',
        'updated_at': '2023-01-01T10:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, '123');
      expect(order.code, 'WRG-2023-001');
      expect(order.housingBlockName, 'Block A');
      expect(order.status, OrderStatus.pending);
      expect(order.total, 50000);
    });

    test('should handle missing housing block', () {
      final json = {
        'id': '123',
        'code': 'WRG-2023-001',
        'customer_name': 'John Doe',
        'payment_method': 'cash',
        'delivery_type': 'delivery',
        'status': 'pending',
        'total': 50000,
        'created_at': '2023-01-01T10:00:00.000Z',
        'updated_at': '2023-01-01T10:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.housingBlockName, isNull);
    });

    test('should calculate time ago correctly', () {
      final now = DateTime.now();
      
      // Just now
      final order1 = Order(
        id: '1', code: '1', customerName: 'A', paymentMethod: 'cash', 
        deliveryType: 'del', status: OrderStatus.pending, total: 0,
        createdAt: now.subtract(const Duration(seconds: 30)),
        updatedAt: now,
      );
      expect(order1.timeAgo, 'Baru saja');
      
      // Minutes
      final order2 = Order(
        id: '2', code: '2', customerName: 'B', paymentMethod: 'cash', 
        deliveryType: 'del', status: OrderStatus.pending, total: 0,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now,
      );
      expect(order2.timeAgo, '5 menit yang lalu');
      
      // Hours
      final order3 = Order(
        id: '3', code: '3', customerName: 'C', paymentMethod: 'cash', 
        deliveryType: 'del', status: OrderStatus.pending, total: 0,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      );
      expect(order3.timeAgo, '2 jam yang lalu');
      
      // Days
      final order4 = Order(
        id: '4', code: '4', customerName: 'D', paymentMethod: 'cash', 
        deliveryType: 'del', status: OrderStatus.pending, total: 0,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      );
      expect(order4.timeAgo, '3 hari yang lalu');
      
      // Long time ago (should show formatted date)
      final order5 = Order(
        id: '5', code: '5', customerName: 'E', paymentMethod: 'cash', 
        deliveryType: 'del', status: OrderStatus.pending, total: 0,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      );
      // Formatters.formatRelativeTime returns date string for > 7 days
      expect(order5.timeAgo, isNot(contains('minggu')));
    });
  });
}
