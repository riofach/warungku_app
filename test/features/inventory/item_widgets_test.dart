import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/inventory/presentation/widgets/stock_indicator.dart';
import 'package:warungku_app/features/inventory/presentation/widgets/item_card.dart';

void main() {
  group('StockIndicator Widget', () {
    Widget buildWidget(Item item, {bool iconOnly = false, bool compact = false}) {
      return MaterialApp(
        home: Scaffold(
          body: StockIndicator(
            item: item,
            iconOnly: iconOnly,
            compact: compact,
          ),
        ),
      );
    }

    testWidgets('should display green indicator for normal stock', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 50, // Above threshold
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Stok: 50'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });

    testWidgets('should display yellow indicator for low stock', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 5, // Below threshold
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Stok: 5'), findsOneWidget);
    });

    testWidgets('should display red indicator and "Habis" for out of stock', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 0,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Habis'), findsOneWidget);
    });

    testWidgets('should show only icon when iconOnly is true', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 50,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, iconOnly: true));

      expect(find.text('Stok: 50'), findsNothing);
      // Icon should be present
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('should show compact format when compact is true', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 25,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, compact: true));

      expect(find.text('25'), findsOneWidget);
      expect(find.text('Stok: 25'), findsNothing);
    });
  });

  group('StockDot Widget', () {
    Widget buildWidget(Item item, {double size = 8}) {
      return MaterialApp(
        home: Scaffold(
          body: StockDot(item: item, size: size),
        ),
      );
    }

    testWidgets('should render a small dot', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 50,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      // Find the Container widget
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 8);
      expect(container.constraints?.maxHeight, 8);
    });

    testWidgets('should respect custom size', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test',
        buyPrice: 1000,
        sellPrice: 2000,
        stock: 50,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, size: 12));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 12);
    });
  });

  group('ItemCard Widget', () {
    Widget buildWidget(Item item, {VoidCallback? onTap, bool showCategory = true}) {
      return MaterialApp(
        home: Scaffold(
          body: ItemCard(
            item: item,
            onTap: onTap,
            showCategory: showCategory,
          ),
        ),
      );
    }

    testWidgets('should display item name', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Indomie Goreng',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Indomie Goreng'), findsOneWidget);
    });

    testWidgets('should display formatted price', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Rp 3.500'), findsOneWidget);
    });

    testWidgets('should display stock indicator', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        stockThreshold: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.byType(StockIndicator), findsOneWidget);
      expect(find.text('Stok: 50'), findsOneWidget);
    });

    testWidgets('should display category badge when categoryName is provided', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        categoryName: 'Makanan',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Makanan'), findsOneWidget);
    });

    testWidgets('should NOT display category badge when showCategory is false', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        categoryName: 'Makanan',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, showCategory: false));

      expect(find.text('Makanan'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      bool tapped = false;
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, onTap: () => tapped = true));

      await tester.tap(find.byType(ItemCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should show placeholder icon when no image url', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        imageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('should display card with proper structure', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Test Item',
        buyPrice: 2500,
        sellPrice: 3500,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      // Verify Card widget exists
      expect(find.byType(Card), findsOneWidget);
      
      // Verify InkWell for tap gesture
      expect(find.byType(InkWell), findsOneWidget);
    });
  });

  group('ItemCardCompact Widget', () {
    Widget buildWidget(Item item, {VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: ItemCardCompact(
            item: item,
            onTap: onTap,
          ),
        ),
      );
    }

    testWidgets('should display item name and price', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Compact Item',
        buyPrice: 2500,
        sellPrice: 4000,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.text('Compact Item'), findsOneWidget);
      expect(find.text('Rp 4.000'), findsOneWidget);
    });

    testWidgets('should display stock dot', (tester) async {
      final item = Item(
        id: 'item-1',
        name: 'Compact Item',
        buyPrice: 2500,
        sellPrice: 4000,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item));

      expect(find.byType(StockDot), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;
      final item = Item(
        id: 'item-1',
        name: 'Compact Item',
        buyPrice: 2500,
        sellPrice: 4000,
        stock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildWidget(item, onTap: () => tapped = true));

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
