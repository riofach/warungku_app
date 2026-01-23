import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../data/models/item_model.dart';
import '../../data/providers/items_provider.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/item_card.dart';

/// Items management screen
/// Displays list of items with search, filter, and stock indicators
class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load items on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListNotifierProvider.notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(itemListNotifierProvider.notifier).searchItems(value);
    });
  }

  void _onCategoryChanged(String? categoryId) {
    ref.read(itemListNotifierProvider.notifier).filterByCategory(categoryId);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(itemListNotifierProvider.notifier).refresh();
  }

  Future<void> _onRefresh() async {
    await ref.read(itemListNotifierProvider.notifier).refresh();
  }

  void _navigateToAddItem() {
    context.push(AppRoutes.itemAdd);
  }

  /// Navigate to edit item screen (Story 3.5 - AC1)
  /// Uses context.push with item data via extra parameter
  void _navigateToEditItem(Item item) {
    debugPrint('[ITEMS] _navigateToEditItem called. item.id=${item.id}, item.imageUrl=${item.imageUrl}');
    context.push('${AppRoutes.itemEdit}/${item.id}', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final itemState = ref.watch(itemListNotifierProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Barang'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),

          // Category filter chips
          CategoryFilterChips(
            onCategoryChanged: _onCategoryChanged,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Items list
          Expanded(
            child: _buildContent(itemState, searchQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(ItemListState state, String searchQuery) {
    // Loading state
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.hasError) {
      return app.AppErrorWidget(
        message: state.errorMessage ?? 'Gagal memuat data',
        onRetry: () {
          ref.read(itemListNotifierProvider.notifier).refresh();
        },
      );
    }

    // Empty state - check if filtering/searching
    if (state.isEmpty) {
      if (searchQuery.isNotEmpty) {
        // No search results
        return _buildEmptySearchResults(searchQuery);
      }

      // No items at all
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada barang',
        subtitle: 'Tap + untuk menambahkan barang pertama',
        actionLabel: 'Tambah Barang',
        onAction: _navigateToAddItem,
      );
    }

    // Items list
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return ItemCard(
            item: item,
            // Story 3.5 - AC1: Navigate to edit screen on tap
            onTap: () => _navigateToEditItem(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptySearchResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ditemukan barang untuk',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"$query"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Hapus Pencarian'),
            ),
          ],
        ),
      ),
    );
  }
}
