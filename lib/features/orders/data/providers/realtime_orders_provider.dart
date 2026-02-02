import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/order_repository.dart';

/// Provides a stream of real-time changes from the 'orders' table.
/// This stream emits PostgresChangePayload objects for INSERT and UPDATE events.
final realtimeOrdersStreamProvider = StreamProvider<PostgresChangePayload>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getOrdersRealtimeStream();
});
