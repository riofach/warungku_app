import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider moved to legacy.dart in Riverpod 3.x - acceptable for simple state
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';

import '../models/item_model.dart';
import '../repositories/item_repository.dart';

/// Provider for ItemRepository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

/// Search query state provider
/// Stores the current search text for item filtering
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category filter state provider
/// Stores the currently selected category ID for filtering
/// null means "All categories" (Semua)
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// State for item list
enum ItemListStatus {
  initial,
  loading,
  loaded,
  error,
}

class ItemListState {
  final ItemListStatus status;
  final List<Item> items;
  final String? errorMessage;

  const ItemListState({
    required this.status,
    required this.items,
    this.errorMessage,
  });

  factory ItemListState.initial() => const ItemListState(
        status: ItemListStatus.initial,
        items: [],
      );

  factory ItemListState.loading() => const ItemListState(
        status: ItemListStatus.loading,
        items: [],
      );

  factory ItemListState.loaded(List<Item> items) => ItemListState(
        status: ItemListStatus.loaded,
        items: items,
      );

  factory ItemListState.error(String message) => ItemListState(
        status: ItemListStatus.error,
        items: [],
        errorMessage: message,
      );

  bool get isLoading => status == ItemListStatus.loading;
  bool get hasError => status == ItemListStatus.error;
  bool get isEmpty => status == ItemListStatus.loaded && items.isEmpty;
  bool get hasData => status == ItemListStatus.loaded && items.isNotEmpty;
}

/// Notifier for item list with search and filter support
class ItemListNotifier extends Notifier<ItemListState> {
  /// Track the current operation to prevent race conditions
  int _operationId = 0;

  @override
  ItemListState build() {
    return ItemListState.initial();
  }

  /// Load all items with optional search and category filter
  /// Uses operation ID to prevent race conditions from rapid calls
  Future<void> loadItems({
    String? searchQuery,
    String? categoryId,
  }) async {
    // Increment operation ID to track this specific call
    final currentOperationId = ++_operationId;

    state = ItemListState.loading();

    try {
      final repository = ref.read(itemRepositoryProvider);
      final items = await repository.getItems(
        searchQuery: searchQuery,
        categoryId: categoryId,
      );

      // Only update state if this is still the latest operation
      if (currentOperationId == _operationId) {
        state = ItemListState.loaded(items);
      }
    } catch (e) {
      // Only update state if this is still the latest operation
      if (currentOperationId == _operationId) {
        state = ItemListState.error(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  /// Refresh item list with current filters
  Future<void> refresh() async {
    final searchQuery = ref.read(searchQueryProvider);
    final categoryId = ref.read(selectedCategoryFilterProvider);
    await loadItems(
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      categoryId: categoryId,
    );
  }

  /// Search items by name
  Future<void> searchItems(String query) async {
    ref.read(searchQueryProvider.notifier).state = query;
    final categoryId = ref.read(selectedCategoryFilterProvider);
    await loadItems(
      searchQuery: query.isNotEmpty ? query : null,
      categoryId: categoryId,
    );
  }

  /// Filter items by category
  Future<void> filterByCategory(String? categoryId) async {
    ref.read(selectedCategoryFilterProvider.notifier).state = categoryId;
    final searchQuery = ref.read(searchQueryProvider);
    await loadItems(
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      categoryId: categoryId,
    );
  }

  /// Apply combined search and filter
  Future<void> applyFilters({
    String? searchQuery,
    String? categoryId,
  }) async {
    if (searchQuery != null) {
      ref.read(searchQueryProvider.notifier).state = searchQuery;
    }
    if (categoryId != null) {
      ref.read(selectedCategoryFilterProvider.notifier).state = categoryId;
    }
    await loadItems(
      searchQuery: searchQuery ?? ref.read(searchQueryProvider),
      categoryId: categoryId ?? ref.read(selectedCategoryFilterProvider),
    );
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryFilterProvider.notifier).state = null;
    await loadItems();
  }
}

/// Provider for ItemListNotifier
final itemListNotifierProvider =
    NotifierProvider<ItemListNotifier, ItemListState>(() {
  return ItemListNotifier();
});

/// FutureProvider for items with automatic dependency on search and category
/// This provider auto-refreshes when search query or category filter changes
final filteredItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);

  return repository.getItems(
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
    categoryId: categoryId,
  );
});

/// Provider for low stock items (for alerts/dashboard)
final lowStockItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getLowStockItems();
});

/// Provider for out of stock items
final outOfStockItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getOutOfStockItems();
});
