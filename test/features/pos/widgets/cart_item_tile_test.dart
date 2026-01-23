import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:warungku_app/features/pos/presentation/widgets/cart_item_tile.dart';
import 'package:warungku_app/features/pos/data/models/cart_item.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/providers/cart_provider.dart';

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
  group('CartItemTile', () {
    testWidgets('should display item details correctly', (WidgetTester tester) async {
      final item = createTestItem('1', 'Test Product', 50000, 10);
      final cartItem = CartItem(item: item, quantity: 2);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemTile(cartItem: cartItem),
            ),
          ),
        ),
      );

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget); // Unit price
      expect(find.text('Rp 100.000'), findsOneWidget); // Subtotal
      expect(find.text('2'), findsOneWidget); // Quantity
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    // Note: Interaction tests (increment/decrement/delete) require more complex 
    // mocking of the Notifier which is better covered in provider tests or integration tests
    // For now we just verify rendering correctness.
  });
}
