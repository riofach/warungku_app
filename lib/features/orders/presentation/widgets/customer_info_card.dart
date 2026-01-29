import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/order_model.dart';

class CustomerInfoCard extends StatelessWidget {
  final Order order;

  const CustomerInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pelanggan',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRow('Nama Pelanggan', order.customerName),
          const Divider(height: AppSpacing.lg),
          _buildRow('Blok Rumah', order.housingBlockName ?? '-'),
          const Divider(height: AppSpacing.lg),
          _buildRow('Tipe Pengiriman', order.deliveryType == 'delivery' ? 'Diantar' : 'Ambil Sendiri'),
          const Divider(height: AppSpacing.lg),
          _buildRow('Ongkos Kirim', 'Gratis', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isHighlight ? AppColors.success : AppColors.textPrimary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
