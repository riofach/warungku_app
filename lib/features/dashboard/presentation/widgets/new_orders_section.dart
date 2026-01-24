import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../orders/data/models/order_model.dart';
import '../../data/providers/new_orders_provider.dart';
import 'new_order_card.dart';

class NewOrdersSection extends ConsumerWidget {
  const NewOrdersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newOrdersAsync = ref.watch(newOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, newOrdersAsync),
        const SizedBox(height: AppSpacing.sm),
        
        // Content
        newOrdersAsync.when(
          data: (orders) => orders.isEmpty
              ? _buildEmptyState(context)
              : _buildOrdersList(context, orders),
          loading: () => _buildShimmer(),
          error: (error, _) => _buildError(context, error),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<List<Order>> ordersAsync) {
    final count = ordersAsync.value?.length ?? 0;
    
    return Row(
      children: [
        const Icon(Icons.shopping_cart, color: AppColors.primary, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Pesanan Baru',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (count > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
        const Spacer(),
        // "Lihat Semua" link
        if (count > 0)
          TextButton(
            onPressed: () => context.push('/orders'),
            child: Text(
              'Lihat Semua',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.markunread_mailbox_outlined,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '📭 Belum ada pesanan baru',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    return Column(
      children: orders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: NewOrderCard(
            order: order,
            onTap: () => context.push('/orders'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(2, (index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _ShimmerOrderCard(),
      )),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Gagal memuat pesanan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerOrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 24,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
