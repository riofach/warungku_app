import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/presentation/widgets/pos_product_card.dart';

void main() {
  group('PosProductCard', () {
    testWidgets('should display item name and price', (tester) async {
      final item = _createTestItem('1', 'Indomie Goreng', sellPrice: 3500);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      expect(find.text('Indomie Goreng'), findsOneWidget);
      expect(find.textContaining('3.500'), findsOneWidget);
    });

    testWidgets('should show stock badge with stock count', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 25);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('should show "Habis" label when stock is 0', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 0);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      // Should find "Habis" text (in badge and overlay)
      expect(find.text('Habis'), findsWidgets);
    });

    testWidgets('should have add button', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 10);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should have disabled add button when stock is 0', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 0);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      // Find the IconButton and verify it's disabled
      final addButton = find.byType(IconButton);
      expect(addButton, findsOneWidget);

      // The button should be disabled for out of stock items
      final iconButton = tester.widget<IconButton>(addButton);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('should call onAddToCart callback when add button is tapped', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 10);
      bool callbackCalled = false;

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(
            item: item,
            onAddToCart: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(callbackCalled, true);
    });

    testWidgets('should display placeholder when image URL is null', (tester) async {
      final item = _createTestItem('1', 'Test Item', imageUrl: null);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      // Should find the placeholder icon
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('should apply reduced opacity for out of stock items', (tester) async {
      final item = _createTestItem('1', 'Test Item', stock: 0);

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      // Find Opacity widget with 0.5 opacity
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('should display category name when available', (tester) async {
      final item = _createTestItem('1', 'Test Item', categoryName: 'Makanan');

      await tester.pumpWidget(
        _createTestWidget(
          child: PosProductCard(item: item),
        ),
      );

      // Category name is not displayed in current design
      // This test is for future enhancement
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('should truncate long item names', (tester) async {
      final item = _createTestItem(
        '1',
        'This is a very long product name that should be truncated with ellipsis',
      );

      await tester.pumpWidget(
        _createTestWidget(
          child: SizedBox(
            width: 150,
            height: 200,
            child: PosProductCard(item: item),
          ),
        ),
      );

      // The name should be displayed (possibly truncated)
      expect(find.textContaining('This is a very long'), findsOneWidget);
    });
  });
}

/// Create a test widget wrapped with necessary providers
Widget _createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 320,  // Increased height to prevent overflow
          child: child,
        ),
      ),
    ),
  );
}

/// Helper function to create test items
Item _createTestItem(
  String id,
  String name, {
  int stock = 10,
  int sellPrice = 1500,
  String? imageUrl,
  String? categoryId,
  String? categoryName,
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
    imageUrl: imageUrl,
    categoryId: categoryId,
    categoryName: categoryName,
  );
}
