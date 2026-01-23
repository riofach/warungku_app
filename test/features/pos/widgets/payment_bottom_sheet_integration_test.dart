import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/presentation/widgets/payment_bottom_sheet.dart';
import 'package:warungku_app/features/pos/presentation/widgets/qris_payment_section.dart';
import 'package:warungku_app/features/pos/presentation/widgets/cash_payment_section.dart';

void main() {
  group('PaymentBottomSheet Integration Tests', () {
    testWidgets('should switch from Cash to QRIS payment method',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Initially should show CashPaymentSection
      expect(find.byType(CashPaymentSection), findsOneWidget);
      expect(find.byType(QrisPaymentSection), findsNothing);

      // Act - Tap QRIS tab
      final qrisTab = find.text('QRIS');
      await tester.tap(qrisTab);
      await tester.pumpAndSettle();

      // Assert - Should show QrisPaymentSection
      expect(find.byType(CashPaymentSection), findsNothing);
      expect(find.byType(QrisPaymentSection), findsOneWidget);
    });

    testWidgets('should switch from QRIS to Cash payment method',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Switch to QRIS first
      final qrisTab = find.text('QRIS');
      await tester.tap(qrisTab);
      await tester.pumpAndSettle();

      // Verify QRIS is shown
      expect(find.byType(QrisPaymentSection), findsOneWidget);

      // Act - Switch back to Cash
      final cashTab = find.text('Tunai');
      await tester.tap(cashTab);
      await tester.pumpAndSettle();

      // Assert - Should show CashPaymentSection
      expect(find.byType(CashPaymentSection), findsOneWidget);
      expect(find.byType(QrisPaymentSection), findsNothing);
    });

    testWidgets('should display both payment tabs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('QRIS'), findsOneWidget);
    });
  });
}
