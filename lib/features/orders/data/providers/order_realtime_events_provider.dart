import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'realtime_orders_provider.dart';

/// Provides a filtered stream of new order events (INSERT).
/// This stream emits PostgresChangePayload objects only for INSERT events.
final newOrderEventsProvider = StreamProvider<PostgresChangePayload>((ref) {
  debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Creating stream...');
  final controller = StreamController<PostgresChangePayload>();

  final sub = ref.listen<AsyncValue<PostgresChangePayload>>(
    realtimeOrdersStreamProvider,
    (previous, next) {
      debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Received data from realtime stream: ${next.runtimeType}');
      next.when(
        data: (payload) {
          debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Payload eventType: ${payload.eventType}');
          if (payload.eventType == PostgresChangeEvent.insert) {
            debugPrint('[NEW_ORDER_EVENTS_PROVIDER] INSERT event detected, adding to controller');
            debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Payload data: ${payload.newRecord}');
            controller.add(payload);
          } else {
            debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Not an INSERT event: ${payload.eventType}');
          }
        },
        loading: () {
          debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Loading state...');
        },
        error: (error, stack) {
          debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Error: $error');
          debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Stack: $stack');
        },
      );
    },
  );

  ref.onDispose(() {
    debugPrint('[NEW_ORDER_EVENTS_PROVIDER] Disposing...');
    sub.close(); // Close the listener
    controller.close(); // Close the controller
  });

  return controller.stream;
});

/// Provides a filtered stream of order update events (UPDATE).
/// This stream emits PostgresChangePayload objects only for UPDATE events.
final orderUpdateEventsProvider = StreamProvider<PostgresChangePayload>((ref) {
  final controller = StreamController<PostgresChangePayload>();

  final sub = ref.listen<AsyncValue<PostgresChangePayload>>(
    realtimeOrdersStreamProvider,
    (previous, next) {
      next.whenData((payload) {
        if (payload.eventType == PostgresChangeEvent.update) {
          controller.add(payload);
        }
      });
    },
  );

  ref.onDispose(() {
    sub.close(); // Close the listener
    controller.close(); // Close the controller
  });

  return controller.stream;
});
