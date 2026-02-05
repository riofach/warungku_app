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
import '../../../../features/inventory/data/providers/housing_blocks_provider.dart';
import '../../../../core/services/realtime_connection_monitor.dart';
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

    // Listen to new order events
    ref.listen<AsyncValue<PostgresChangePayload>>(newOrderEventsProvider, (
      previous,
      next,
    ) {
      next.whenData((payload) {
        ref.invalidate(ordersProvider);
        debugPrint('OrdersScreen: Detected new order INSERT, refreshing list.');
      });
    });

    // Listen to connection state changes
    ref.listen<ConnectionState>(connectionStateProvider, (previous, next) {
      debugPrint('OrdersScreen: Connection state changed from $previous to $next');
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 40,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: ordersAsync.when(
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
              debugPrint('OrdersScreen: Loading state with cached data: ${cachedOrders.length} orders');
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(cachedOrders, [OrderStatus.pending, OrderStatus.paid]),
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
              debugPrint('OrdersScreen: Error state but showing cached data: ${cachedOrders.length} orders');
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(cachedOrders, [OrderStatus.pending, OrderStatus.paid]),
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
            return Stack(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, List<OrderStatus> statuses) {
    final filteredOrders = allOrders
        .where((order) => statuses.contains(order.status))
        .toList();

    if (filteredOrders.isEmpty) {
      // Bungkus EmptyStateWidget dalam Stack dengan ListView
      // agar tetap bisa di-refresh (pull-to-refresh)
      return Stack(
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
      );
    }

    return ListView.builder(
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
    );
  }
}
