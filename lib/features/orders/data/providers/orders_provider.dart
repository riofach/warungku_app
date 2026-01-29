import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/inventory/data/providers/housing_blocks_provider.dart';
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
final ordersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final housingBlocksState = ref.watch(housingBlockListNotifierProvider);
  
  return repository.getOrdersStream().map((orders) {
    // If housing blocks are available, map the names
    final blocks = housingBlocksState.blocks;
    
    if (blocks.isEmpty) {
      return orders;
    }

    return orders.map((order) {
      // Find matching housing block
      final block = blocks.where((b) => b.id == order.housingBlockId).firstOrNull;
      
      if (block != null) {
        return order.copyWith(housingBlockName: block.name);
      }
      return order;
    }).toList();
  });
});

/// Provider to fetch a single order by ID
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});
