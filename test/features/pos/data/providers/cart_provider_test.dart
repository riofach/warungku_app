import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/models/cart_item.dart';
import 'package:warungku_app/features/pos/data/providers/cart_provider.dart';

void main() {
  group('CartItem', () {
    test('should calculate subtotal correctly', () {
      final item = _createTestItem('1', 'Test', sellPrice: 5000);
      final cartItem = CartItem(item: item, quantity: 3);

      expect(cartItem.subtotal, 15000);
    });

    test('copyWith should create new instance with updated values', () {
      final item = _createTestItem('1', 'Test', sellPrice: 5000);
      final cartItem = CartItem(item: item, quantity: 2);

      final updated = cartItem.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.item.id, '1');
      expect(updated.subtotal, 25000);
    });

    test('equality should be based on item id', () {
      final item1 = _createTestItem('1', 'Test', sellPrice: 5000);
      final item2 = _createTestItem('1', 'Test', sellPrice: 5000);

      final cartItem1 = CartItem(item: item1, quantity: 2);
      final cartItem2 = CartItem(item: item2, quantity: 3);

      expect(cartItem1, equals(cartItem2));
    });

    test('different item ids should not be equal', () {
      final item1 = _createTestItem('1', 'Test', sellPrice: 5000);
      final item2 = _createTestItem('2', 'Test', sellPrice: 5000);

      final cartItem1 = CartItem(item: item1, quantity: 2);
      final cartItem2 = CartItem(item: item2, quantity: 2);

      expect(cartItem1, isNot(equals(cartItem2)));
    });
  });

  group('CartNotifier', () {
    late ProviderContainer container;
    late CartNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(cartNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(cartNotifierProvider);
      expect(state.isEmpty, true);
      expect(state.items, isEmpty);
    });

    test('addItem should add new item to cart', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);

      notifier.addItem(item);

      final state = container.read(cartNotifierProvider);
      expect(state.items.length, 1);
      expect(state.items.first.item.id, '1');
      expect(state.items.first.quantity, 1);
    });

    test('addItem should increment quantity for existing item', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);

      notifier.addItem(item);
      notifier.addItem(item);
      notifier.addItem(item);

      final state = container.read(cartNotifierProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 3);
    });

    test('addItem should respect stock limit', () {
      final item = _createTestItem('1', 'Test Item', stock: 2);

      notifier.addItem(item);
      notifier.addItem(item);
      notifier.addItem(item); // Should not add - stock limit

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 2);
    });

    test('addItem with quantity should add multiple at once', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);

      notifier.addItem(item, quantity: 5);

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 5);
    });

    test('updateQuantity should update item quantity', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      notifier.addItem(item, quantity: 2);

      notifier.updateQuantity('1', 5);

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 5);
    });

    test('updateQuantity to 0 should remove item', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      notifier.addItem(item);

      notifier.updateQuantity('1', 0);

      final state = container.read(cartNotifierProvider);
      expect(state.isEmpty, true);
    });

    test('updateQuantity should respect stock limit', () {
      final item = _createTestItem('1', 'Test Item', stock: 5);
      notifier.addItem(item);

      notifier.updateQuantity('1', 10);

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 5); // Capped at stock
    });

    test('incrementQuantity should increase by 1', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      notifier.addItem(item, quantity: 2);

      notifier.incrementQuantity('1');

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 3);
    });

    test('incrementQuantity should respect stock limit', () {
      final item = _createTestItem('1', 'Test Item', stock: 3);
      notifier.addItem(item, quantity: 3);

      notifier.incrementQuantity('1');

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 3); // Not incremented
    });

    test('decrementQuantity should decrease by 1', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      notifier.addItem(item, quantity: 5);

      notifier.decrementQuantity('1');

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 4);
    });

    test('decrementQuantity to 0 should remove item', () {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      notifier.addItem(item, quantity: 1);

      notifier.decrementQuantity('1');

      final state = container.read(cartNotifierProvider);
      expect(state.isEmpty, true);
    });

    test('removeItem should remove item from cart', () {
      final item1 = _createTestItem('1', 'Item 1', stock: 10);
      final item2 = _createTestItem('2', 'Item 2', stock: 10);
      notifier.addItem(item1);
      notifier.addItem(item2);

      notifier.removeItem('1');

      final state = container.read(cartNotifierProvider);
      expect(state.items.length, 1);
      expect(state.items.first.item.id, '2');
    });

    test('clearCart should remove all items', () {
      final item1 = _createTestItem('1', 'Item 1', stock: 10);
      final item2 = _createTestItem('2', 'Item 2', stock: 10);
      notifier.addItem(item1);
      notifier.addItem(item2);

      notifier.clearCart();

      final state = container.read(cartNotifierProvider);
      expect(state.isEmpty, true);
    });

    test('canAddMore should return true when below stock limit', () {
      final item = _createTestItem('1', 'Test Item', stock: 5);
      notifier.addItem(item, quantity: 3);

      expect(notifier.canAddMore('1'), true);
    });

    test('canAddMore should return false when at stock limit', () {
      final item = _createTestItem('1', 'Test Item', stock: 5);
      notifier.addItem(item, quantity: 5);

      expect(notifier.canAddMore('1'), false);
    });

    test('canAddMore should return true for item not in cart', () {
      expect(notifier.canAddMore('non-existent'), true);
    });
  });

  group('Cart Providers', () {
    test('cartTotalQuantityProvider should return total quantity', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);

      notifier.addItem(_createTestItem('1', 'Item 1', stock: 10), quantity: 3);
      notifier.addItem(_createTestItem('2', 'Item 2', stock: 10), quantity: 2);

      final total = container.read(cartTotalQuantityProvider);
      expect(total, 5);

      container.dispose();
    });

    test('cartTotalPriceProvider should return total price', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);

      notifier.addItem(_createTestItem('1', 'Item 1', sellPrice: 5000, stock: 10), quantity: 2);
      notifier.addItem(_createTestItem('2', 'Item 2', sellPrice: 3000, stock: 10), quantity: 1);

      final total = container.read(cartTotalPriceProvider);
      expect(total, 13000);

      container.dispose();
    });

    test('cartIsEmptyProvider should return true for empty cart', () {
      final container = ProviderContainer();

      final isEmpty = container.read(cartIsEmptyProvider);
      expect(isEmpty, true);

      container.dispose();
    });

    test('cartIsEmptyProvider should return false for cart with items', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);

      notifier.addItem(_createTestItem('1', 'Item 1', stock: 10));

      final isEmpty = container.read(cartIsEmptyProvider);
      expect(isEmpty, false);

      container.dispose();
    });

    test('cartUniqueItemCountProvider should return unique item count', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);

      notifier.addItem(_createTestItem('1', 'Item 1', stock: 10), quantity: 3);
      notifier.addItem(_createTestItem('2', 'Item 2', stock: 10), quantity: 2);
      notifier.addItem(_createTestItem('3', 'Item 3', stock: 10), quantity: 1);

      final count = container.read(cartUniqueItemCountProvider);
      expect(count, 3);

      container.dispose();
    });
  });
}

/// Helper function to create test items
Item _createTestItem(
  String id,
  String name, {
  int stock = 10,
  int sellPrice = 1500,
}) {
  return Item(
    id: id,
    name: name,
    buyPrice: 1000,
    sellPrice: sellPrice,
    stock: stock,
    stockThreshold: 5,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
