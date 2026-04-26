import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../inventory/data/models/item_model.dart';
import '../../../inventory/presentation/widgets/unit_picker_bottom_sheet.dart';
import '../../data/providers/cart_provider.dart';

class PosProductCard extends ConsumerWidget {
  final Item item;
  final VoidCallback? onAddToCart;

  const PosProductCard({super.key, required this.item, this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);

    // For has_units: item is "out of stock" when all active units have 0 available
    final bool isOutOfStock = item.hasUnits
        ? item.activeUnits.every((u) => u.availableFrom(item.stock) == 0)
        : item.stock == 0;

    // For has_units: sum quantity of all cart entries for this item
    final int quantityInCart = item.hasUnits
        ? cartState.items
              .where((ci) => ci.item.id == item.id)
              .fold(0, (sum, ci) => sum + ci.quantity)
        : cartState.getQuantityByKey(item.id);

    final bool canAddMore = item.hasUnits
        ? !isOutOfStock
        : ref.read(cartNotifierProvider.notifier).canAddMore(item.id);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: _buildStockBadge(),
                  ),
                  if (isOutOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Text(
                          'Habis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (quantityInCart > 0)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          '$quantityInCart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // has_units: show "Mulai Rp X.XXX"
                            item.hasUnits && item.activeUnits.isNotEmpty
                                ? 'Mulai ${Formatters.formatRupiah(item.activeUnits.map((u) => u.sellPrice).reduce((a, b) => a < b ? a : b))}'
                                : Formatters.formatRupiah(item.sellPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton.filled(
                            onPressed: isOutOfStock || !canAddMore
                                ? null
                                : () => _onAddPressed(context, ref),
                            icon: Icon(
                              item.hasUnits ? Icons.tune : Icons.add,
                              size: 16,
                            ),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: isOutOfStock || !canAddMore
                                  ? AppColors.textTertiary
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddPressed(BuildContext context, WidgetRef ref) {
    if (item.hasUnits) {
      showUnitPicker(context, item);
    } else {
      ref.read(cartNotifierProvider.notifier).addItem(item);
      onAddToCart?.call();
    }
  }

  Widget _buildProductImage() {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundDark,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.backgroundDark,
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    final status = item.stockStatus;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        item.hasUnits
            ? item.displayStock
            : (item.stock == 0 ? 'Habis' : '${item.stock}'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
