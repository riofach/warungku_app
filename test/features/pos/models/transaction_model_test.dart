import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/data/models/transaction_model.dart';

void main() {
  group('Transaction Model', () {
    test('should create Transaction from JSON', () {
      // Arrange
      final json = {
        'id': 'test-id-123',
        'code': 'TRX-20260123-0001',
        'admin_id': 'admin-123',
        'payment_method': 'cash',
        'cash_received': 50000,
        'change_amount': 5000,
        'total': 45000,
        'created_at': '2026-01-23T10:30:00Z',
      };

      // Act
      final transaction = Transaction.fromJson(json);

      // Assert
      expect(transaction.id, 'test-id-123');
      expect(transaction.code, 'TRX-20260123-0001');
      expect(transaction.adminId, 'admin-123');
      expect(transaction.paymentMethod, 'cash');
      expect(transaction.cashReceived, 50000);
      expect(transaction.changeAmount, 5000);
      expect(transaction.total, 45000);
      expect(transaction.createdAt, DateTime.parse('2026-01-23T10:30:00Z'));
    });

    test('should create Transaction from JSON with null values', () {
      // Arrange
      final json = {
        'id': 'test-id-123',
        'code': 'TRX-20260123-0002',
        'admin_id': null,
        'payment_method': 'qris',
        'cash_received': null,
        'change_amount': null,
        'total': 30000,
        'created_at': '2026-01-23T11:00:00Z',
      };

      // Act
      final transaction = Transaction.fromJson(json);

      // Assert
      expect(transaction.adminId, null);
      expect(transaction.cashReceived, null);
      expect(transaction.changeAmount, null);
      expect(transaction.paymentMethod, 'qris');
    });

    test('should convert Transaction to JSON', () {
      // Arrange
      final transaction = Transaction(
        id: 'test-id-123',
        code: 'TRX-20260123-0003',
        adminId: 'admin-456',
        paymentMethod: 'cash',
        cashReceived: 100000,
        changeAmount: 10000,
        total: 90000,
        createdAt: DateTime.parse('2026-01-23T12:00:00Z'),
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['id'], 'test-id-123');
      expect(json['code'], 'TRX-20260123-0003');
      expect(json['admin_id'], 'admin-456');
      expect(json['payment_method'], 'cash');
      expect(json['cash_received'], 100000);
      expect(json['change_amount'], 10000);
      expect(json['total'], 90000);
      expect(json['created_at'], isA<String>());
    });
  });

  group('TransactionItem Model', () {
    test('should create TransactionItem from JSON', () {
      // Arrange
      final json = {
        'id': 'item-id-123',
        'transaction_id': 'trx-id-456',
        'item_id': 'product-id-789',
        'item_name': 'Indomie Goreng',
        'quantity': 5,
        'buy_price': 2500,
        'sell_price': 3000,
        'subtotal': 15000,
        'created_at': '2026-01-23T10:30:00Z',
      };

      // Act
      final transactionItem = TransactionItem.fromJson(json);

      // Assert
      expect(transactionItem.id, 'item-id-123');
      expect(transactionItem.transactionId, 'trx-id-456');
      expect(transactionItem.itemId, 'product-id-789');
      expect(transactionItem.itemName, 'Indomie Goreng');
      expect(transactionItem.quantity, 5);
      expect(transactionItem.buyPrice, 2500);
      expect(transactionItem.sellPrice, 3000);
      expect(transactionItem.subtotal, 15000);
    });

    test('should convert TransactionItem to JSON', () {
      // Arrange
      final transactionItem = TransactionItem(
        id: 'item-id-123',
        transactionId: 'trx-id-456',
        itemId: 'product-id-789',
        itemName: 'Indomie Goreng',
        quantity: 5,
        buyPrice: 2500,
        sellPrice: 3000,
        subtotal: 15000,
        createdAt: DateTime.parse('2026-01-23T10:30:00Z'),
      );

      // Act
      final json = transactionItem.toJson();

      // Assert
      expect(json['id'], 'item-id-123');
      expect(json['transaction_id'], 'trx-id-456');
      expect(json['item_id'], 'product-id-789');
      expect(json['item_name'], 'Indomie Goreng');
      expect(json['quantity'], 5);
      expect(json['buy_price'], 2500);
      expect(json['sell_price'], 3000);
      expect(json['subtotal'], 15000);
    });

    test('should handle nullable item_id', () {
      // Arrange
      final json = {
        'id': 'item-id-123',
        'transaction_id': 'trx-id-456',
        'item_id': null,
        'item_name': 'Deleted Item',
        'quantity': 2,
        'buy_price': 1000,
        'sell_price': 1500,
        'subtotal': 3000,
        'created_at': '2026-01-23T10:30:00Z',
      };

      // Act
      final transactionItem = TransactionItem.fromJson(json);

      // Assert
      expect(transactionItem.itemId, null);
      expect(transactionItem.itemName, 'Deleted Item');
    });
  });
}
