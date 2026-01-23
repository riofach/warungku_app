import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app_error;
import '../../../../core/widgets/loading_widget.dart';
import '../../../inventory/data/models/category_model.dart';
import '../../../inventory/data/providers/categories_provider.dart';
import '../../data/providers/pos_items_provider.dart';
import '../../data/providers/pos_search_provider.dart';
import '../../data/providers/pos_category_filter_provider.dart';
import '../../data/providers/filtered_pos_items_provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/cart_error_provider.dart';
import '../widgets/pos_product_card.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/cart_bottom_sheet.dart';

/// POS (Point of Sale) screen - kasir interface
/// Displays product grid with search, category filter, and cart summary
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load categories on init (items loaded by AsyncValue automatically)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListNotifierProvider.notifier).loadCategories();
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
      ref.read(posSearchQueryProvider.notifier).state = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(posSearchQueryProvider.notifier).state = '';
  }

  void _onCategorySelected(String? categoryId) {
    ref.read(posCategoryFilterProvider.notifier).state = categoryId;
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => CartBottomSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(posItemsNotifierProvider);
    final filteredItems = ref.watch(filteredPosItemsProvider);
    final categoriesState = ref.watch(categoryListNotifierProvider);
    final searchQuery = ref.watch(posSearchQueryProvider);
    final selectedCategory = ref.watch(posCategoryFilterProvider);
    final cartIsEmpty = ref.watch(cartIsEmptyProvider);

    // Listen for cart errors and show SnackBar
    ref.listen<String?>(cartErrorProvider, (previous, next) {
      if (next != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(cartErrorProvider.notifier).setError(null);
              },
            ),
          ),
        );
        // Clear error immediately after showing
        ref.read(cartErrorProvider.notifier).setError(null);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(searchQuery),

          // Category chips
          _buildCategoryChips(categoriesState.categories, selectedCategory),

          // Product grid
          Expanded(
            child: _buildProductGrid(itemsAsync, filteredItems),
          ),
        ],
      ),
      // Cart summary bar
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: cartIsEmpty ? 0 : 70,
        child: cartIsEmpty 
            ? null 
            : CartSummaryBar(
                onTap: () => _showCartBottomSheet(context),
              ),
      ),
    );
  }

  Widget _buildSearchBar(String searchQuery) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari barang...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories, String? selectedCategory) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: 52,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1, // +1 for "Semua"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Semua" chip
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: const Text('Semua'),
                selected: selectedCategory == null,
                onSelected: (_) => _onCategorySelected(null),
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                checkmarkColor: AppColors.primary,
              ),
            );
          }
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(category.name),
              selected: selectedCategory == category.id,
              onSelected: (_) => _onCategorySelected(category.id),
              selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
              checkmarkColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(AsyncValue<List<dynamic>> itemsAsync, List filteredItems) {
    return itemsAsync.when(
      loading: () => const LoadingWidget(message: 'Memuat barang...'),
      error: (error, stack) => app_error.AppErrorWidget(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.refresh(posItemsNotifierProvider),
      ),
      data: (items) {
        // Empty state (no items at all)
        if (items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'Belum ada barang',
            subtitle: 'Tambahkan barang terlebih dahulu di menu Stok',
          );
        }

        // Empty search results
        if (filteredItems.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'Tidak ditemukan',
            subtitle: 'Coba kata kunci atau kategori lain',
          );
        }

        // Product grid
        return RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(posItemsNotifierProvider.future);
            await ref.read(categoryListNotifierProvider.notifier).refresh();
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.70, // Adjust based on card design
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return PosProductCard(
                item: item,
                onAddToCart: () {
                    // Feedback handled by listener above, but we can add success feedback here if needed
                },
              );
            },
          ),
        );
      },
    );
  }
}
