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
/// Tracks loading, success, and error states during item creation
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
/// Handles item creation with optional image upload
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
      String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('duplicate') || errorStr.contains('unique')) {
        errorMessage = 'Barang dengan nama ini sudah ada';
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('socket')) {
        errorMessage = 'Gagal menyimpan. Periksa koneksi internet.';
      } else if (errorStr.contains('storage') ||
          errorStr.contains('upload') ||
          errorStr.contains('bucket')) {
        errorMessage = 'Gagal mengupload foto. Silakan coba lagi.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      }

      // Set error state
      state = state.copyWith(
        status: ItemFormStatus.error,
        errorMessage: errorMessage,
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
