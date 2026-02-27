import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/transactions/data/models/transaction_model.dart';

void main() {
  group('TransactionAdmin', () {
    test('should create TransactionAdmin from JSON', () {
      final json = {
        'id': 'admin-123',
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      final admin = TransactionAdmin.fromJson(json);

      expect(admin.id, 'admin-123');
      expect(admin.name, 'John Doe');
      expect(admin.email, 'john@example.com');
    });

    test('should return display name from name', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(admin.displayName, 'John Doe');
    });

    test('should return email prefix as display name when name is null', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: null,
        email: 'john@example.com',
      );

      expect(admin.displayName, 'john');
    });

    test('should return initials from name', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(admin.initials, 'JD');
    });

    test('should return single initial when name has one word', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: 'John',
        email: 'john@example.com',
      );

      expect(admin.initials, 'J');
    });

    test('should return email initial when name is null', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: null,
        email: 'john@example.com',
      );

      expect(admin.initials, 'J');
    });

    test('should convert to JSON correctly', () {
      final admin = TransactionAdmin(
        id: 'admin-123',
        name: 'John Doe',
        email: 'john@example.com',
      );

      final json = admin.toJson();

      expect(json['id'], 'admin-123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
    });
  });

  group('TransactionItem', () {
    test('should create TransactionItem from JSON', () {
      final json = {
        'id': 'item-123',
        'transaction_id': 'trx-123',
        'item_id': 'product-123',
        'item_name': 'Indomie Goreng', // from RPC join, not direct column
        'quantity': 2,
        'price': 3000, // DB column 'price' (sell price)
        'subtotal': 6000,
        'created_at': '2026-01-20T10:00:00Z',
      };

      final item = TransactionItem.fromJson(json);

      expect(item.id, 'item-123');
      expect(item.transactionId, 'trx-123');
      expect(item.itemId, 'product-123');
      expect(item.itemName, 'Indomie Goreng');
      expect(item.quantity, 2);
      expect(item.price, 3000);
      expect(item.sellPrice, 3000); // backward-compat getter
      expect(item.buyPrice, 0); // not in DB schema
      expect(item.subtotal, 6000);
    });

    test('profit is calculated correctly with buy_price', () {
      final item = TransactionItem(
        id: 'item-123',
        transactionId: 'trx-123',
        itemName: 'Indomie Goreng',
        quantity: 5,
        buyPrice: 2000,
        price: 3000,
        subtotal: 15000,
        createdAt: DateTime.now(),
      );

      // Profit = (price - buy_price) * quantity = (3000 - 2000) * 5 = 5000
      expect(item.profit, 5000);
    });
  });

  group('Transaction', () {
    test('should create Transaction from JSON', () {
      final json = {
        'id': 'trx-123',
        'code': 'TRX-20260120-0001',
        'admin_id': 'admin-123',
        'payment_method': 'cash',
        'cash_received': 100000,
        'change_amount': 50000,
        'total': 50000,
        'created_at': '2026-01-20T10:00:00Z',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'trx-123');
      expect(transaction.code, 'TRX-20260120-0001');
      expect(transaction.adminId, 'admin-123');
      expect(transaction.paymentMethod, 'cash');
      expect(transaction.cashReceived, 100000);
      expect(transaction.changeAmount, 50000);
      expect(transaction.total, 50000);
    });

    test('should parse transaction with admin info', () {
      final json = {
        'id': 'trx-123',
        'code': 'TRX-20260120-0001',
        'admin_id': 'admin-123',
        'payment_method': 'qris',
        'total': 50000,
        'created_at': '2026-01-20T10:00:00Z',
        'admin': {
          'id': 'admin-123',
          'name': 'John Doe',
          'email': 'john@example.com',
        },
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.admin, isNotNull);
      expect(transaction.admin!.name, 'John Doe');
      expect(transaction.admin!.email, 'john@example.com');
      expect(transaction.adminName, 'John Doe');
    });

    test('should parse transaction with items', () {
      final json = {
        'id': 'trx-123',
        'code': 'TRX-20260120-0001',
        'admin_id': 'admin-123',
        'payment_method': 'cash',
        'total': 15000,
        'created_at': '2026-01-20T10:00:00Z',
        'transaction_items': [
          {
            'id': 'item-1',
            'transaction_id': 'trx-123',
            'item_name': 'Indomie Goreng',
            'quantity': 5,
            'buy_price': 2000,
            'sell_price': 3000,
            'subtotal': 15000,
            'created_at': '2026-01-20T10:00:00Z',
          },
        ],
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.items.length, 1);
      expect(transaction.items[0].itemName, 'Indomie Goreng');
      expect(transaction.itemCount, 5);
    });

    test('should return Unknown for admin name when admin is null', () {
      final transaction = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 50000,
        createdAt: DateTime.now(),
      );

      expect(transaction.adminName, 'Unknown');
    });

    test('isCash should return true for cash transactions', () {
      final transaction = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 50000,
        createdAt: DateTime.now(),
      );

      expect(transaction.isCash, true);
      expect(transaction.isQris, false);
    });

    test('isQris should return true for QRIS transactions', () {
      final transaction = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'qris',
        total: 50000,
        createdAt: DateTime.now(),
      );

      expect(transaction.isQris, true);
      expect(transaction.isCash, false);
    });

    test('should calculate total profit from items', () {
      final transaction = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 25000,
        createdAt: DateTime.now(),
        items: [
          TransactionItem(
            id: 'item-1',
            transactionId: 'trx-123',
            itemName: 'Item 1',
            quantity: 2,
            buyPrice: 1000,
            price: 2000,
            subtotal: 4000,
            createdAt: DateTime.now(),
          ),
          TransactionItem(
            id: 'item-2',
            transactionId: 'trx-123',
            itemName: 'Item 2',
            quantity: 3,
            buyPrice: 3000,
            price: 5000,
            subtotal: 15000,
            createdAt: DateTime.now(),
          ),
        ],
      );

      // Item 1 profit: (2000 - 1000) * 2 = 2000
      // Item 2 profit: (5000 - 3000) * 3 = 6000
      // Total profit: 2000 + 6000 = 8000
      expect(transaction.totalProfit, 8000);
    });

    test('should format total as Indonesian Rupiah', () {
      final transaction = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 150000,
        createdAt: DateTime.now(),
      );

      expect(transaction.formattedTotal, contains('Rp'));
      expect(transaction.formattedTotal, contains('150'));
    });
  });

  group('Transaction Equality', () {
    test('two transactions with same id should be equal', () {
      final trx1 = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 50000,
        createdAt: DateTime.now(),
      );

      final trx2 = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0002',
        paymentMethod: 'qris',
        total: 100000,
        createdAt: DateTime.now(),
      );

      expect(trx1, equals(trx2));
      expect(trx1.hashCode, equals(trx2.hashCode));
    });

    test('two transactions with different id should not be equal', () {
      final trx1 = Transaction(
        id: 'trx-123',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 50000,
        createdAt: DateTime.now(),
      );

      final trx2 = Transaction(
        id: 'trx-456',
        code: 'TRX-20260120-0001',
        paymentMethod: 'cash',
        total: 50000,
        createdAt: DateTime.now(),
      );

      expect(trx1, isNot(equals(trx2)));
    });
  });
}
