import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';
import 'package:warungku_app/features/orders/data/providers/orders_provider.dart';
import 'package:warungku_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:warungku_app/features/orders/presentation/widgets/customer_info_card.dart';
import 'package:warungku_app/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:warungku_app/features/orders/presentation/widgets/order_item_list.dart';
import 'package:warungku_app/features/orders/presentation/widgets/order_summary_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('OrderDetailScreen displays all sections correctly', (tester) async {
    final order = Order(
      id: '123',
      code: 'WRG-TEST',
      customerName: 'Test User',
      paymentMethod: 'qris',
      deliveryType: 'delivery',
      status: OrderStatus.paid,
      total: 50000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [
        const OrderItem(id: '1', quantity: 2, price: 10000, subtotal: 20000, itemName: 'Item 1'),
        const OrderItem(id: '2', quantity: 1, price: 30000, subtotal: 30000, itemName: 'Item 2'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderDetailProvider('123').overrideWith((ref) => Future.value(order)),
        ],
        child: const MaterialApp(
          home: OrderDetailScreen(orderId: '123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widgets are present
    expect(find.byType(OrderDetailHeader), findsOneWidget);
    expect(find.byType(CustomerInfoCard), findsOneWidget);
    expect(find.byType(OrderItemList), findsOneWidget);
    expect(find.byType(OrderSummaryCard), findsOneWidget);

    // Verify content
    expect(find.text('WRG-TEST'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
  });
}
