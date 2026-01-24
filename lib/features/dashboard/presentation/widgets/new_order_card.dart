import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/data/models/order_model.dart';

class NewOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const NewOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order code
                    Text(
                      order.code,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    // Customer name and block
                    Text(
                      '${order.customerName}${order.housingBlockName != null ? ' - ${order.housingBlockName}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Time ago and total
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        // Time ago with flexible constraint
                        Flexible(
                          child: Text(
                            order.timeAgo,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm), // Reduced spacing
                        // Total price
                        Text(
                          formatRupiah(order.total),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm), // Added gap between info and badge
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.status.icon,
                      size: 14,
                      color: order.status.color,
                    ),
                    const SizedBox(width: 4),
                    // Use Flexible to handle long status text on small screens
                    Flexible(
                      child: Text(
                        order.status.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: order.status.color,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}
