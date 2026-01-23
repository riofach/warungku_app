import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/pos/data/providers/pos_items_provider.dart';

void main() {
  group('PosItemsState', () {
    group('factory constructors', () {
      test('initial() should create state with initial status', () {
        final state = PosItemsState.initial();

        expect(state.status, PosItemsStatus.initial);
        expect(state.items, isEmpty);
        expect(state.errorMessage, isNull);
      });

      test('loading() should create state with loading status', () {
        final state = PosItemsState.loading();

        expect(state.status, PosItemsStatus.loading);
        expect(state.items, isEmpty);
        expect(state.errorMessage, isNull);
      });

      test('loaded() should create state with items', () {
        final items = [
          _createTestItem('item-1', 'Test 1'),
          _createTestItem('item-2', 'Test 2'),
        ];

        final state = PosItemsState.loaded(items);

        expect(state.status, PosItemsStatus.loaded);
        expect(state.items.length, 2);
        expect(state.errorMessage, isNull);
      });

      test('loaded() with empty list should work', () {
        final state = PosItemsState.loaded([]);

        expect(state.status, PosItemsStatus.loaded);
        expect(state.items, isEmpty);
      });

      test('error() should create state with error message', () {
        final state = PosItemsState.error('Network error');

        expect(state.status, PosItemsStatus.error);
        expect(state.items, isEmpty);
        expect(state.errorMessage, 'Network error');
      });
    });

    group('computed properties', () {
      test('isLoading should return true only for loading status', () {
        expect(PosItemsState.initial().isLoading, false);
        expect(PosItemsState.loading().isLoading, true);
        expect(PosItemsState.loaded([]).isLoading, false);
        expect(PosItemsState.error('err').isLoading, false);
      });

      test('hasError should return true only for error status', () {
        expect(PosItemsState.initial().hasError, false);
        expect(PosItemsState.loading().hasError, false);
        expect(PosItemsState.loaded([]).hasError, false);
        expect(PosItemsState.error('err').hasError, true);
      });

      test('isEmpty should return true for loaded state with empty list', () {
        expect(PosItemsState.initial().isEmpty, false);
        expect(PosItemsState.loading().isEmpty, false);
        expect(PosItemsState.loaded([]).isEmpty, true);
        expect(PosItemsState.loaded([_createTestItem('1', 'Test')]).isEmpty, false);
        expect(PosItemsState.error('err').isEmpty, false);
      });

      test('isLoaded should return true for loaded status', () {
        expect(PosItemsState.initial().isLoaded, false);
        expect(PosItemsState.loading().isLoaded, false);
        expect(PosItemsState.loaded([]).isLoaded, true);
        expect(PosItemsState.loaded([_createTestItem('1', 'Test')]).isLoaded, true);
        expect(PosItemsState.error('err').isLoaded, false);
      });
    });
  });

  group('PosItemsStatus enum', () {
    test('should have all required values', () {
      expect(PosItemsStatus.values.length, 4);
      expect(PosItemsStatus.values.contains(PosItemsStatus.initial), true);
      expect(PosItemsStatus.values.contains(PosItemsStatus.loading), true);
      expect(PosItemsStatus.values.contains(PosItemsStatus.loaded), true);
      expect(PosItemsStatus.values.contains(PosItemsStatus.error), true);
    });
  });

  group('State Transitions', () {
    test('initial -> loading transition', () {
      var state = PosItemsState.initial();
      expect(state.status, PosItemsStatus.initial);

      state = PosItemsState.loading();
      expect(state.status, PosItemsStatus.loading);
    });

    test('loading -> loaded transition', () {
      var state = PosItemsState.loading();
      expect(state.status, PosItemsStatus.loading);

      state = PosItemsState.loaded([_createTestItem('1', 'Test')]);
      expect(state.status, PosItemsStatus.loaded);
      expect(state.items.length, 1);
    });

    test('loading -> error transition', () {
      var state = PosItemsState.loading();
      expect(state.status, PosItemsStatus.loading);

      state = PosItemsState.error('Network error');
      expect(state.status, PosItemsStatus.error);
      expect(state.errorMessage, 'Network error');
    });
  });
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
