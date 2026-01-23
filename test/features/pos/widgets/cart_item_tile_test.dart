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

    testWidgets('should disable increment button when at stock limit', (WidgetTester tester) async {
      final item = createTestItem('1', 'Test Product', 50000, 5);
      final cartItem = CartItem(item: item, quantity: 5); // At stock limit

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemTile(cartItem: cartItem),
            ),
          ),
        ),
      );

      // Find all IconButtons
      final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
      
      // The add button should be the third IconButton (after decrement and before delete)
      // Index: 0 = decrement, 1 = increment, 2 = delete
      final incrementButton = iconButtons.elementAt(1);
      
      // Verify it's disabled
      expect(incrementButton.onPressed, isNull);
    });

    testWidgets('should enable increment button when below stock limit', (WidgetTester tester) async {
      final item = createTestItem('1', 'Test Product', 50000, 10);
      final cartItem = CartItem(item: item, quantity: 5); // Below stock limit

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemTile(cartItem: cartItem),
            ),
          ),
        ),
      );

      // Find all IconButtons
      final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
      
      // The add button should be the second IconButton
      final incrementButton = iconButtons.elementAt(1);
      
      // Verify it's enabled
      expect(incrementButton.onPressed, isNotNull);
    });

    testWidgets('should disable decrement button when quantity is 1', (WidgetTester tester) async {
      final item = createTestItem('1', 'Test Product', 50000, 10);
      final cartItem = CartItem(item: item, quantity: 1);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemTile(cartItem: cartItem),
            ),
          ),
        ),
      );

      // Find all IconButtons
      final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
      
      // The decrement button should be the first IconButton
      final decrementButton = iconButtons.elementAt(0);
      
      // Verify it's disabled
      expect(decrementButton.onPressed, isNull);
    });

    testWidgets('should show delete confirmation dialog on delete tap', (WidgetTester tester) async {
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

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Hapus Item?'), findsOneWidget);
      expect(find.text('Hapus "Test Product" dari keranjang?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });
  });
}
