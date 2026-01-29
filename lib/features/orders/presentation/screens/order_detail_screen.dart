import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../data/providers/orders_provider.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/order_detail_header.dart';
import '../widgets/order_item_list.dart';
import '../widgets/order_summary_card.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Detail Pesanan', style: AppTypography.appBarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderDetailHeader(order: order),
              const SizedBox(height: AppSpacing.md),
              CustomerInfoCard(order: order),
              const SizedBox(height: AppSpacing.md),
              OrderItemList(items: order.items),
              const SizedBox(height: AppSpacing.md),
              OrderSummaryCard(order: order),
            ],
          ),
        ),
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => AppErrorWidget(
          message: 'Gagal memuat pesanan',
          details: error.toString(),
          onRetry: () => ref.refresh(orderDetailProvider(orderId)),
        ),
      ),
    );
  }
}
