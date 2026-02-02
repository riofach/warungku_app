import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed for PostgresChangePayload
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../features/inventory/data/providers/housing_blocks_provider.dart';
import '../../data/models/order_model.dart';
import '../../data/providers/orders_provider.dart';
import '../../data/providers/order_realtime_events_provider.dart'; // Needed for real-time listeners
import '../widgets/order_card.dart'; // Make sure this widget exists or is implemented

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Ensure housing blocks are loaded for mapping names
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(housingBlockListNotifierProvider.notifier).loadBlocks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan real-time dari orderUpdateEventsProvider
    ref.listen<AsyncValue<PostgresChangePayload>>(orderUpdateEventsProvider, (previous, next) {
      next.whenData((payload) {
        // Ketika ada event UPDATE, refresh daftar pesanan
        ref.invalidate(ordersProvider); // Invalidate ordersProvider yang ada
        debugPrint('OrdersScreen: Detected order UPDATE, refreshing list.');
      });
    });

    // Mendengarkan pesanan baru dari newOrderEventsProvider
    ref.listen<AsyncValue<PostgresChangePayload>>(newOrderEventsProvider, (previous, next) {
      next.whenData((payload) {
        // Ketika ada event INSERT, refresh daftar pesanan
        ref.invalidate(ordersProvider); // Invalidate ordersProvider yang ada
        debugPrint('OrdersScreen: Detected new order INSERT, refreshing list.');
      });
    });

    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Baru'),
            Tab(text: 'Proses'),
            Tab(text: 'Selesai'),
            Tab(text: 'Batal'),
          ],
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(orders, [OrderStatus.pending, OrderStatus.paid]),
              _buildOrderList(orders, [OrderStatus.processing, OrderStatus.ready, OrderStatus.delivered]),
              _buildOrderList(orders, [OrderStatus.completed]),
              _buildOrderList(orders, [OrderStatus.cancelled, OrderStatus.failed]),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(ordersProvider),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, List<OrderStatus> statuses) {
    final filteredOrders = allOrders
        .where((order) => statuses.contains(order.status))
        .toList();

    if (filteredOrders.isEmpty) {
      return const EmptyStateWidget(
        title: 'Belum ada pesanan',
        subtitle: 'Pesanan dengan status ini belum tersedia',
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return OrderCard(
          order: order,
          onTap: () {
            context.push('${AppRoutes.orderDetail}/${order.id}');
          },
        );
      },
    );
  }
}