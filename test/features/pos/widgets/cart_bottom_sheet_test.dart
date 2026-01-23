import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/presentation/widgets/cart_bottom_sheet.dart';
import 'package:warungku_app/features/pos/data/providers/cart_provider.dart';
import 'package:warungku_app/features/pos/data/models/cart_item.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';

// Mock data
final testItem = Item(
  id: '1',
  name: 'Test Item',
  buyPrice: 9000,
  sellPrice: 10000,
  stock: 10,
  categoryId: 'cat1',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final testCartItem = CartItem(item: testItem, quantity: 2);

void main() {
  group('CartBottomSheet', () {
    testWidgets('should show empty state when cart is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartNotifierProvider.overrideWith(() => MockCartNotifierEmpty()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DraggableScrollableSheet(
                builder: (context, scrollController) {
                  return CartBottomSheet(scrollController: scrollController);
                },
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Keranjang'), findsOneWidget);
      expect(find.text('Keranjang Kosong'), findsOneWidget);
      expect(find.text('Belum ada barang yang ditambahkan'), findsOneWidget);
      expect(find.text('Bayar'), findsNothing); // Button should not show when empty
    });

    testWidgets('should show items and total when cart has items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartNotifierProvider.overrideWith(() => MockCartNotifierWithItems()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DraggableScrollableSheet(
                builder: (context, scrollController) {
                  return CartBottomSheet(scrollController: scrollController);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Keranjang'), findsOneWidget);
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Total Pembayaran'), findsOneWidget);
      
      // We expect 2 occurrences: one in the cart item tile (subtotal) and one in the footer (total)
      expect(find.text('Rp 20.000'), findsNWidgets(2)); 
      
      expect(find.text('Bayar'), findsOneWidget); // Updated to match AC #2
    });
  });
}

// Mocks
class MockCartNotifierEmpty extends CartNotifier {
  @override
  CartState build() {
    return const CartState(items: []);
  }
}

class MockCartNotifierWithItems extends CartNotifier {
  @override
  CartState build() {
    return CartState(items: [testCartItem]);
  }
}
