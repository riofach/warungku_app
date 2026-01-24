import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/theme/app_colors.dart';
import 'package:warungku_app/features/dashboard/presentation/widgets/low_stock_item_card.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';

void main() {
  group('LowStockItemCard Widget', () {
    late Item testItem;
    late bool tapCalled;

    setUp(() {
      tapCalled = false;
      testItem = Item(
        id: '1',
        name: 'Indomie Goreng',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        buyPrice: 2500,
        sellPrice: 3000,
        stock: 5,
        stockThreshold: 10,
        imageUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display item name', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Indomie Goreng'), findsOneWidget);
    });

    testWidgets('should display stock count', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Stok: 5'), findsOneWidget);
    });

    testWidgets('should display placeholder when no image url', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('should display image when image url exists', (tester) async {
      // Arrange
      final itemWithImage = Item(
        id: '1',
        name: 'Indomie Goreng',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        buyPrice: 2500,
        sellPrice: 3000,
        stock: 5,
        stockThreshold: 10,
        imageUrl: 'https://example.com/image.jpg',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: itemWithImage,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(tapCalled, isTrue);
    });

    testWidgets('should have warning border color for low stock items',
        (tester) async {
      // Arrange - item with low stock
      final lowStockItem = Item(
        id: '1',
        name: 'Indomie Goreng',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        buyPrice: 2500,
        sellPrice: 3000,
        stock: 5,
        stockThreshold: 10,
        imageUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: lowStockItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final borderColor = (shape.side).color;

      expect(borderColor, AppColors.warning.withOpacity(0.5));
    });

    testWidgets('should have error border color for out of stock items',
        (tester) async {
      // Arrange - item with zero stock
      final outOfStockItem = Item(
        id: '1',
        name: 'Teh Botol',
        categoryId: 'cat-2',
        categoryName: 'Minuman',
        buyPrice: 3000,
        sellPrice: 4000,
        stock: 0,
        stockThreshold: 20,
        imageUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: outOfStockItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final borderColor = (shape.side).color;

      expect(borderColor, AppColors.error.withOpacity(0.5));
    });

    testWidgets('should truncate long item names', (tester) async {
      // Arrange - item with very long name
      final longNameItem = Item(
        id: '1',
        name: 'Indomie Goreng Rasa Ayam Bawang Ekstra Pedas Super Jumbo',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        buyPrice: 2500,
        sellPrice: 3000,
        stock: 5,
        stockThreshold: 10,
        imageUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: longNameItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(
        find.text(
            'Indomie Goreng Rasa Ayam Bawang Ekstra Pedas Super Jumbo'),
      );
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should have fixed width of 120', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Card),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 120);
    });

    testWidgets('should display stock status icon', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockItemCard(
              item: testItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert - should have an icon for stock status
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.size == 12,
        ),
        findsOneWidget,
      );
    });
  });
}
