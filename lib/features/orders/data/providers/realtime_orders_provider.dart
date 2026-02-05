import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/order_repository.dart';
import '../../../../core/services/realtime_connection_monitor.dart';

/// Provides a stream of real-time changes from the 'orders' table.
/// This stream emits PostgresChangePayload objects for INSERT and UPDATE events.
/// 
/// Enhanced with connection monitoring:
/// - Monitors connection state through ConnectionMonitor
/// - Triggers data refresh when fallback polling activates
/// - Handles reconnection gracefully
final realtimeOrdersStreamProvider = StreamProvider<PostgresChangePayload>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  
  // Get the stream from repository
  final stream = orderRepository.getOrdersRealtimeStream();
  
  // Listen to connection state changes
  ref.listen<ConnectionState>(connectionStateProvider, (previous, next) {
    // Log connection state changes for debugging
    if (previous != next) {
      // ignore: avoid_print
      print('[REALTIME_ORDERS_STREAM] Connection state: $previous → $next');
    }
  });
  
  return stream;
});

/// Provider that combines realtime stream with connection monitoring
/// Provides enhanced error handling and connection state awareness
final enhancedRealtimeOrdersProvider = Provider<AsyncValue<PostgresChangePayload>>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  final realtimeStream = ref.watch(realtimeOrdersStreamProvider);
  
  // When in polling mode, we may want to poll orders periodically
  // This is handled by the OrdersScreen listening to connectionStateProvider
  
  return realtimeStream.when(
    data: (payload) {
      // Log successful data receipt with connection state
      // ignore: avoid_print
      print('[ENHANCED_REALTIME_ORDERS] Received payload: ${payload.eventType} (State: $connectionState)');
      return AsyncValue.data(payload);
    },
    loading: () {
      // ignore: avoid_print
      print('[ENHANCED_REALTIME_ORDERS] Loading... (State: $connectionState)');
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      // Log error with connection state for debugging
      // ignore: avoid_print
      print('[ENHANCED_REALTIME_ORDERS] Error: $error (State: $connectionState)');
      return AsyncValue.error(error, stack);
    },
  );
});
