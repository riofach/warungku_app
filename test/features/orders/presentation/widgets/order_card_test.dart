import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';
import 'package:warungku_app/features/orders/presentation/widgets/order_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testOrder = Order(
    id: '1',
    code: 'WRG-2023-001',
    customerName: 'Budi Santoso',
    housingBlockName: 'Blok A1',
    paymentMethod: 'cash',
    deliveryType: 'delivery',
    status: OrderStatus.pending,
    total: 50000,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
  );

  testWidgets('OrderCard displays correct information', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(order: testOrder),
        ),
      ),
    );

    // Verify basic info
    expect(find.text('WRG-2023-001'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Blok A1'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget); // Assuming formatRupiah works
    
    // Verify status badge
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
  });

  testWidgets('OrderCard handles missing housing block', (WidgetTester tester) async {
    final orderNoBlock = Order(
      id: '1',
      code: 'WRG-2023-001',
      customerName: 'Budi Santoso',
      housingBlockName: null,
      paymentMethod: 'cash',
      deliveryType: 'delivery',
      status: OrderStatus.pending,
      total: 50000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(order: orderNoBlock),
        ),
      ),
    );

    expect(find.text('Tanpa Lokasi'), findsOneWidget);
  });
}
