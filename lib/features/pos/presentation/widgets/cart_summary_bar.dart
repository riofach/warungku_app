import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/cart_provider.dart';

/// Cart summary bar widget for POS screen
/// Displays cart item count and total price
/// Shows at bottom of screen when cart has items
class CartSummaryBar extends ConsumerWidget {
  final VoidCallback? onTap;

  const CartSummaryBar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final totalQuantity = cartState.totalQuantity;
    final totalPrice = cartState.totalPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Cart icon with badge
              Badge(
                label: Text(
                  '$totalQuantity',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Item count text
              Text(
                '$totalQuantity item',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Total price
              Text(
                Formatters.formatRupiah(totalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Arrow icon
              const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
