import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../providers/dashboard_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repositories/order_repository.dart';

/// Provider for new website orders with realtime updates
final newOrdersProvider = AsyncNotifierProvider<NewOrdersNotifier, List<Order>>(
  NewOrdersNotifier.new,
);

/// Notifier for managing new orders state with Supabase Realtime
class NewOrdersNotifier extends AsyncNotifier<List<Order>> {
  RealtimeChannel? _channel;
  
  // Callback for new order notifications (set by dashboard screen)
  static void Function(Order)? onNewOrderReceived;
  
  @override
  Future<List<Order>> build() async {
    // Setup realtime subscription
    _setupRealtimeSubscription();
    
    // Cleanup on dispose
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
            debugPrint('[NEW_ORDERS] INSERT event received: ${payload.newRecord}');
            _handleInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.tableOrders,
          callback: (payload) {
            debugPrint('[NEW_ORDERS] UPDATE event received: ${payload.newRecord}');
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
    final status = newRecord['status'] as String?;
    if (status == 'pending' || status == 'paid') {
      // Refetch to get housing block join data
      refresh();
      
      // Trigger notification callback
      try {
        final order = Order.fromJson(newRecord);
        if (onNewOrderReceived != null) {
          onNewOrderReceived!(order);
        }
      } catch (e) {
        debugPrint('[NEW_ORDERS] Error parsing new order for notification: $e');
      }
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
      // If status updated TO pending/paid, refresh
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
