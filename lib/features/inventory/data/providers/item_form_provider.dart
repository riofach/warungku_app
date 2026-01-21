import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'items_provider.dart';

/// Form status enum for item form operations
enum ItemFormStatus {
  initial,
  loading,
  success,
  error,
}

/// State class for item form
/// Tracks loading, success, and error states during item creation/update
class ItemFormState {
  final ItemFormStatus status;
  final String? errorMessage;
  final String? createdItemId;

  const ItemFormState({
    this.status = ItemFormStatus.initial,
    this.errorMessage,
    this.createdItemId,
  });

  /// Create copy with updated fields
  ItemFormState copyWith({
    ItemFormStatus? status,
    String? errorMessage,
    String? createdItemId,
  }) {
    return ItemFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      createdItemId: createdItemId,
    );
  }

  // Convenience getters
  bool get isLoading => status == ItemFormStatus.loading;
  bool get isSuccess => status == ItemFormStatus.success;
  bool get hasError => status == ItemFormStatus.error;
  bool get isInitial => status == ItemFormStatus.initial;
}

/// Notifier for item form operations (Riverpod 3.x pattern)
/// Handles item creation and update with optional image upload
/// Story 3.5: Added updateItem method for edit mode (AC5, AC8)
class ItemFormNotifier extends Notifier<ItemFormState> {
  @override
  ItemFormState build() {
    return const ItemFormState();
  }

  /// Save a new item with optional image
  /// Uploads image first if provided, then creates item record
  Future<bool> saveItem({
    required String name,
    String? categoryId,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    required int stockThreshold,
    required bool isActive,
    File? imageFile,
  }) async {
    // Set loading state
    state = state.copyWith(status: ItemFormStatus.loading);

    try {
      final repository = ref.read(itemRepositoryProvider);
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await repository.uploadImage(imageFile);
      }

      // Create item record
      final itemId = await repository.createItem(
        name: name,
        categoryId: categoryId,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
        stockThreshold: stockThreshold,
        isActive: isActive,
        imageUrl: imageUrl,
      );

      // Set success state
      state = state.copyWith(
        status: ItemFormStatus.success,
        createdItemId: itemId,
      );

      // Refresh items list - invalidate and reload
      ref.invalidate(itemListNotifierProvider);
      // Trigger reload after invalidation
      await ref.read(itemListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      // Determine error message based on error type
      String errorMessage = _mapErrorMessage(e.toString(), operation: 'save');

      // Set error state
      state = state.copyWith(
        status: ItemFormStatus.error,
        errorMessage: errorMessage,
      );

      return false;
    }
  }

  /// Update an existing item with optional new image (Story 3.5 - AC5, AC8)
  /// Uploads new image if provided, handles image removal
  ///
  /// [itemId] - ID of item to update
  /// [imageFile] - New image file to upload (optional)
  /// [imageRemoved] - Flag indicating user removed the existing image (AC7)
  Future<bool> updateItem({
    required String itemId,
    required String name,
    String? categoryId,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    required int stockThreshold,
    required bool isActive,
    File? imageFile,
    bool imageRemoved = false,
  }) async {
    // Set loading state
    state = state.copyWith(status: ItemFormStatus.loading);

    try {
      final repository = ref.read(itemRepositoryProvider);

      // Update item record (repository handles image upload/removal)
      final updatedItem = await repository.updateItem(
        id: itemId,
        name: name,
        categoryId: categoryId,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
        stockThreshold: stockThreshold,
        isActive: isActive,
        imageFile: imageFile,
        imageRemoved: imageRemoved,
      );

      // Set success state
      state = state.copyWith(
        status: ItemFormStatus.success,
        createdItemId: updatedItem.id,
      );

      // Refresh items list - invalidate and reload (AC5)
      ref.invalidate(itemListNotifierProvider);
      // Trigger reload after invalidation
      await ref.read(itemListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      // Determine error message based on error type (AC8)
      String errorMessage = _mapErrorMessage(e.toString(), operation: 'save');

      // Set error state
      state = state.copyWith(
        status: ItemFormStatus.error,
        errorMessage: errorMessage,
      );

      return false;
    }
  }

  /// Get appropriate error message based on error string
  /// 
  /// [errorStr] - The error string to analyze
  /// [operation] - The operation type for context-specific messages:
  ///   - 'save': Item creation/update operations
  ///   - 'delete': Item deletion operations
  ///   - 'stock': Stock update operations
  String _mapErrorMessage(String errorStr, {String operation = 'save'}) {
    final lowerError = errorStr.toLowerCase();
    
    // Not found errors
    if (lowerError.contains('not found') || 
        lowerError.contains('pgrst116') ||
        lowerError.contains('0 rows')) {
      return 'Barang tidak ditemukan';
    }
    
    // Network errors - operation-specific messages
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket')) {
      switch (operation) {
        case 'delete':
          return 'Gagal menghapus. Periksa koneksi internet.';
        case 'stock':
          return 'Gagal memperbarui stok. Periksa koneksi internet.';
        default:
          return 'Gagal menyimpan. Periksa koneksi internet.';
      }
    }
    
    // Duplicate name errors (only for save operations)
    if (operation == 'save' && 
        (lowerError.contains('duplicate') || lowerError.contains('unique'))) {
      return 'Barang dengan nama ini sudah ada';
    }
    
    // Storage/upload errors (only for save operations)
    if (operation == 'save' &&
        (lowerError.contains('storage') ||
         lowerError.contains('upload') ||
         lowerError.contains('bucket'))) {
      return 'Gagal mengupload foto. Silakan coba lagi.';
    }
    
    // Timeout errors
    if (lowerError.contains('timeout')) {
      return operation == 'save' 
          ? 'Koneksi timeout. Silakan coba lagi.'
          : 'Terjadi kesalahan. Silakan coba lagi.';
    }
    
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Deletes an item (soft delete - sets is_active = false) (Story 3.6 - AC3)
  /// 
  /// Returns true if deletion was successful.
  /// Updates state to loading during operation and success/error on completion.
  /// Invalidates items list provider on success.
  /// 
  /// [itemId] - ID of item to delete
  Future<bool> deleteItem(String itemId) async {
    state = state.copyWith(status: ItemFormStatus.loading);
    
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.deleteItem(itemId);
      
      state = state.copyWith(status: ItemFormStatus.success);
      
      // Refresh items list to remove deleted item
      ref.invalidate(itemListNotifierProvider);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ItemFormStatus.error,
        errorMessage: _mapErrorMessage(e.toString(), operation: 'delete'),
      );
      return false;
    }
  }

  /// Updates item stock to a new value (Stock Opname) (Story 3.7 - AC5, AC6)
  ///
  /// Returns true if update was successful.
  /// NOTE: Does NOT set state to success to avoid triggering ref.listen in ItemFormScreen
  /// which would cause double snackbar and unwanted navigation.
  /// Invalidates items list provider on success.
  ///
  /// [itemId] - ID of item to update
  /// [newStock] - New stock count value
  Future<bool> updateStock(String itemId, int newStock) async {
    state = state.copyWith(status: ItemFormStatus.loading);

    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.updateStock(itemId, newStock);

      // Reset to initial instead of success to avoid triggering ref.listen snackbar/pop
      state = const ItemFormState();

      // Refresh items list to show updated stock
      ref.invalidate(itemListNotifierProvider);
      // Force immediate refresh to ensure list shows updated stock when user navigates back
      await ref.read(itemListNotifierProvider.notifier).refresh();

      return true;
    } catch (e) {
      state = state.copyWith(
        status: ItemFormStatus.error,
        errorMessage: _mapErrorMessage(e.toString(), operation: 'stock'),
      );
      return false;
    }
  }

  /// Reset form state to initial
  void reset() {
    state = const ItemFormState();
  }
}

/// Provider for ItemFormNotifier
/// Uses autoDispose to clean up when widget is unmounted
final itemFormNotifierProvider =
    NotifierProvider.autoDispose<ItemFormNotifier, ItemFormState>(
  ItemFormNotifier.new,
);
