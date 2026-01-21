import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/inventory/data/providers/items_provider.dart';

void main() {
  group('ItemListState', () {
    group('factory constructors', () {
      test('initial() should create state with initial status', () {
        final state = ItemListState.initial();

        expect(state.status, ItemListStatus.initial);
        expect(state.items, isEmpty);
        expect(state.errorMessage, isNull);
      });

      test('loading() should create state with loading status', () {
        final state = ItemListState.loading();

        expect(state.status, ItemListStatus.loading);
        expect(state.items, isEmpty);
        expect(state.errorMessage, isNull);
      });

      test('loaded() should create state with items', () {
        final items = [
          _createTestItem('item-1', 'Test 1'),
          _createTestItem('item-2', 'Test 2'),
        ];

        final state = ItemListState.loaded(items);

        expect(state.status, ItemListStatus.loaded);
        expect(state.items.length, 2);
        expect(state.errorMessage, isNull);
      });

      test('loaded() with empty list should work', () {
        final state = ItemListState.loaded([]);

        expect(state.status, ItemListStatus.loaded);
        expect(state.items, isEmpty);
      });

      test('error() should create state with error message', () {
        final state = ItemListState.error('Network error');

        expect(state.status, ItemListStatus.error);
        expect(state.items, isEmpty);
        expect(state.errorMessage, 'Network error');
      });
    });

    group('computed properties', () {
      test('isLoading should return true only for loading status', () {
        expect(ItemListState.initial().isLoading, false);
        expect(ItemListState.loading().isLoading, true);
        expect(ItemListState.loaded([]).isLoading, false);
        expect(ItemListState.error('err').isLoading, false);
      });

      test('hasError should return true only for error status', () {
        expect(ItemListState.initial().hasError, false);
        expect(ItemListState.loading().hasError, false);
        expect(ItemListState.loaded([]).hasError, false);
        expect(ItemListState.error('err').hasError, true);
      });

      test('isEmpty should return true for loaded state with empty list', () {
        expect(ItemListState.initial().isEmpty, false);
        expect(ItemListState.loading().isEmpty, false);
        expect(ItemListState.loaded([]).isEmpty, true);
        expect(ItemListState.loaded([_createTestItem('1', 'Test')]).isEmpty, false);
        expect(ItemListState.error('err').isEmpty, false);
      });

      test('hasData should return true for loaded state with items', () {
        expect(ItemListState.initial().hasData, false);
        expect(ItemListState.loading().hasData, false);
        expect(ItemListState.loaded([]).hasData, false);
        expect(ItemListState.loaded([_createTestItem('1', 'Test')]).hasData, true);
        expect(ItemListState.error('err').hasData, false);
      });
    });
  });

  group('ItemListStatus enum', () {
    test('should have all required values', () {
      expect(ItemListStatus.values.length, 4);
      expect(ItemListStatus.values.contains(ItemListStatus.initial), true);
      expect(ItemListStatus.values.contains(ItemListStatus.loading), true);
      expect(ItemListStatus.values.contains(ItemListStatus.loaded), true);
      expect(ItemListStatus.values.contains(ItemListStatus.error), true);
    });
  });

  group('State Transitions', () {
    test('initial -> loading transition', () {
      var state = ItemListState.initial();
      expect(state.status, ItemListStatus.initial);

      // Simulate loadItems() call
      state = ItemListState.loading();
      expect(state.status, ItemListStatus.loading);
      expect(state.isLoading, true);
    });

    test('loading -> loaded transition with items', () {
      var state = ItemListState.loading();
      expect(state.isLoading, true);

      // Simulate successful fetch
      final items = [
        _createTestItem('item-1', 'Indomie'),
        _createTestItem('item-2', 'Aqua'),
      ];
      state = ItemListState.loaded(items);

      expect(state.status, ItemListStatus.loaded);
      expect(state.isLoading, false);
      expect(state.hasData, true);
      expect(state.items.length, 2);
    });

    test('loading -> loaded transition with empty list', () {
      var state = ItemListState.loading();

      // Simulate fetch returning empty
      state = ItemListState.loaded([]);

      expect(state.status, ItemListStatus.loaded);
      expect(state.isEmpty, true);
      expect(state.hasData, false);
    });

    test('loading -> error transition', () {
      var state = ItemListState.loading();

      // Simulate fetch error
      state = ItemListState.error('Gagal memuat data barang');

      expect(state.status, ItemListStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Gagal memuat data barang');
    });

    test('error -> loading transition (retry)', () {
      var state = ItemListState.error('Network error');
      expect(state.hasError, true);

      // Simulate retry
      state = ItemListState.loading();

      expect(state.status, ItemListStatus.loading);
      expect(state.hasError, false);
      expect(state.errorMessage, isNull);
    });

    test('loaded -> loading transition (refresh)', () {
      final items = [_createTestItem('item-1', 'Test')];
      var state = ItemListState.loaded(items);
      expect(state.hasData, true);

      // Simulate refresh
      state = ItemListState.loading();

      expect(state.status, ItemListStatus.loading);
      expect(state.items, isEmpty); // Items cleared during loading
    });
  });

  group('Search and Filter State Flow', () {
    test('should transition through search flow correctly', () {
      // Initial load
      var state = ItemListState.initial();
      state = ItemListState.loading();
      state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie Goreng'),
        _createTestItem('item-2', 'Aqua 600ml'),
        _createTestItem('item-3', 'Teh Botol'),
      ]);

      expect(state.items.length, 3);

      // User starts search - triggers loading
      state = ItemListState.loading();
      expect(state.isLoading, true);

      // Search returns filtered results
      state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie Goreng'),
      ]);

      expect(state.items.length, 1);
      expect(state.items[0].name, 'Indomie Goreng');
    });

    test('should handle search with no results', () {
      var state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie'),
      ]);

      // Search for something that doesn't exist
      state = ItemListState.loading();
      state = ItemListState.loaded([]);

      expect(state.isEmpty, true);
      expect(state.hasData, false);
    });

    test('should transition through category filter flow', () {
      // Load all items
      var state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie', categoryId: 'cat-makanan'),
        _createTestItem('item-2', 'Aqua', categoryId: 'cat-minuman'),
        _createTestItem('item-3', 'Teh', categoryId: 'cat-minuman'),
      ]);

      expect(state.items.length, 3);

      // Filter by category
      state = ItemListState.loading();
      state = ItemListState.loaded([
        _createTestItem('item-2', 'Aqua', categoryId: 'cat-minuman'),
        _createTestItem('item-3', 'Teh', categoryId: 'cat-minuman'),
      ]);

      expect(state.items.length, 2);
      expect(state.items.every((item) => item.categoryId == 'cat-minuman'), true);
    });

    test('should handle combined search and filter', () {
      // Initial with filtered items
      var state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie', categoryId: 'cat-makanan'),
        _createTestItem('item-2', 'Mie Sedaap', categoryId: 'cat-makanan'),
      ]);

      // Apply search within category
      state = ItemListState.loading();
      state = ItemListState.loaded([
        _createTestItem('item-1', 'Indomie', categoryId: 'cat-makanan'),
      ]);

      expect(state.items.length, 1);
      expect(state.items[0].name, 'Indomie');
    });
  });

  group('Error State Handling', () {
    test('should preserve error message in error state', () {
      final state = ItemListState.error('Koneksi timeout. Silakan coba lagi.');

      expect(state.errorMessage, 'Koneksi timeout. Silakan coba lagi.');
      expect(state.hasError, true);
    });

    test('error state should have empty items list', () {
      final state = ItemListState.error('Error');

      expect(state.items, isEmpty);
      expect(state.hasData, false);
      expect(state.isEmpty, false); // isEmpty only true for loaded state
    });

    test('different error messages should be captured', () {
      final timeout = ItemListState.error('Koneksi timeout. Silakan coba lagi.');
      final network = ItemListState.error('Gagal memuat data. Periksa koneksi internet.');
      final generic = ItemListState.error('Terjadi kesalahan, silakan coba lagi');

      expect(timeout.errorMessage, contains('timeout'));
      expect(network.errorMessage, contains('koneksi'));
      expect(generic.errorMessage, contains('kesalahan'));
    });
  });

  group('Refresh Flow', () {
    test('refresh should go through loading state', () {
      final states = <ItemListStatus>[];

      // Track state transitions during refresh
      states.add(ItemListState.loaded([_createTestItem('1', 'Test')]).status);
      states.add(ItemListState.loading().status);
      states.add(ItemListState.loaded([_createTestItem('1', 'Test Updated')]).status);

      expect(states, [
        ItemListStatus.loaded,
        ItemListStatus.loading,
        ItemListStatus.loaded,
      ]);
    });

    test('refresh failure should result in error state', () {
      final states = <ItemListStatus>[];

      states.add(ItemListState.loaded([_createTestItem('1', 'Test')]).status);
      states.add(ItemListState.loading().status);
      states.add(ItemListState.error('Refresh failed').status);

      expect(states, [
        ItemListStatus.loaded,
        ItemListStatus.loading,
        ItemListStatus.error,
      ]);
    });
  });

  group('Clear Filters Flow', () {
    test('clear filters should reload all items', () {
      // Filtered state
      var state = ItemListState.loaded([
        _createTestItem('item-1', 'Filtered Item'),
      ]);

      // Clear filters triggers reload
      state = ItemListState.loading();
      state = ItemListState.loaded([
        _createTestItem('item-1', 'Item 1'),
        _createTestItem('item-2', 'Item 2'),
        _createTestItem('item-3', 'Item 3'),
      ]);

      expect(state.items.length, 3);
      expect(state.hasData, true);
    });
  });
}

/// Helper function to create test items
Item _createTestItem(
  String id,
  String name, {
  String? categoryId,
  int stock = 50,
  int stockThreshold = 10,
}) {
  return Item(
    id: id,
    name: name,
    categoryId: categoryId,
    buyPrice: 1000,
    sellPrice: 2000,
    stock: stock,
    stockThreshold: stockThreshold,
    createdAt: DateTime(2026, 1, 20),
    updatedAt: DateTime(2026, 1, 20),
  );
}
