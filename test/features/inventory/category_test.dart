import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/category_model.dart';
import 'package:warungku_app/features/inventory/data/providers/categories_provider.dart';

void main() {
  group('Category Model', () {
    group('fromJson', () {
      test('should create Category from valid JSON', () {
        final json = {
          'id': 'cat-123',
          'name': 'Sembako',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final category = Category.fromJson(json);

        expect(category.id, 'cat-123');
        expect(category.name, 'Sembako');
        expect(category.createdAt, isA<DateTime>());
        expect(category.updatedAt, isA<DateTime>());
        expect(category.itemCount, 0);
      });

      test('should parse category with item count from nested items array', () {
        final json = {
          'id': 'cat-123',
          'name': 'Minuman',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
          'items': [
            {'count': 15}
          ],
        };

        final category = Category.fromJson(json);

        expect(category.id, 'cat-123');
        expect(category.name, 'Minuman');
        expect(category.itemCount, 15);
      });

      test('should handle empty items array', () {
        final json = {
          'id': 'cat-123',
          'name': 'Kosong',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
          'items': [],
        };

        final category = Category.fromJson(json);

        expect(category.itemCount, 0);
      });

      test('should handle null items', () {
        final json = {
          'id': 'cat-123',
          'name': 'Test',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
          'items': null,
        };

        final category = Category.fromJson(json);

        expect(category.itemCount, 0);
      });

      test('should handle null timestamps with defaults', () {
        final json = {
          'id': 'cat-123',
          'name': 'Test',
          'created_at': null,
          'updated_at': null,
        };

        final category = Category.fromJson(json);

        expect(category.createdAt, isA<DateTime>());
        expect(category.updatedAt, isA<DateTime>());
      });

      test('should handle missing items key', () {
        final json = {
          'id': 'cat-123',
          'name': 'Test',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final category = Category.fromJson(json);

        expect(category.itemCount, 0);
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly with only name field', () {
        final category = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          itemCount: 10,
        );

        final json = category.toJson();

        expect(json['name'], 'Sembako');
        expect(json.keys.length, 1); // Only name should be in toJson
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final category = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
          itemCount: 10,
        );

        final updated = category.copyWith(name: 'Minuman');

        expect(updated.id, 'cat-123');
        expect(updated.name, 'Minuman');
        expect(updated.itemCount, 10);
      });

      test('should create copy with updated itemCount', () {
        final category = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
          itemCount: 10,
        );

        final updated = category.copyWith(itemCount: 20);

        expect(updated.itemCount, 20);
      });

      test('should preserve all fields when no arguments passed', () {
        final original = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
          itemCount: 10,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);
        expect(copy.itemCount, original.itemCount);
      });
    });

    group('Equality', () {
      test('two categories with same id should be equal', () {
        final cat1 = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cat2 = Category(
          id: 'cat-123',
          name: 'Different Name',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          itemCount: 10,
        );

        expect(cat1, equals(cat2));
        expect(cat1.hashCode, equals(cat2.hashCode));
      });

      test('two categories with different id should not be equal', () {
        final cat1 = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cat2 = Category(
          id: 'cat-456',
          name: 'Sembako',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(cat1, isNot(equals(cat2)));
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final category = Category(
          id: 'cat-123',
          name: 'Sembako',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          itemCount: 5,
        );

        final result = category.toString();

        expect(result, contains('cat-123'));
        expect(result, contains('Sembako'));
        expect(result, contains('5'));
      });
    });
  });

  group('CategoryListState', () {
    test('initial state should have initial status and empty list', () {
      final state = CategoryListState.initial();

      expect(state.status, CategoryListStatus.initial);
      expect(state.categories, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isEmpty, false);
    });

    test('loading state should have loading status', () {
      final state = CategoryListState.loading();

      expect(state.status, CategoryListStatus.loading);
      expect(state.isLoading, true);
      expect(state.hasError, false);
    });

    test('loaded state should have list of categories', () {
      final categories = [
        Category(
          id: 'cat-1',
          name: 'Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final state = CategoryListState.loaded(categories);

      expect(state.status, CategoryListStatus.loaded);
      expect(state.categories, categories);
      expect(state.isEmpty, false);
    });

    test('loaded state with empty list should be isEmpty', () {
      final state = CategoryListState.loaded([]);

      expect(state.status, CategoryListStatus.loaded);
      expect(state.isEmpty, true);
    });

    test('error state should have error message', () {
      final state = CategoryListState.error('Test error');

      expect(state.status, CategoryListStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Test error');
    });
  });

  group('CategoryActionState', () {
    test('initial state should have initial status', () {
      final state = CategoryActionState.initial();

      expect(state.status, CategoryActionStatus.initial);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isSuccess, false);
    });

    test('loading state should have loading status', () {
      final state = CategoryActionState.loading();

      expect(state.status, CategoryActionStatus.loading);
      expect(state.isLoading, true);
    });

    test('success state should have success message', () {
      final state = CategoryActionState.success('Category created');

      expect(state.status, CategoryActionStatus.success);
      expect(state.isSuccess, true);
      expect(state.successMessage, 'Category created');
    });

    test('error state should have error message', () {
      final state = CategoryActionState.error('Failed to create');

      expect(state.status, CategoryActionStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Failed to create');
    });
  });
}
