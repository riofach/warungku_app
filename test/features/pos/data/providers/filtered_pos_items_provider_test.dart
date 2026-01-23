import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/providers/pos_items_provider.dart';
import 'package:warungku_app/features/pos/data/providers/pos_search_provider.dart';
import 'package:warungku_app/features/pos/data/providers/pos_category_filter_provider.dart';
import 'package:warungku_app/features/pos/data/providers/filtered_pos_items_provider.dart';

void main() {
  group('FilteredPosItemsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should return empty list when items not loaded', () {
      // Initial state - not loaded
      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems, isEmpty);
    });

    test('should return all items when no filter applied', () {
      // Create test items
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
        _createTestItem('3', 'Mie Sedap', categoryId: 'cat-1'),
      ];

      // Override the provider state to loaded
      // Simulate loaded state by setting state directly
      container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems.length, 3);
    });

    test('should filter items by search query (case-insensitive)', () {
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
        _createTestItem('3', 'Mie Sedap', categoryId: 'cat-1'),
      ];

      container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      // Set search query
      container.read(posSearchQueryProvider.notifier).state = 'mie';

      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems.length, 2); // Indomie Goreng, Mie Sedap
      expect(filteredItems.any((item) => item.name == 'Indomie Goreng'), true);
      expect(filteredItems.any((item) => item.name == 'Mie Sedap'), true);
    });

    test('should filter items by category', () {
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
        _createTestItem('3', 'Mie Sedap', categoryId: 'cat-1'),
      ];

      container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      // Set category filter
      container.read(posCategoryFilterProvider.notifier).state = 'cat-1';

      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems.length, 2); // Indomie Goreng, Mie Sedap
      expect(filteredItems.every((item) => item.categoryId == 'cat-1'), true);
    });

    test('should combine search and category filters', () {
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
        _createTestItem('3', 'Mie Sedap', categoryId: 'cat-1'),
        _createTestItem('4', 'Indomie Kuah', categoryId: 'cat-1'),
      ];

      container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      // Set both filters
      container.read(posSearchQueryProvider.notifier).state = 'indomie';
      container.read(posCategoryFilterProvider.notifier).state = 'cat-1';

      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems.length, 2); // Indomie Goreng, Indomie Kuah
      expect(filteredItems.every((item) => item.name.toLowerCase().contains('indomie')), true);
      expect(filteredItems.every((item) => item.categoryId == 'cat-1'), true);
    });

    test('should return empty list when search query has no matches', () {
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
      ];

      container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      // Set search query with no matches
      container.read(posSearchQueryProvider.notifier).state = 'xyz123';

      final filteredItems = container.read(filteredPosItemsProvider);
      expect(filteredItems, isEmpty);
    });
  });

  group('posHasActiveFilterProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should return false when no filter is active', () {
      final hasActiveFilter = container.read(posHasActiveFilterProvider);
      expect(hasActiveFilter, false);
    });

    test('should return true when search query is set', () {
      container.read(posSearchQueryProvider.notifier).state = 'test';
      final hasActiveFilter = container.read(posHasActiveFilterProvider);
      expect(hasActiveFilter, true);
    });

    test('should return true when category filter is set', () {
      container.read(posCategoryFilterProvider.notifier).state = 'cat-1';
      final hasActiveFilter = container.read(posHasActiveFilterProvider);
      expect(hasActiveFilter, true);
    });

    test('should return true when both filters are set', () {
      container.read(posSearchQueryProvider.notifier).state = 'test';
      container.read(posCategoryFilterProvider.notifier).state = 'cat-1';
      final hasActiveFilter = container.read(posHasActiveFilterProvider);
      expect(hasActiveFilter, true);
    });
  });

  group('filteredPosItemsCountProvider', () {
    test('should return count of filtered items', () {
      final items = [
        _createTestItem('1', 'Indomie Goreng', categoryId: 'cat-1'),
        _createTestItem('2', 'Aqua 600ml', categoryId: 'cat-2'),
        _createTestItem('3', 'Mie Sedap', categoryId: 'cat-1'),
      ];

      final container = ProviderContainer(
        overrides: [
          posItemsNotifierProvider.overrideWith(() => _MockPosItemsNotifier(items)),
        ],
      );

      container.read(posSearchQueryProvider.notifier).state = 'mie';

      final count = container.read(filteredPosItemsCountProvider);
      expect(count, 2);

      container.dispose();
    });
  });
}

/// Mock PosItemsNotifier for testing
class _MockPosItemsNotifier extends PosItemsNotifier {
  final List<Item> _items;

  _MockPosItemsNotifier(this._items);

  @override
  PosItemsState build() {
    return PosItemsState.loaded(_items);
  }

  @override
  Future<void> loadItems() async {
    state = PosItemsState.loaded(_items);
  }
}

/// Helper function to create test items
Item _createTestItem(String id, String name, {int stock = 10, String? categoryId}) {
  return Item(
    id: id,
    name: name,
    buyPrice: 1000,
    sellPrice: 1500,
    stock: stock,
    stockThreshold: 5,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    categoryId: categoryId,
  );
}
