import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import '../../../../core/services/realtime_connection_monitor.dart';

/// Controller for order actions (update status, cancel)
final orderControllerProvider = AsyncNotifierProvider<OrderController, void>(() {
  return OrderController();
});

class OrderController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // no-op
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(orderRepositoryProvider);
      await repository.updateOrderStatus(orderId, newStatus);
      // Refresh the detail provider to get the latest data immediately
      // The list provider (stream) updates automatically via Supabase Realtime
      ref.invalidate(orderDetailProvider(orderId));
    });
  }
}

/// Cache provider untuk menyimpan data orders terakhir
/// Persist meskipun provider di-refresh atau error
final ordersCacheProvider = StateProvider<List<Order>>((ref) => []);

/// Provider untuk melacak apakah ini load pertama kali
final ordersInitialLoadProvider = StateProvider<bool>((ref) => true);

/// Provider untuk melacak error state
final ordersErrorProvider = StateProvider<String?>((ref) => null);

/// Provider for the list of orders with real-time updates
/// Uses server-side join to include housing block data
/// Enhanced with graceful error handling and persistent cache
final ordersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  
  // Get cache and state refs
  final cachedOrders = ref.read(ordersCacheProvider);
  final isFirstLoad = ref.read(ordersInitialLoadProvider);
  
  // Create a stream controller
  final controller = StreamController<List<Order>>.broadcast();
  
  // Emit cached data immediately if available (prevents empty state flash)
  if (cachedOrders.isNotEmpty) {
    debugPrint('[ORDERS_PROVIDER] Emitting cached data immediately: ${cachedOrders.length} orders');
    controller.add(cachedOrders);
  }
  
  // Function to fetch orders with error handling
  Future<void> fetchOrders() async {
    try {
      debugPrint('[ORDERS_PROVIDER] Fetching orders... (firstLoad: $isFirstLoad)');
      final orders = await repository.getOrders();
      
      // Update cache
      ref.read(ordersCacheProvider.notifier).state = orders;
      ref.read(ordersInitialLoadProvider.notifier).state = false;
      ref.read(ordersErrorProvider.notifier).state = null;
      
      if (!controller.isClosed) {
        controller.add(orders);
        debugPrint('[ORDERS_PROVIDER] Fetch success: ${orders.length} orders');
      }
    } catch (e) {
      debugPrint('[ORDERS_PROVIDER] Fetch error: $e');
      ref.read(ordersErrorProvider.notifier).state = e.toString();
      ref.read(ordersInitialLoadProvider.notifier).state = false;
      
      // If we have cached data, emit it (don't show error)
      if (cachedOrders.isNotEmpty && !controller.isClosed) {
        debugPrint('[ORDERS_PROVIDER] Using cached data due to error');
        controller.add(cachedOrders);
      } else if (!controller.isClosed) {
        // No cache, emit empty list
        debugPrint('[ORDERS_PROVIDER] No cache available, emitting empty list');
        controller.add([]);
      }
    }
  }
  
  // Listen to connection state changes
  final connectionSub = ref.listen<ConnectionState>(
    connectionStateProvider,
    (previous, next) {
      debugPrint('[ORDERS_PROVIDER] Connection state: $previous → $next');
      
      // When connection is restored, refresh data
      if (previous == ConnectionState.polling && 
          next == ConnectionState.connected) {
        debugPrint('[ORDERS_PROVIDER] Connection restored, refreshing...');
        fetchOrders();
      }
      
      // When in polling mode, fetch data periodically
      if (next == ConnectionState.polling) {
        debugPrint('[ORDERS_PROVIDER] Polling mode, fetching...');
        fetchOrders();
      }
    },
  );
  
  // Start fetching (but don't block on first load)
  fetchOrders();
  
  // Cleanup
  ref.onDispose(() {
    debugPrint('[ORDERS_PROVIDER] Disposing...');
    connectionSub.close();
    controller.close();
  });
  
  return controller.stream;
});

/// Provider to fetch a single order by ID
/// Enhanced with error handling
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  try {
    return await repository.getOrderById(orderId);
  } catch (e) {
    debugPrint('[ORDER_DETAIL_PROVIDER] Error fetching order $orderId: $e');
    rethrow;
  }
});
