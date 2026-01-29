import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/orders/utils/order_status_helper.dart';

void main() {
  group('OrderStatusHelper', () {
    test('pending status should return processing action', () {
      final result = OrderStatusHelper.getNextStatusAction('pending');
      expect(result, isNotNull);
      expect(result?.$1, 'processing');
      expect(result?.$2, 'Proses Pesanan');
    });

    test('paid status should return processing action', () {
      final result = OrderStatusHelper.getNextStatusAction('paid');
      expect(result, isNotNull);
      expect(result?.$1, 'processing');
      expect(result?.$2, 'Proses Pesanan');
    });

    test('processing status should return ready action', () {
      final result = OrderStatusHelper.getNextStatusAction('processing');
      expect(result, isNotNull);
      expect(result?.$1, 'ready');
      expect(result?.$2, 'Siap Diantar/Diambil');
    });

    test('ready status should return completed action', () {
      final result = OrderStatusHelper.getNextStatusAction('ready');
      expect(result, isNotNull);
      expect(result?.$1, 'completed');
      expect(result?.$2, 'Selesai');
    });

    test('completed status should return null', () {
      final result = OrderStatusHelper.getNextStatusAction('completed');
      expect(result, isNull);
    });

    test('cancelled status should return null', () {
      final result = OrderStatusHelper.getNextStatusAction('cancelled');
      expect(result, isNull);
    });

    test('unknown status should return null', () {
      final result = OrderStatusHelper.getNextStatusAction('unknown_status');
      expect(result, isNull);
    });
  });
}
