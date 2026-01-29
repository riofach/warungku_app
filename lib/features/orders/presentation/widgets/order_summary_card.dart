import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final Order order;

  const OrderSummaryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Column(
        children: [
          _buildRow('Subtotal', Formatters.formatRupiah(order.total)),
           // Grand Total same as Subtotal for now as Delivery is free
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                Formatters.formatRupiah(order.total),
                style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (order.status == OrderStatus.pending)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      order.paymentMethod.toLowerCase() == 'qris' 
                          ? 'Pesanan belum lunas (QRIS)'
                          : 'Bayar di tempat (Tunai)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
             if (order.status == OrderStatus.paid || order.status == OrderStatus.completed)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pembayaran Lunas',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
