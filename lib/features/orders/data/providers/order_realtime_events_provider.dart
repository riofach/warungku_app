import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'realtime_orders_provider.dart';

/// Provides a filtered stream of new order events (INSERT).
/// This stream emits PostgresChangePayload objects only for INSERT events.
final newOrderEventsProvider = StreamProvider<PostgresChangePayload>((ref) {
  final controller = StreamController<PostgresChangePayload>();

  final sub = ref.listen<AsyncValue<PostgresChangePayload>>(
    realtimeOrdersStreamProvider,
    (previous, next) {
      next.whenData((payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
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
