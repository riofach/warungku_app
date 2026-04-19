import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/providers/report_data_provider.dart';
import 'order_list_item.dart';

class OrderListSection extends ConsumerWidget {
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OrderListSection({
    super.key,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(reportOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: EmptyStateWidget(
                icon: Icons.shopping_bag_outlined,
                title: 'Belum ada pesanan',
                subtitle: 'Tidak ada pesanan online pada periode ini',
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: orders.length,
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderListItem(
              order: order,
              onTap: () => context.push('/orders/detail/${order.id}'),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorWidget(
            message: 'Gagal memuat pesanan',
            onRetry: () => ref.invalidate(reportOrdersProvider),
          ),
        ),
      ),
    );
  }
}
