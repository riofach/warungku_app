import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';

class OrderDetailHeader extends StatelessWidget {
  final Order order;

  const OrderDetailHeader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface, // Or white depending on design, using surface usually safer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // Wrap text with Expanded to take available space
                child: Text(
                  order.code,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                ),
              ),
              const SizedBox(width: AppSpacing.sm), // Add spacing between items
              _buildStatusBadge(order.status, order.deliveryType),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                Formatters.formatDateTime(order.createdAt), // Verify formatters
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                order.paymentMethod.toUpperCase() == 'QRIS' ? 'QRIS' : 'Tunai',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, String deliveryType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              status.getLabel(deliveryType: deliveryType),
              style: AppTypography.labelSmall.copyWith(color: status.color),
              overflow: TextOverflow.ellipsis, // Ensure ellipsis if still too long
            ),
          ),
        ],
      ),
    );
  }
}
