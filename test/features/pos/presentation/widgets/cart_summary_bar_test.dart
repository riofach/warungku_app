import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/providers/cart_provider.dart';
import 'package:warungku_app/features/pos/data/models/cart_item.dart';
import 'package:warungku_app/features/pos/presentation/widgets/cart_summary_bar.dart';

void main() {
  group('CartSummaryBar', () {
    testWidgets('should display cart item count', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2'), quantity: 3),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      // Total quantity should be 5 (2 + 3)
      expect(find.text('5'), findsOneWidget);
      expect(find.text('5 item'), findsOneWidget);
    });

    testWidgets('should display total price formatted as Rupiah', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1', sellPrice: 5000), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2', sellPrice: 3000), quantity: 1),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      // Total should be (5000 * 2) + (3000 * 1) = 13000
      expect(find.textContaining('13.000'), findsOneWidget);
    });

    testWidgets('should display shopping cart icon', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('should display arrow icon for navigation hint', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('should call onTap callback when tapped', (tester) async {
      bool callbackCalled = false;
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: CartSummaryBar(
            onTap: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(CartSummaryBar));
      await tester.pump();

      expect(callbackCalled, true);
    });

    testWidgets('should have correct height of 70', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxHeight, 70);
    });

    testWidgets('should display badge with quantity', (tester) async {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 5),
      ];

      await tester.pumpWidget(
        _createTestWidgetWithCart(
          items: items,
          child: const CartSummaryBar(),
        ),
      );

      // Find Badge widget
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('should update when cart changes', (tester) async {
      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CartSummaryBar(),
            ),
          ),
        ),
      );

      // Initially empty cart
      expect(find.text('0'), findsWidgets);

      // Add item to cart
      container.read(cartNotifierProvider.notifier).addItem(
        _createTestItem('1', 'Test Item', sellPrice: 5000),
      );

      await tester.pump();

      // Should now show 1 item
      expect(find.text('1'), findsWidgets);
      expect(find.text('1 item'), findsOneWidget);

      container.dispose();
    });
  });

  group('CartState', () {
    test('should calculate total quantity correctly', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2'), quantity: 3),
      ];

      final state = CartState(items: items);

      expect(state.totalQuantity, 5);
    });

    test('should calculate total price correctly', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1', sellPrice: 5000), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2', sellPrice: 3000), quantity: 1),
      ];

      final state = CartState(items: items);

      expect(state.totalPrice, 13000);
    });

    test('should return unique item count', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2'), quantity: 3),
        CartItem(item: _createTestItem('3', 'Item 3'), quantity: 1),
      ];

      final state = CartState(items: items);

      expect(state.uniqueItemCount, 3);
    });

    test('isEmpty should return true for empty cart', () {
      final state = CartState.initial();
      expect(state.isEmpty, true);
      expect(state.isNotEmpty, false);
    });

    test('isEmpty should return false for cart with items', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      final state = CartState(items: items);
      expect(state.isEmpty, false);
      expect(state.isNotEmpty, true);
    });

    test('getCartItem should return cart item by id', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 2),
        CartItem(item: _createTestItem('2', 'Item 2'), quantity: 3),
      ];

      final state = CartState(items: items);

      final cartItem = state.getCartItem('1');
      expect(cartItem, isNotNull);
      expect(cartItem!.item.name, 'Item 1');
      expect(cartItem.quantity, 2);
    });

    test('getCartItem should return null for non-existent item', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 2),
      ];

      final state = CartState(items: items);

      final cartItem = state.getCartItem('non-existent');
      expect(cartItem, isNull);
    });

    test('getQuantity should return quantity for item in cart', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 5),
      ];

      final state = CartState(items: items);

      expect(state.getQuantity('1'), 5);
    });

    test('getQuantity should return 0 for item not in cart', () {
      final state = CartState.initial();

      expect(state.getQuantity('non-existent'), 0);
    });

    test('containsItem should return true for item in cart', () {
      final items = [
        CartItem(item: _createTestItem('1', 'Item 1'), quantity: 1),
      ];

      final state = CartState(items: items);

      expect(state.containsItem('1'), true);
      expect(state.containsItem('non-existent'), false);
    });
  });
}

/// Create a test widget with cart items pre-populated
Widget _createTestWidgetWithCart({
  required List<CartItem> items,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      cartNotifierProvider.overrideWith(() => _MockCartNotifier(items)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

/// Mock CartNotifier for testing
class _MockCartNotifier extends CartNotifier {
  final List<CartItem> _items;

  _MockCartNotifier(this._items);

  @override
  CartState build() {
    return CartState(items: _items);
  }
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
