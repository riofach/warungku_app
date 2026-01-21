import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/theme/app_colors.dart';
import 'package:warungku_app/features/inventory/data/models/item_model.dart';
import 'package:warungku_app/features/inventory/data/providers/items_provider.dart';

void main() {
  group('Item Model', () {
    group('fromJson', () {
      test('should create Item from valid JSON with all fields', () {
        final json = {
          'id': 'item-123',
          'category_id': 'cat-456',
          'name': 'Indomie Goreng',
          'buy_price': 2500,
          'sell_price': 3500,
          'stock': 50,
          'stock_threshold': 10,
          'image_url': 'https://example.com/image.jpg',
          'is_active': true,
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final item = Item.fromJson(json);

        expect(item.id, 'item-123');
        expect(item.categoryId, 'cat-456');
        expect(item.name, 'Indomie Goreng');
        expect(item.buyPrice, 2500);
        expect(item.sellPrice, 3500);
        expect(item.stock, 50);
        expect(item.stockThreshold, 10);
        expect(item.imageUrl, 'https://example.com/image.jpg');
        expect(item.isActive, true);
        expect(item.createdAt, isA<DateTime>());
        expect(item.updatedAt, isA<DateTime>());
      });

      test('should handle nested category from join query', () {
        final json = {
          'id': 'item-123',
          'category_id': 'cat-456',
          'name': 'Aqua 600ml',
          'buy_price': 2000,
          'sell_price': 4000,
          'stock': 100,
          'stock_threshold': 20,
          'is_active': true,
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
          'categories': {'name': 'Minuman'},
        };

        final item = Item.fromJson(json);

        expect(item.categoryName, 'Minuman');
      });

      test('should handle null category_id', () {
        final json = {
          'id': 'item-123',
          'category_id': null,
          'name': 'Test Item',
          'buy_price': 1000,
          'sell_price': 2000,
          'stock': 10,
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final item = Item.fromJson(json);

        expect(item.categoryId, isNull);
        expect(item.categoryName, isNull);
      });

      test('should use default values for missing optional fields', () {
        final json = {
          'id': 'item-123',
          'name': 'Minimal Item',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final item = Item.fromJson(json);

        expect(item.buyPrice, 0);
        expect(item.sellPrice, 0);
        expect(item.stock, 0);
        expect(item.stockThreshold, 10);
        expect(item.imageUrl, isNull);
        expect(item.isActive, true);
      });

      test('should handle null timestamps with defaults', () {
        final json = {
          'id': 'item-123',
          'name': 'Test',
          'buy_price': 1000,
          'sell_price': 2000,
          'stock': 10,
          'created_at': null,
          'updated_at': null,
        };

        final item = Item.fromJson(json);

        expect(item.createdAt, isA<DateTime>());
        expect(item.updatedAt, isA<DateTime>());
      });

      test('should handle missing categories key in join', () {
        final json = {
          'id': 'item-123',
          'name': 'Test',
          'buy_price': 1000,
          'sell_price': 2000,
          'stock': 10,
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final item = Item.fromJson(json);

        expect(item.categoryName, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        final item = Item(
          id: 'item-123',
          categoryId: 'cat-456',
          name: 'Indomie Goreng',
          buyPrice: 2500,
          sellPrice: 3500,
          stock: 50,
          stockThreshold: 10,
          imageUrl: 'https://example.com/image.jpg',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = item.toJson();

        expect(json['category_id'], 'cat-456');
        expect(json['name'], 'Indomie Goreng');
        expect(json['buy_price'], 2500);
        expect(json['sell_price'], 3500);
        expect(json['stock'], 50);
        expect(json['stock_threshold'], 10);
        expect(json['image_url'], 'https://example.com/image.jpg');
        expect(json['is_active'], true);
        // Should NOT include id, created_at, updated_at
        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final item = Item(
          id: 'item-123',
          name: 'Original',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = item.copyWith(name: 'Updated');

        expect(updated.id, 'item-123');
        expect(updated.name, 'Updated');
        expect(updated.buyPrice, 1000);
      });

      test('should create copy with updated stock', () {
        final item = Item(
          id: 'item-123',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = item.copyWith(stock: 5);

        expect(updated.stock, 5);
        expect(updated.stockStatus, StockStatus.low);
      });

      test('should preserve all fields when no arguments passed', () {
        final original = Item(
          id: 'item-123',
          categoryId: 'cat-456',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 50,
          stockThreshold: 10,
          imageUrl: 'https://example.com',
          isActive: true,
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
          categoryName: 'Category',
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.categoryId, original.categoryId);
        expect(copy.name, original.name);
        expect(copy.buyPrice, original.buyPrice);
        expect(copy.sellPrice, original.sellPrice);
        expect(copy.stock, original.stock);
        expect(copy.stockThreshold, original.stockThreshold);
        expect(copy.imageUrl, original.imageUrl);
        expect(copy.isActive, original.isActive);
        expect(copy.categoryName, original.categoryName);
      });

      test('should allow setting categoryId to null', () {
        final item = Item(
          id: 'item-123',
          categoryId: 'cat-456',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = item.copyWith(categoryId: null);

        expect(updated.categoryId, isNull);
        expect(updated.name, 'Test'); // Other fields preserved
      });

      test('should allow setting imageUrl to null', () {
        final item = Item(
          id: 'item-123',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          imageUrl: 'https://example.com/image.jpg',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = item.copyWith(imageUrl: null);

        expect(updated.imageUrl, isNull);
      });

      test('should allow setting categoryName to null', () {
        final item = Item(
          id: 'item-123',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          categoryName: 'Makanan',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = item.copyWith(categoryName: null);

        expect(updated.categoryName, isNull);
      });
    });

    group('Equality', () {
      test('two items with same id should be equal', () {
        final item1 = Item(
          id: 'item-123',
          name: 'Item 1',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final item2 = Item(
          id: 'item-123',
          name: 'Different Name',
          buyPrice: 5000,
          sellPrice: 10000,
          stock: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('two items with different id should not be equal', () {
        final item1 = Item(
          id: 'item-123',
          name: 'Same Name',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final item2 = Item(
          id: 'item-456',
          name: 'Same Name',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item1, isNot(equals(item2)));
      });
    });

    group('toString', () {
      test('should return formatted string with key info', () {
        final item = Item(
          id: 'item-123',
          name: 'Test Item',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = item.toString();

        expect(result, contains('item-123'));
        expect(result, contains('Test Item'));
        expect(result, contains('50'));
      });
    });
  });

  group('StockStatus', () {
    group('stockStatus computation', () {
      test('should return outOfStock when stock is 0', () {
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

        expect(item.stockStatus, StockStatus.outOfStock);
      });

      test('should return low when stock equals threshold', () {
        final item = Item(
          id: 'item-1',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          stockThreshold: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item.stockStatus, StockStatus.low);
      });

      test('should return low when stock is below threshold', () {
        final item = Item(
          id: 'item-1',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 5,
          stockThreshold: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item.stockStatus, StockStatus.low);
      });

      test('should return normal when stock is above threshold', () {
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

        expect(item.stockStatus, StockStatus.normal);
      });

      test('should handle edge case where stock is 1 above threshold', () {
        final item = Item(
          id: 'item-1',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 11,
          stockThreshold: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item.stockStatus, StockStatus.normal);
      });
    });

    group('StockStatusExtension', () {
      test('normal status should have green color', () {
        expect(StockStatus.normal.color, AppColors.stockSafe);
      });

      test('low status should have yellow/warning color', () {
        expect(StockStatus.low.color, AppColors.stockWarning);
      });

      test('outOfStock status should have red/critical color', () {
        expect(StockStatus.outOfStock.color, AppColors.stockCritical);
      });

      test('normal status should have Tersedia label', () {
        expect(StockStatus.normal.label, 'Tersedia');
      });

      test('low status should have Stok Menipis label', () {
        expect(StockStatus.low.label, 'Stok Menipis');
      });

      test('outOfStock status should have Habis label', () {
        expect(StockStatus.outOfStock.label, 'Habis');
      });

      test('normal status should have check_circle icon', () {
        expect(StockStatus.normal.icon, Icons.check_circle);
      });

      test('low status should have warning icon', () {
        expect(StockStatus.low.icon, Icons.warning);
      });

      test('outOfStock status should have error icon', () {
        expect(StockStatus.outOfStock.icon, Icons.error);
      });
    });
  });

  group('ItemListState', () {
    test('initial state should have initial status and empty list', () {
      final state = ItemListState.initial();

      expect(state.status, ItemListStatus.initial);
      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isEmpty, false);
      expect(state.hasData, false);
    });

    test('loading state should have loading status', () {
      final state = ItemListState.loading();

      expect(state.status, ItemListStatus.loading);
      expect(state.isLoading, true);
      expect(state.hasError, false);
    });

    test('loaded state should have list of items', () {
      final items = [
        Item(
          id: 'item-1',
          name: 'Test',
          buyPrice: 1000,
          sellPrice: 2000,
          stock: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final state = ItemListState.loaded(items);

      expect(state.status, ItemListStatus.loaded);
      expect(state.items, items);
      expect(state.isEmpty, false);
      expect(state.hasData, true);
    });

    test('loaded state with empty list should be isEmpty', () {
      final state = ItemListState.loaded([]);

      expect(state.status, ItemListStatus.loaded);
      expect(state.isEmpty, true);
      expect(state.hasData, false);
    });

    test('error state should have error message', () {
      final state = ItemListState.error('Test error');

      expect(state.status, ItemListStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Test error');
    });
  });
}
