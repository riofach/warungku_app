import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../data/providers/cart_provider.dart';

/// Cart Item Tile Widget
/// Displays item details and quantity controls in cart list
class CartItemTile extends ConsumerWidget {
  final CartItem cartItem;

  const CartItemTile({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = cartItem.item;
    // Real-time stock check for increment button
    final canAddMore = ref.read(cartNotifierProvider.notifier).canAddMore(item.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.backgroundDark,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundDark,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundDark,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  Formatters.formatRupiah(item.sellPrice),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Quantity Stepper & Subtotal Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuantityStepper(context, ref),
                    Text(
                      Formatters.formatRupiah(cartItem.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Delete Button
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, WidgetRef ref) {
    final canIncrement = cartItem.quantity < cartItem.item.stock;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: cartItem.quantity > 1
                ? () {
                    ref.read(cartNotifierProvider.notifier)
                        .decrementQuantity(cartItem.item.id);
                  }
                : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onPressed: canIncrement
                ? () {
                    ref.read(cartNotifierProvider.notifier)
                        .incrementQuantity(cartItem.item.id);
                  }
                : () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stok terbatas (Sisa: ${cartItem.item.stock})'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Hapus "${cartItem.item.name}" dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(cartNotifierProvider.notifier).removeItem(cartItem.item.id);
    }
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 16,
    );
  }
}
