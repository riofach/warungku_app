import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

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

/// Provider for the list of orders with real-time updates
/// Uses server-side join to include housing block data
final ordersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  
  // Server-side join is now handled in repository.getOrdersStream()
  // Housing block data is included directly from the query
  return repository.getOrdersStream();
});

/// Provider to fetch a single order by ID
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});
