import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../inventory/data/models/item_model.dart';

/// Widget card untuk menampilkan individual low stock item
/// Menampilkan thumbnail, nama item, dan stock count dengan color coding
class LowStockItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const LowStockItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: item.stockStatus == StockStatus.outOfStock
                ? AppColors.error.withOpacity(0.5)
                : AppColors.warning.withOpacity(0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          height: 60,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Item name (truncated)
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),

                // Stock count with color coding
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.stockStatus.icon,
                      size: 12,
                      color: item.stockStatus.color,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'Stok: ${item.stock}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: item.stockStatus.color,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Placeholder image ketika tidak ada thumbnail
  Widget _buildPlaceholder() {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }
}
