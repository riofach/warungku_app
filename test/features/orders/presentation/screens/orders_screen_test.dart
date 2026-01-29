import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku_app/features/inventory/data/models/housing_block_model.dart';
import 'package:warungku_app/features/inventory/data/providers/housing_blocks_provider.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';
import 'package:warungku_app/features/orders/data/providers/orders_provider.dart';
import 'package:warungku_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:warungku_app/features/orders/presentation/widgets/order_card.dart';

// Mock Notifier
class MockHousingBlockListNotifier extends HousingBlockListNotifier {
  @override
  Future<void> loadBlocks() async {
    // No-op for test
    state = HousingBlockListState.loaded([
      HousingBlock(
        id: 'block-1',
        name: 'Blok A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final now = DateTime.now();
  final testOrders = [
    // Baru (Pending/Paid)
    Order(
      id: '1',
      code: 'ORDER-1',
      customerName: 'User 1',
      housingBlockName: 'Blok A1',
      paymentMethod: 'cash',
      deliveryType: 'delivery',
      status: OrderStatus.pending,
      total: 10000,
      createdAt: now,
      updatedAt: now,
    ),
    Order(
      id: '2',
      code: 'ORDER-2',
      customerName: 'User 2',
      paymentMethod: 'qris',
      deliveryType: 'pickup',
      status: OrderStatus.paid,
      total: 20000,
      createdAt: now,
      updatedAt: now,
    ),
    // Proses (Processing/Ready/Delivered)
    Order(
      id: '3',
      code: 'ORDER-3',
      customerName: 'User 3',
      paymentMethod: 'cash',
      deliveryType: 'delivery',
      status: OrderStatus.processing,
      total: 30000,
      createdAt: now,
      updatedAt: now,
    ),
    // Selesai (Completed)
    Order(
      id: '4',
      code: 'ORDER-4',
      customerName: 'User 4',
      paymentMethod: 'cash',
      deliveryType: 'pickup',
      status: OrderStatus.completed,
      total: 40000,
      createdAt: now,
      updatedAt: now,
    ),
    // Batal (Cancelled/Failed)
    Order(
      id: '5',
      code: 'ORDER-5',
      customerName: 'User 5',
      paymentMethod: 'cash',
      deliveryType: 'delivery',
      status: OrderStatus.cancelled,
      total: 50000,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  testWidgets('OrdersScreen renders 4 tabs and filters orders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith((ref) => Stream.value(testOrders)),
          housingBlockListNotifierProvider.overrideWith(() => MockHousingBlockListNotifier()),
        ],
        child: const MaterialApp(
          home: OrdersScreen(),
        ),
      ),
    );

    // Allow FutureBuilder/StreamBuilder to resolve
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // Animation

    // Verify Tabs
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('Proses'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Initial Tab: Baru
    // Should see ORDER-1 and ORDER-2
    expect(find.text('ORDER-1'), findsOneWidget);
    expect(find.text('ORDER-2'), findsOneWidget);
    // Should NOT see other orders
    expect(find.text('ORDER-3'), findsNothing); // Processing
    expect(find.text('ORDER-4'), findsNothing); // Completed
    expect(find.text('ORDER-5'), findsNothing); // Cancelled

    // Tap 'Proses' Tab
    await tester.tap(find.text('Proses'));
    await tester.pumpAndSettle();

    // Should see ORDER-3
    expect(find.text('ORDER-3'), findsOneWidget);
    expect(find.text('ORDER-1'), findsNothing);

    // Tap 'Selesai' Tab
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    // Should see ORDER-4
    expect(find.text('ORDER-4'), findsOneWidget);

    // Tap 'Batal' Tab
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Should see ORDER-5
    expect(find.text('ORDER-5'), findsOneWidget);
  });

  testWidgets('OrdersScreen shows empty state when no orders in tab', (WidgetTester tester) async {
    // Only cancelled orders
    final cancelledOrders = [testOrders.last];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith((ref) => Stream.value(cancelledOrders)),
          housingBlockListNotifierProvider.overrideWith(() => MockHousingBlockListNotifier()),
        ],
        child: const MaterialApp(
          home: OrdersScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tab 'Baru' should be empty
    expect(find.text('Belum ada pesanan'), findsOneWidget);
    expect(find.text('Pesanan dengan status ini belum tersedia'), findsOneWidget);

    // Tab 'Batal' should have content
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('ORDER-5'), findsOneWidget);
    expect(find.text('Belum ada pesanan'), findsNothing);
  });
}
