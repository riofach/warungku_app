import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/dashboard/data/providers/low_stock_provider.dart';
import 'package:warungku_app/features/dashboard/presentation/widgets/low_stock_alert.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';

void main() {
  group('LowStockAlert Widget', () {
    testWidgets('should display header with warning icon and title',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Stok Menipis'), findsOneWidget);
    });

    testWidgets('should display count badge when items exist', (tester) async {
      // Arrange
      final testItems = [
        Item(
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
        ),
        Item(
          id: '2',
          name: 'Teh Botol',
          categoryId: 'cat-2',
          categoryName: 'Minuman',
          buyPrice: 3000,
          sellPrice: 4000,
          stock: 3,
          stockThreshold: 20,
          imageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: testItems),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2'), findsOneWidget); // Count badge
      expect(find.text('Stok Menipis'), findsOneWidget);
    });

    testWidgets('should display empty state when no low stock items',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('✅ Semua stok aman!'), findsOneWidget);
    });

    testWidgets('should display horizontal list when items exist',
        (tester) async {
      // Arrange
      final testItems = [
        Item(
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
        ),
        Item(
          id: '2',
          name: 'Teh Botol',
          categoryId: 'cat-2',
          categoryName: 'Minuman',
          buyPrice: 3000,
          sellPrice: 4000,
          stock: 3,
          stockThreshold: 20,
          imageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: testItems),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Indomie Goreng'), findsOneWidget);
      expect(find.text('Teh Botol'), findsOneWidget);
    });

    testWidgets('should display shimmer loading state', (tester) async {
      // Arrange - create a provider that stays in loading state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifierLoading(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );

      // Act - pump once to start loading
      await tester.pump();

      // Assert - should show shimmer cards
      expect(find.byType(ListView), findsOneWidget);
      // Shimmer cards should be visible
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('should display error message on error', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: []), // Default success
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change state to error
      final container = ProviderScope.containerOf(tester.element(find.byType(LowStockAlert)));
      container.read(lowStockProvider.notifier).state = AsyncValue.error(
        Exception('Network error'),
        StackTrace.current,
      );
      
      await tester.pump();

      // Assert
      expect(find.text('Gagal memuat data stok'), findsOneWidget);
    });

    testWidgets('should not display count badge when count is 0',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowStockProvider.overrideWith(
              () => _TestLowStockNotifier(testData: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LowStockAlert(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('0'), findsNothing); // Count badge should not exist
      expect(find.text('Stok Menipis'), findsOneWidget);
    });
  });
}

/// Helper notifier for testing with success data
class _TestLowStockNotifier extends LowStockNotifier {
  final List<Item> testData;

  _TestLowStockNotifier({this.testData = const []});

  @override
  Future<List<Item>> build() async {
    return testData;
  }
}

/// Helper notifier for testing loading state
class _TestLowStockNotifierLoading extends LowStockNotifier {
  @override
  Future<List<Item>> build() async {
    // Completer so we can finish the build when the test is done
    // and avoid pending timers
    final completer = Completer<List<Item>>();
    ref.onDispose(() {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });
    return completer.future;
  }
}

/// Helper notifier for testing error state
class _TestLowStockNotifierError extends LowStockNotifier {
  @override
  Future<List<Item>> build() async {
    return Future.delayed(
      const Duration(milliseconds: 10),
      () => throw Exception('Network error'),
    );
  }
}
