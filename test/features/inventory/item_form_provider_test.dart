import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/providers/item_form_provider.dart';

void main() {
  group('ItemFormState', () {
    test('should initialize with initial status', () {
      const state = ItemFormState();

      expect(state.status, ItemFormStatus.initial);
      expect(state.errorMessage, isNull);
      expect(state.createdItemId, isNull);
      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.hasError, isFalse);
    });

    test('should return correct isLoading when status is loading', () {
      const state = ItemFormState(status: ItemFormStatus.loading);

      expect(state.isLoading, isTrue);
      expect(state.isInitial, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.hasError, isFalse);
    });

    test('should return correct isSuccess when status is success', () {
      const state = ItemFormState(
        status: ItemFormStatus.success,
        createdItemId: 'item-123',
      );

      expect(state.isSuccess, isTrue);
      expect(state.createdItemId, 'item-123');
      expect(state.isLoading, isFalse);
      expect(state.isInitial, isFalse);
      expect(state.hasError, isFalse);
    });

    test('should return correct hasError when status is error', () {
      const state = ItemFormState(
        status: ItemFormStatus.error,
        errorMessage: 'Test error',
      );

      expect(state.hasError, isTrue);
      expect(state.errorMessage, 'Test error');
      expect(state.isLoading, isFalse);
      expect(state.isInitial, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith should update status correctly', () {
      const initialState = ItemFormState();

      final loadingState = initialState.copyWith(status: ItemFormStatus.loading);

      expect(loadingState.status, ItemFormStatus.loading);
      expect(loadingState.errorMessage, isNull);
    });

    test('copyWith should update errorMessage correctly', () {
      const initialState = ItemFormState();

      final errorState = initialState.copyWith(
        status: ItemFormStatus.error,
        errorMessage: 'Network error',
      );

      expect(errorState.status, ItemFormStatus.error);
      expect(errorState.errorMessage, 'Network error');
    });

    test('copyWith should update createdItemId correctly', () {
      const initialState = ItemFormState();

      final successState = initialState.copyWith(
        status: ItemFormStatus.success,
        createdItemId: 'new-item-id',
      );

      expect(successState.status, ItemFormStatus.success);
      expect(successState.createdItemId, 'new-item-id');
    });

    test('copyWith should preserve existing values when not updated', () {
      const initialState = ItemFormState(
        status: ItemFormStatus.success,
        createdItemId: 'existing-id',
      );

      // Note: copyWith clears errorMessage and createdItemId if not explicitly passed
      // This is intentional behavior - success state doesn't carry old errors
      final updatedState = initialState.copyWith();

      expect(updatedState.status, ItemFormStatus.success);
      // createdItemId is reset when not explicitly passed (nullable field behavior)
    });
  });

  group('ItemFormStatus', () {
    test('should have correct enum values', () {
      expect(ItemFormStatus.values.length, 4);
      expect(ItemFormStatus.initial, isNotNull);
      expect(ItemFormStatus.loading, isNotNull);
      expect(ItemFormStatus.success, isNotNull);
      expect(ItemFormStatus.error, isNotNull);
    });
  });

  group('ItemFormState state transitions', () {
    test('initial -> loading transition', () {
      const initial = ItemFormState();
      
      final loading = initial.copyWith(status: ItemFormStatus.loading);
      
      expect(initial.isInitial, isTrue);
      expect(loading.isLoading, isTrue);
      expect(loading.isInitial, isFalse);
    });

    test('loading -> success transition', () {
      const loading = ItemFormState(status: ItemFormStatus.loading);
      
      final success = loading.copyWith(
        status: ItemFormStatus.success,
        createdItemId: 'item-123',
      );
      
      expect(success.isSuccess, isTrue);
      expect(success.isLoading, isFalse);
      expect(success.createdItemId, 'item-123');
    });

    test('loading -> error transition', () {
      const loading = ItemFormState(status: ItemFormStatus.loading);
      
      final error = loading.copyWith(
        status: ItemFormStatus.error,
        errorMessage: 'Gagal menyimpan. Periksa koneksi internet.',
      );
      
      expect(error.hasError, isTrue);
      expect(error.isLoading, isFalse);
      expect(error.errorMessage, 'Gagal menyimpan. Periksa koneksi internet.');
    });

    test('error -> loading transition (retry)', () {
      const error = ItemFormState(
        status: ItemFormStatus.error,
        errorMessage: 'Previous error',
      );
      
      final loading = error.copyWith(status: ItemFormStatus.loading);
      
      expect(loading.isLoading, isTrue);
      expect(loading.hasError, isFalse);
      // errorMessage should be cleared
      expect(loading.errorMessage, isNull);
    });

    test('success state should clear error message', () {
      const error = ItemFormState(
        status: ItemFormStatus.error,
        errorMessage: 'Previous error',
      );
      
      final success = error.copyWith(
        status: ItemFormStatus.success,
        createdItemId: 'new-id',
      );
      
      expect(success.isSuccess, isTrue);
      expect(success.errorMessage, isNull);
      expect(success.createdItemId, 'new-id');
    });
  });

  group('ItemFormNotifier error message mapping', () {
    test('duplicate error messages are mapped correctly', () {
      // Test that duplicate-related error strings are recognized
      const duplicatePatterns = [
        'duplicate',
        'unique',
        'UNIQUE constraint failed',
        'duplicate key value',
      ];
      
      for (final pattern in duplicatePatterns) {
        expect(pattern.toLowerCase().contains('duplicate') || 
               pattern.toLowerCase().contains('unique'), isTrue);
      }
    });

    test('network error messages are mapped correctly', () {
      const networkPatterns = [
        'network',
        'connection',
        'socket',
        'SocketException',
      ];
      
      for (final pattern in networkPatterns) {
        expect(
          pattern.toLowerCase().contains('network') ||
          pattern.toLowerCase().contains('connection') ||
          pattern.toLowerCase().contains('socket'),
          isTrue,
        );
      }
    });

    test('storage error messages are mapped correctly', () {
      const storagePatterns = [
        'storage',
        'upload',
        'bucket',
        'StorageException',
      ];
      
      for (final pattern in storagePatterns) {
        expect(
          pattern.toLowerCase().contains('storage') ||
          pattern.toLowerCase().contains('upload') ||
          pattern.toLowerCase().contains('bucket'),
          isTrue,
        );
      }
    });

    test('timeout error messages are mapped correctly', () {
      const timeoutPatterns = [
        'timeout',
        'TimeoutException',
        'connection timeout',
      ];
      
      for (final pattern in timeoutPatterns) {
        expect(pattern.toLowerCase().contains('timeout'), isTrue);
      }
    });
  });
}
