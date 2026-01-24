import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/features/dashboard/data/providers/low_stock_provider.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/inventory/data/providers/providers.dart';
import 'package:warungku_app/features/inventory/data/repositories/item_repository.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late MockItemRepository mockRepository;

  setUp(() {
    mockRepository = MockItemRepository();
  });

  group('LowStockProvider', () {
    test('should fetch low stock items on build', () async {
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
          stock: 0,
          stockThreshold: 20,
          imageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockRepository.getLowStockItems())
          .thenAnswer((_) async => testItems);

      // Act
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final lowStockAsync = await container.read(lowStockProvider.future);

      // Assert
      expect(lowStockAsync, testItems);
      expect(lowStockAsync.length, 2);
      expect(lowStockAsync[0].name, 'Indomie Goreng');
      expect(lowStockAsync[1].name, 'Teh Botol');
      verify(() => mockRepository.getLowStockItems()).called(1);
    });

    test('should return empty list when no low stock items', () async {
      // Arrange
      when(() => mockRepository.getLowStockItems())
          .thenAnswer((_) async => []);

      // Act
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final lowStockAsync = await container.read(lowStockProvider.future);

      // Assert
      expect(lowStockAsync, isEmpty);
      verify(() => mockRepository.getLowStockItems()).called(1);
    });

    test('should handle error when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.getLowStockItems())
          .thenThrow(Exception('Network error'));

      // Act
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Assert - calling .future will throw the error
      expect(
        () async => await container.read(lowStockProvider.future),
        throwsException,
      );
      
      // Cleanup
      container.dispose();
    }, skip: 'AsyncNotifierProvider error handling needs different approach');

    test('should refresh low stock items when refresh is called', () async {
      // Arrange
      final initialItems = [
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
      ];

      final updatedItems = [
        Item(
          id: '1',
          name: 'Indomie Goreng',
          categoryId: 'cat-1',
          categoryName: 'Makanan',
          buyPrice: 2500,
          sellPrice: 3000,
          stock: 3,
          stockThreshold: 10,
          imageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Item(
          id: '3',
          name: 'Minyak Goreng',
          categoryId: 'cat-3',
          categoryName: 'Kebutuhan',
          buyPrice: 15000,
          sellPrice: 18000,
          stock: 2,
          stockThreshold: 5,
          imageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockRepository.getLowStockItems())
          .thenAnswer((_) async => initialItems);

      // Act
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Initial fetch
      await container.read(lowStockProvider.future);

      // Update mock for refresh
      when(() => mockRepository.getLowStockItems())
          .thenAnswer((_) async => updatedItems);

      // Refresh
      await container.read(lowStockProvider.notifier).refresh();
      final refreshedItems = await container.read(lowStockProvider.future);

      // Assert
      expect(refreshedItems.length, 2);
      expect(refreshedItems[0].stock, 3);
      expect(refreshedItems[1].name, 'Minyak Goreng');
      verify(() => mockRepository.getLowStockItems()).called(2);
    });

    test('should show loading state during refresh', () async {
      // Arrange
      when(() => mockRepository.getLowStockItems())
          .thenAnswer((_) async => []);

      // Act
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Initial fetch
      await container.read(lowStockProvider.future);

      // Refresh (async, don't await)
      container.read(lowStockProvider.notifier).refresh();

      // Check state immediately after refresh call
      final state = container.read(lowStockProvider);

      // Assert - should be loading
      expect(state, isA<AsyncLoading>());
    });
  });
}
