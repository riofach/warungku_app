import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/models/cart_item.dart';
import 'package:warungku_app/features/pos/data/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper to create test items
Item createTestItem(String id, String name, int price, int stock) {
  return Item(
    id: id,
    name: name,
    buyPrice: price - 1000,
    sellPrice: price,
    stock: stock,
    categoryId: 'cat1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('CartNotifier', () {
    test('should add item to cart', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Test Item', 10000, 10);

      notifier.addItem(item);

      final state = container.read(cartNotifierProvider);
      expect(state.items.length, 1);
      expect(state.items.first.item.id, '1');
      expect(state.items.first.quantity, 1);
      expect(state.totalPrice, 10000);
    });

    test('should increment quantity if item exists', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Test Item', 10000, 10);

      notifier.addItem(item);
      notifier.addItem(item);

      final state = container.read(cartNotifierProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 2);
      expect(state.totalPrice, 20000);
    });

    test('should not exceed stock when adding item', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Limited Item', 10000, 2);

      notifier.addItem(item); // 1
      notifier.addItem(item); // 2
      notifier.addItem(item); // Should fail (stock 2)

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 2);
    });

    test('should update quantity correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Test Item', 10000, 10);

      notifier.addItem(item);
      notifier.updateQuantity('1', 5);

      final state = container.read(cartNotifierProvider);
      expect(state.items.first.quantity, 5);
      expect(state.totalPrice, 50000);
    });

    test('should remove item when quantity is 0', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Test Item', 10000, 10);

      notifier.addItem(item);
      notifier.updateQuantity('1', 0);

      final state = container.read(cartNotifierProvider);
      expect(state.items.isEmpty, true);
    });

    test('should remove item explicitly', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Test Item', 10000, 10);

      notifier.addItem(item);
      notifier.removeItem('1');

      final state = container.read(cartNotifierProvider);
      expect(state.items.isEmpty, true);
    });

    test('should clear cart', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item1 = createTestItem('1', 'Item 1', 10000, 10);
      final item2 = createTestItem('2', 'Item 2', 20000, 10);

      notifier.addItem(item1);
      notifier.addItem(item2);
      notifier.clearCart();

      final state = container.read(cartNotifierProvider);
      expect(state.items.isEmpty, true);
      expect(state.totalQuantity, 0);
      expect(state.totalPrice, 0);
    });
    
    test('canAddMore returns false when stock limit reached', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      final item = createTestItem('1', 'Limited Item', 10000, 2);

      notifier.addItem(item, quantity: 2);
      
      expect(notifier.canAddMore('1'), false);
    });
  });
}
