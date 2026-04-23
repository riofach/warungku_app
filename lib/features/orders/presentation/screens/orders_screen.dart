import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed for PostgresChangePayload
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/services/realtime_connection_monitor.dart';
import '../../data/models/order_model.dart';
import '../../data/providers/orders_provider.dart';
import '../../data/providers/order_realtime_events_provider.dart'; // masih dipakai oleh orderUpdateEventsProvider
import '../../../../features/dashboard/data/providers/new_orders_provider.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handle manual refresh from pull-to-refresh
  Future<void> _handleRefresh() async {
    debugPrint('OrdersScreen: Manual refresh triggered');

    // Invalidate providers to trigger refresh
    ref.invalidate(ordersProvider);

    // Wait for refresh to complete
    await ref.read(ordersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to realtime order update events
    ref.listen<AsyncValue<PostgresChangePayload>>(orderUpdateEventsProvider, (
      previous,
      next,
    ) {
      next.whenData((payload) {
        ref.invalidate(ordersProvider);
        debugPrint('OrdersScreen: Detected order UPDATE, refreshing list.');
      });
    });

    // Listen to new order INSERT events — single source of truth via [NEW_ORDERS] channel
    ref.listen<AsyncValue<Order>>(newOrderNotificationStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((order) {
        ref.invalidate(ordersProvider);
        debugPrint(
          'OrdersScreen: Detected new order INSERT (${order.code}), refreshing list.',
        );
      });
    });

    // Listen to connection state changes
    ref.listen<ConnectionState>(connectionStateProvider, (previous, next) {
      debugPrint(
        'OrdersScreen: Connection state changed from $previous to $next',
      );
    });

    final ordersAsync = ref.watch(ordersProvider);
    final cachedOrders = ref.watch(ordersCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: ConnectionStatusIndicator(
                compact: MediaQuery.of(context).size.width < 360,
                onTap: () async {
                  // Manual reconnect when tapped
                  final monitor = ref.read(connectionMonitorProvider);
                  await monitor.manualReconnect();
                },
              ),
            ),
          ),
        ],
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
              _buildOrderList(orders, [
                OrderStatus.processing,
                OrderStatus.ready,
                OrderStatus.delivered,
              ]),
              _buildOrderList(orders, [OrderStatus.completed]),
              _buildOrderList(orders, [
                OrderStatus.cancelled,
                OrderStatus.failed,
              ]),
            ],
          );
        },
        loading: () {
          // If we have cached data, show it while loading
          if (cachedOrders.isNotEmpty) {
            debugPrint(
              'OrdersScreen: Loading state with cached data: ${cachedOrders.length} orders',
            );
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(cachedOrders, [
                  OrderStatus.pending,
                  OrderStatus.paid,
                ]),
                _buildOrderList(cachedOrders, [
                  OrderStatus.processing,
                  OrderStatus.ready,
                  OrderStatus.delivered,
                ]),
                _buildOrderList(cachedOrders, [OrderStatus.completed]),
                _buildOrderList(cachedOrders, [
                  OrderStatus.cancelled,
                  OrderStatus.failed,
                ]),
              ],
            );
          }
          return const Center(child: LoadingWidget());
        },
        error: (error, stack) {
          // If we have cached data, show it instead of error
          if (cachedOrders.isNotEmpty) {
            debugPrint(
              'OrdersScreen: Error state but showing cached data: ${cachedOrders.length} orders',
            );
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(cachedOrders, [
                  OrderStatus.pending,
                  OrderStatus.paid,
                ]),
                _buildOrderList(cachedOrders, [
                  OrderStatus.processing,
                  OrderStatus.ready,
                  OrderStatus.delivered,
                ]),
                _buildOrderList(cachedOrders, [OrderStatus.completed]),
                _buildOrderList(cachedOrders, [
                  OrderStatus.cancelled,
                  OrderStatus.failed,
                ]),
              ],
            );
          }
          // No cache, show error with refresh capability
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [],
                ),
                Positioned.fill(
                  child: AppErrorWidget(
                    message: error.toString(),
                    onRetry: () => ref.refresh(ordersProvider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, List<OrderStatus> statuses) {
    final filteredOrders = allOrders
        .where((order) => statuses.contains(order.status))
        .toList();

    if (filteredOrders.isEmpty) {
      // Wrapped in RefreshIndicator so pull-to-refresh works on empty screens too
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [],
            ),
            const Positioned.fill(
              child: EmptyStateWidget(
                title: 'Belum ada pesanan',
                subtitle: 'Pesanan dengan status ini belum tersedia',
                icon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 40,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}
