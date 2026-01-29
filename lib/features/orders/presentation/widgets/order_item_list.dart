import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';

class OrderItemList extends StatelessWidget {
  final List<OrderItem> items;

  const OrderItemList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Pesanan',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Text('Tidak ada item', style: AppTypography.bodyMedium),

          // Use ListView.separated for better performance with many items,
          // though shrinkWrap is still needed inside SingleChildScrollView
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _buildItemRow(items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail (Optional)
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            image: item.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) => {},
                  )
                : null,
          ),
          child: item.imageUrl == null
              ? const Icon(
                  Icons.fastfood,
                  color: AppColors.textSecondary,
                  size: 24,
                )
              : null, // Fallback handled by decoration logic or error builder could be better, but NetworkImage onError is limited in DecorationImage
        ),
        const SizedBox(width: AppSpacing.md),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} x ${Formatters.formatRupiah(item.price)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),

        // Subtotal
        Text(
          Formatters.formatRupiah(item.subtotal),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
