import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import '../../../../core/services/realtime_connection_monitor.dart';
import 'realtime_orders_provider.dart';
import '../../../../features/dashboard/data/providers/new_orders_provider.dart';

/// App startup timestamp — orders created before this time are IGNORED
/// for notifications (avoids showing old orders as 'new' on app restart).
final _appStartTime = DateTime.now();

/// Controller for order actions (update status, cancel)
final orderControllerProvider = AsyncNotifierProvider<OrderController, void>(
  () {
    return OrderController();
  },
);

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
    debugPrint(
      '[ORDERS_PROVIDER] Emitting cached data immediately: ${cachedOrders.length} orders',
    );
    controller.add(cachedOrders);
  }

  // Function to fetch orders with error handling
  Future<void> fetchOrders() async {
    try {
      debugPrint(
        '[ORDERS_PROVIDER] Fetching orders... (firstLoad: $isFirstLoad)',
      );
      final orders = await repository.getOrders();

      // =====================================================================
      // NOTIFICATION DETECTION: Find newly inserted orders vs previous cache.
      // This is the PRIMARY notification trigger since Supabase Realtime may
      // not be configured. The 30s poll is 100% reliable.
      // =====================================================================
      final previousIds = ref
          .read(ordersCacheProvider)
          .map((o) => o.id)
          .toSet();
      final newOrders = orders.where((o) {
        // Must be a new ID (not in previous fetch)
        if (previousIds.isNotEmpty && previousIds.contains(o.id)) return false;
        // Must be pending or paid (active new order)
        if (o.status != OrderStatus.pending && o.status != OrderStatus.paid)
          return false;
        // Must have been created AFTER app startup (ignore historical orders)
        if (o.createdAt.isBefore(
          _appStartTime.subtract(const Duration(minutes: 5)),
        ))
          return false;
        return true;
      }).toList();

      for (final newOrder in newOrders) {
        debugPrint(
          '[ORDERS_PROVIDER] 🔔 New order detected via poll: ${newOrder.code}',
        );
        emitNewOrderNotification(newOrder);
      }
      // =====================================================================

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

  // Listen to connection state changes (for transitions)
  final connectionSub = ref.listen<ConnectionState>(connectionStateProvider, (
    previous,
    next,
  ) {
    debugPrint('[ORDERS_PROVIDER] Connection state: $previous → $next');

    // When connection is restored, refresh data
    if (previous == ConnectionState.polling &&
        next == ConnectionState.connected) {
      debugPrint('[ORDERS_PROVIDER] Connection restored, refreshing...');
      fetchOrders();
    }
  });

  // Listen to the connection stream for polling ticks
  // The stream emits events even if the state value doesn't change
  final monitor = ref.read(connectionMonitorProvider);
  final streamSub = monitor.connectionStateStream.listen((state) {
    if (state == ConnectionState.polling) {
      debugPrint('[ORDERS_PROVIDER] Polling tick received, fetching...');
      fetchOrders();
    }
  });

  // Periodic fallback polling every 30 seconds
  // Ensures list stays fresh even when Supabase Realtime events are missed
  // (e.g., RLS issue, background connection drop, silent failure)
  final pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (!controller.isClosed) {
      debugPrint('[ORDERS_PROVIDER] Periodic 30s poll — refreshing orders...');
      fetchOrders();
    }
  });

  // Listen to Realtime Events (INSERT/UPDATE/DELETE)
  // This triggers a refresh whenever the DB changes
  final realtimeSub = ref.listen<AsyncValue<PostgresChangePayload>>(
    realtimeOrdersStreamProvider,
    (previous, next) {
      next.whenData((payload) {
        debugPrint(
          '[ORDERS_PROVIDER] Realtime event: ${payload.eventType}, refreshing list...',
        );
        fetchOrders();
      });
    },
  );

  // Start fetching (but don't block on first load)
  fetchOrders();

  // Cleanup
  ref.onDispose(() {
    debugPrint('[ORDERS_PROVIDER] Disposing...');
    connectionSub.close();
    realtimeSub.close();
    streamSub.cancel();
    pollingTimer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider to fetch a single order by ID
/// Enhanced with error handling
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((
  ref,
  orderId,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  try {
    return await repository.getOrderById(orderId);
  } catch (e) {
    debugPrint('[ORDER_DETAIL_PROVIDER] Error fetching order $orderId: $e');
    rethrow;
  }
});
