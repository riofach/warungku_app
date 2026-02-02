import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/core/constants/supabase_constants.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart'; // Ensure Order model is correct
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';
import 'package:warungku_app/features/orders/data/providers/realtime_orders_provider.dart';
import 'package:warungku_app/features/orders/data/providers/order_realtime_events_provider.dart';

// Mock OrderRepository
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  group('Realtime Order Providers', () {
    late MockOrderRepository mockOrderRepository;
    late StreamController<PostgresChangePayload>
        realtimeOrdersSourceController; // This simulates the repository's stream

    setUp(() {
      mockOrderRepository = MockOrderRepository();
      realtimeOrdersSourceController = StreamController<PostgresChangePayload>();

      // Configure the mock to return our controlled stream source
      when(() => mockOrderRepository.getOrdersRealtimeStream())
          .thenAnswer((_) => realtimeOrdersSourceController.stream);
    });

    tearDown(() async {
      await realtimeOrdersSourceController.close();
    });

    test(
        'realtimeOrdersStreamProvider emits events from repository wrapped in AsyncData',
        () async {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        ],
      );

      final listener = container.listen(
        realtimeOrdersStreamProvider,
        (previous, next) {},
      );

      // Simulate an event from the mocked repository's stream
      final testPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': '1', 'customer_name': 'Test Customer', 'total': 10000},
      );

      realtimeOrdersSourceController.add(testPayload);

      // Wait for Riverpod to process the event
      await Future.microtask(() {});

      // Expect the listener to have received an AsyncData with the payload
      expect(listener.read(), isA<AsyncData<PostgresChangePayload>>());
      expect(listener.read().value, testPayload);

      container.dispose();
    });

    test('newOrderEventsProvider filters for INSERT events', () async {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        ],
      );

      final listener = container.listen(
        newOrderEventsProvider,
        (previous, next) {},
      );

      final insertPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': '2', 'customer_name': 'New Customer', 'total': 25000, 'status': 'pending'},
      );

      final updatePayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.update,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {'status': 'pending'},
        newRecord: {'id': '3', 'customer_name': 'Updated Customer', 'total': 30000, 'status': 'paid'},
      );

      // Simulate events
      realtimeOrdersSourceController.add(updatePayload); // Should be filtered out
      await Future.microtask(() {}); // Allow some processing time

      // At this point, newOrderEventsProvider should NOT have received updatePayload
      expect(listener.read().isLoading, true); // It should still be loading or not updated with data

      realtimeOrdersSourceController.add(insertPayload); // Should pass through
      await Future.microtask(() {}); // Allow some processing time

      // Expect the listener to have received the insertPayload
      expect(listener.read(), isA<AsyncData<PostgresChangePayload>>());
      expect(listener.read().value, insertPayload);

      container.dispose();
    });

    test('orderUpdateEventsProvider filters for UPDATE events', () async {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        ],
      );

      final listener = container.listen(
        orderUpdateEventsProvider,
        (previous, next) {},
      );

      final insertPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': '4', 'customer_name': 'Another New Customer', 'total': 15000, 'status': 'pending'},
      );

      final updatePayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.update,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {'status': 'pending'},
        newRecord: {'id': '5', 'customer_name': 'Changed Status', 'total': 40000, 'status': 'delivered'},
      );

      // Simulate events
      realtimeOrdersSourceController.add(insertPayload); // Should be filtered out
      await Future.microtask(() {}); // Allow some processing time

      // At this point, orderUpdateEventsProvider should NOT have received insertPayload
      expect(listener.read().isLoading, true); // It should still be loading or not updated with data

      realtimeOrdersSourceController.add(updatePayload); // Should pass through
      await Future.microtask(() {}); // Allow some processing time

      // Expect the listener to have received the updatePayload
      expect(listener.read(), isA<AsyncData<PostgresChangePayload>>());
      expect(listener.read().value, updatePayload);

      container.dispose();
    });

    // Test for Order.fromJson parsing (this is separate from provider filtering logic)
    test('Order.fromJson parses newRecord correctly', () async {
      final newOrderJson = {
        'id': 'order-test-123',
        'code': 'WRG-001',
        'customer_name': 'Unit Test Customer',
        'total': 50000,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'payment_method': 'cash',
        'delivery_type': 'pickup',
      };
      // This test doesn't need providers, just directly tests Order.fromJson
      final order = Order.fromJson(newOrderJson);

      expect(order.id, 'order-test-123');
      expect(order.code, 'WRG-001');
      expect(order.customerName, 'Unit Test Customer');
      expect(order.total, 50000);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, 'cash');
      expect(order.deliveryType, 'pickup');
    });
  });
}

// Ensure OrderStatus enum is available for comparison
// If OrderModel is auto-generated, you might need to adjust this.
enum OrderStatus {
  pending,
  paid,
  processing,
  ready,
  delivered,
  completed,
  cancelled,
  failed,
}
