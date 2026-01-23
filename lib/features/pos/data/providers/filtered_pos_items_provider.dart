import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/data/models/item_model.dart';
import 'pos_items_provider.dart';
import 'pos_search_provider.dart';
import 'pos_category_filter_provider.dart';

/// Provider for filtered POS items
/// Combines search query and category filter to filter the items list
/// This is a computed provider that watches the source providers
final filteredPosItemsProvider = Provider<List<Item>>((ref) {
  final itemsAsyncValue = ref.watch(posItemsNotifierProvider);
  final searchQuery = ref.watch(posSearchQueryProvider);
  final categoryId = ref.watch(posCategoryFilterProvider);

  // Return empty list if not loaded
  return itemsAsyncValue.when(
    data: (items) {
      // Start with all items
      var filteredItems = items;

      // Apply category filter
      if (categoryId != null) {
        filteredItems = filteredItems
            .where((item) => item.categoryId == categoryId)
            .toList();
      }

      // Apply search filter (case-insensitive)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filteredItems = filteredItems
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }

      return filteredItems;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider to check if any filter is active
final posHasActiveFilterProvider = Provider<bool>((ref) {
  final searchQuery = ref.watch(posSearchQueryProvider);
  final categoryId = ref.watch(posCategoryFilterProvider);
  return searchQuery.isNotEmpty || categoryId != null;
});

/// Provider for the count of filtered items
final filteredPosItemsCountProvider = Provider<int>((ref) {
  return ref.watch(filteredPosItemsProvider).length;
});
