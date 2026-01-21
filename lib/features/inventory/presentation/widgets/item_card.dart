import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/item_model.dart';
import 'stock_indicator.dart';

/// Item card widget for displaying product information in a list
/// Shows thumbnail, name, price, stock indicator, and category badge
class ItemCard extends StatelessWidget {
  /// The item to display
  final Item item;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether to show the category badge
  final bool showCategory;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Image
              _buildThumbnail(context),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Sell Price
                    Text(
                      Formatters.formatRupiah(item.sellPrice),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Stock Indicator & Category Badge
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StockIndicator(item: item),
                        if (showCategory && item.categoryName != null)
                          _CategoryBadge(name: item.categoryName!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(context);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(context);
                },
              )
            : _buildPlaceholder(context),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Category badge widget
class _CategoryBadge extends StatelessWidget {
  final String name;

  const _CategoryBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Compact item card for smaller displays
class ItemCardCompact extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ItemCardCompact({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.backgroundDark,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                )
              : Container(
                  color: AppColors.backgroundDark,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        Formatters.formatRupiah(item.sellPrice),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: StockDot(item: item, size: 12),
    );
  }
}
