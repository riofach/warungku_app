import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/core/constants/supabase_constants.dart';
import 'package:warungku_app/core/router/app_router.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';
import 'package:warungku_app/features/orders/data/providers/realtime_orders_provider.dart';
import 'package:warungku_app/features/orders/data/providers/order_realtime_events_provider.dart';
import 'package:warungku_app/features/orders/presentation/widgets/new_order_notification_banner.dart';
import 'package:warungku_app/features/orders/presentation/widgets/new_order_notification_overlay_host.dart';

// Mocks
class MockOrderRepository extends Mock implements OrderRepository {}
class MockGoRouter extends Mock implements GoRouter {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('NewOrderNotificationOverlayHost', () {
    late MockOrderRepository mockOrderRepository;
    late StreamController<PostgresChangePayload> realtimeOrdersSourceController;
    late MockGoRouter mockGoRouter;
    late MockNavigatorObserver mockNavigatorObserver;

    // Register fallback for GoRouter to avoid "no valid fallback" error
    setUpAll(() {
      registerFallbackValue(Uri.parse('/'));
    });

    setUp(() {
      mockOrderRepository = MockOrderRepository();
      realtimeOrdersSourceController = StreamController<PostgresChangePayload>();
      mockGoRouter = MockGoRouter();
      mockNavigatorObserver = MockNavigatorObserver();

      when(() => mockOrderRepository.getOrdersRealtimeStream())
          .thenAnswer((_) => realtimeOrdersSourceController.stream);

      // Mock untuk GoRouter, kita akan verifikasi context.go()
      // Note: GoRouter.go is a method, not a getter, so we need to mock it like this.
      when(() => mockGoRouter.go(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async {});
      when(() => mockGoRouter.push(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      await realtimeOrdersSourceController.close();
    });

    Future<void> pumpTestWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
            routerProvider.overrideWithValue(mockGoRouter), // Provide the mocked GoRouter
          ],
          child: NewOrderNotificationOverlayHost(
            child: MaterialApp.router(
              title: 'Test App',
              routerConfig: mockGoRouter, // Langsung menggunakan mockGoRouter
            ),
          ),
        ),
      );
      // Wait for all widgets to render and initial navigations to settle
      await tester.pumpAndSettle();
    }

    testWidgets('Banner appears on new order event', (tester) async {
      await pumpTestWidget(tester);

      expect(find.byType(NewOrderNotificationBanner), findsNothing);

      final orderPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': 'order-123', 'customer_name': 'Budi', 'total': 50000},
      );

      realtimeOrdersSourceController.add(orderPayload);
      await tester.pumpAndSettle(const Duration(milliseconds: 100)); // Allow provider to update and overlay to build

      expect(find.byType(NewOrderNotificationBanner), findsOneWidget);
      expect(find.text('🛒 Pesanan baru dari Budi'), findsOneWidget);
    });

    testWidgets('Tapping banner navigates to OrderDetailScreen and removes banner', (tester) async {
      await pumpTestWidget(tester);

      final orderPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': 'order-456', 'customer_name': 'Ani', 'total': 75000},
      );

      realtimeOrdersSourceController.add(orderPayload);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byType(NewOrderNotificationBanner), findsOneWidget);

      await tester.tap(find.byType(NewOrderNotificationBanner));
      await tester.pumpAndSettle(); // Settle navigation

      // Verify navigation occurred
      verify(() => mockGoRouter.go('${AppRoutes.orderDetail}/order-456')).called(1);

      // Verify banner is removed
      expect(find.byType(NewOrderNotificationBanner), findsNothing);
    });

    testWidgets('Banner disappears automatically after 5 seconds', (tester) async {
      await pumpTestWidget(tester);

      final orderPayload = PostgresChangePayload(
        eventType: PostgresChangeEvent.insert,
        commitTimestamp: DateTime.now(),
        schema: 'public',
        table: SupabaseConstants.tableOrders,
        errors: const [],
        oldRecord: const {},
        newRecord: {'id': 'order-789', 'customer_name': 'Cici', 'total': 100000},
      );

      realtimeOrdersSourceController.add(orderPayload);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byType(NewOrderNotificationBanner), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 5, milliseconds: 500)); // Wait for 5.5 seconds to ensure disappearance

      expect(find.byType(NewOrderNotificationBanner), findsNothing);
    });
  });
}

