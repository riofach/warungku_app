import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../inventory/data/models/item_model.dart';
import '../../data/providers/low_stock_provider.dart';
import 'low_stock_item_card.dart';

/// Widget untuk menampilkan section low stock alert di dashboard
/// Menampilkan header dengan count badge dan horizontal scrollable list
class LowStockAlert extends ConsumerWidget {
  const LowStockAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan count badge
        lowStockAsync.when(
          data: (items) => _buildHeader(context, items.length),
          loading: () => _buildHeader(context, null),
          error: (_, __) => _buildHeader(context, 0),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Content area
        lowStockAsync.when(
          data: (items) => items.isEmpty
              ? _buildEmptyState(context)
              : _buildItemList(context, items),
          loading: () => _buildShimmer(),
          error: (error, _) => _buildError(context, error),
        ),
      ],
    );
  }

  /// Header dengan warning icon dan count badge
  Widget _buildHeader(BuildContext context, int? count) {
    return Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Stok Menipis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  /// Empty state ketika semua stok aman
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            '✅ Semua stok aman!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
          ),
        ),
      ),
    );
  }

  /// Horizontal scrollable list of low stock items
  Widget _buildItemList(BuildContext context, List<Item> items) {
    return SizedBox(
      height: 140, // Fixed height untuk horizontal scroll
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < items.length - 1 ? AppSpacing.sm : 0,
            ),
            child: LowStockItemCard(
              item: item,
              onTap: () => context.push('/items/edit/${item.id}', extra: item),
            ),
          );
        },
      ),
    );
  }

  /// Shimmer loading state
  Widget _buildShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: const _ShimmerItemCard(),
        ),
      ),
    );
  }

  /// Error state dengan pesan error
  Widget _buildError(BuildContext context, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Gagal memuat data stok',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer card untuk loading state
class _ShimmerItemCard extends StatelessWidget {
  const _ShimmerItemCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Name placeholder
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Stock placeholder
              Container(
                height: 12,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
