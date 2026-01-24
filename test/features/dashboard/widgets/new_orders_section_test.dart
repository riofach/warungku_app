import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/dashboard/data/providers/new_orders_provider.dart';
import 'package:warungku_app/features/dashboard/presentation/widgets/new_order_card.dart';
import 'package:warungku_app/features/dashboard/presentation/widgets/new_orders_section.dart';
import 'package:warungku_app/features/orders/data/models/order_model.dart';
import 'package:warungku_app/core/theme/app_colors.dart';

// Create a mock notifier extending the real one
class MockNewOrdersNotifier extends NewOrdersNotifier {
  @override
  Future<List<Order>> build() async {
    return [
      Order(
        id: '1',
        code: 'WRG-2023-001',
        customerName: 'John Doe',
        paymentMethod: 'cash',
        deliveryType: 'delivery',
        status: OrderStatus.pending,
        total: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Order(
        id: '2',
        code: 'WRG-2023-002',
        customerName: 'Jane Smith',
        paymentMethod: 'qris',
        deliveryType: 'pickup',
        status: OrderStatus.paid,
        total: 75000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

class EmptyNewOrdersNotifier extends NewOrdersNotifier {
  @override
  Future<List<Order>> build() async {
    return [];
  }
}

void main() {
  group('NewOrdersSection Widget Test', () {
    testWidgets('displays header correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newOrdersProvider.overrideWith(MockNewOrdersNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NewOrdersSection(),
            ),
          ),
        ),
      );

      // Need to wait for async provider to build
      await tester.pump();
      
      expect(find.text('Pesanan Baru'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count
      expect(find.text('Lihat Semua'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('displays order cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newOrdersProvider.overrideWith(MockNewOrdersNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NewOrdersSection(),
            ),
          ),
        ),
      );

      await tester.pump();
      
      expect(find.byType(NewOrderCard), findsNWidgets(2));
      expect(find.text('WRG-2023-001'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    });
    
    testWidgets('displays empty state when no orders', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newOrdersProvider.overrideWith(EmptyNewOrdersNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NewOrdersSection(),
            ),
          ),
        ),
      );

      await tester.pump();
      
      expect(find.text('📭 Belum ada pesanan baru'), findsOneWidget);
      expect(find.byType(NewOrderCard), findsNothing);
    });
  });
}
