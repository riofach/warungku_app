import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/realtime_connection_monitor.dart';
import '../providers/dashboard_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repositories/order_repository.dart';

/// Provider for new website orders with realtime updates
final newOrdersProvider = AsyncNotifierProvider<NewOrdersNotifier, List<Order>>(
  NewOrdersNotifier.new,
);

// ---------------------------------------------------------------------------
// Global broadcast stream for new order notification events.
// This is the SINGLE SOURCE OF TRUTH for in-app banner notifications.
// Listened to by NewOrderNotificationOverlayHost (global, always mounted).
// ---------------------------------------------------------------------------
final _newOrderNotificationController = StreamController<Order>.broadcast();

/// Provides a stream of newly-inserted orders for the notification overlay.
/// Emits an [Order] everytime a new order INSERT is received via Realtime.
final newOrderNotificationStreamProvider = StreamProvider<Order>((ref) {
  return _newOrderNotificationController.stream;
});

/// Emit a new order notification to the global banner overlay.
/// Called from [ordersProvider] when polling detects a new order,
/// AND from [NewOrdersNotifier] when Supabase Realtime delivers an INSERT.
void emitNewOrderNotification(Order order) {
  debugPrint('[NOTIFICATION] 🚀 emitNewOrderNotification: ${order.code}');
  _newOrderNotificationController.add(order);
}

/// Notifier for managing new orders state with Supabase Realtime
class NewOrdersNotifier extends AsyncNotifier<List<Order>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Order>> build() async {
    debugPrint(
      '[NEW_ORDERS] 🚀 Provider build() called — setting up realtime channel...',
    );

    // Keep this notifier alive globally so the realtime subscription
    // persists even when the DashboardScreen is not mounted.
    ref.keepAlive();

    // Setup realtime subscription
    _setupRealtimeSubscription();

    // Connection recovery: if connection is re-established after disruption,
    // refresh the orders list to catch any events missed during the outage.
    ref.listen(connectionStateProvider, (previous, next) {
      if (next == ConnectionState.connected &&
          (previous == ConnectionState.reconnecting ||
              previous == ConnectionState.polling)) {
        debugPrint(
          '[NEW_ORDERS] 🔄 Connection restored — refreshing to catch missed events...',
        );
        refresh();
      }
    });

    // Cleanup channel on dispose (only if provider is truly removed)
    ref.onDispose(() {
      _disposeChannel();
    });

    // Fetch initial data
    return _fetchNewOrders();
  }

  Future<List<Order>> _fetchNewOrders() async {
    final repository = ref.read(orderRepositoryProvider);
    return repository.getNewOrders();
  }

  void _setupRealtimeSubscription() {
    _channel = Supabase.instance.client
        .channel(SupabaseConstants.channelOrders)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.tableOrders,
          callback: (payload) {
            debugPrint(
              '[NEW_ORDERS] INSERT event received: ${payload.newRecord}',
            );
            _handleInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.tableOrders,
          callback: (payload) {
            debugPrint(
              '[NEW_ORDERS] UPDATE event received: ${payload.newRecord}',
            );
            _handleUpdate(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[NEW_ORDERS] Subscription status: $status');
          if (error != null) {
            debugPrint('[NEW_ORDERS] Subscription error: $error');
          }
        });
  }

  void _handleInsert(Map<String, dynamic> newRecord) {
    // Parse order and emit to global notification stream (ALL new orders).
    try {
      final order = Order.fromJson(newRecord);
      debugPrint(
        '[NEW_ORDERS] 🔔 Emitting new order notification: ${order.code}',
      );
      _newOrderNotificationController.add(order);
    } catch (e) {
      debugPrint('[NEW_ORDERS] Error parsing new order for notification: $e');
    }

    // Also refresh the pending orders list
    final status = newRecord['status'] as String?;
    if (status == 'pending' || status == 'paid') {
      refresh();
    }
  }

  void _handleUpdate(Map<String, dynamic> newRecord) {
    final status = newRecord['status'] as String?;
    final orderId = newRecord['id'] as String?;

    if (status != 'pending' && status != 'paid' && orderId != null) {
      // Remove order from list if status changed to non-pending/paid
      state.whenData((orders) {
        final updatedOrders = orders.where((o) => o.id != orderId).toList();
        state = AsyncData(updatedOrders);
      });

      // Refresh global dashboard data since an order is processed
      ref.invalidate(dashboardProvider);
    } else if ((status == 'pending' || status == 'paid') && orderId != null) {
      refresh();
    }
  }

  void _disposeChannel() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      debugPrint('[NEW_ORDERS] Channel disposed');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchNewOrders());
  }
}
