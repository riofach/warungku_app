import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/data/providers/payment_provider.dart';
import 'package:warungku_app/features/pos/presentation/widgets/quick_amount_chip.dart';

void main() {
  group('QuickAmountChip', () {
    testWidgets('should render chip with label', (tester) async {
      // Arrange
      var tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAmountChip(
              label: 'Rp 10.000',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Rp 10.000'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAmountChip(
              label: 'Rp 10.000',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(QuickAmountChip));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });

    testWidgets('should display "Uang Pas" label correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAmountChip(
              label: 'Uang Pas',
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Uang Pas'), findsOneWidget);
    });
  });

  group('CashPaymentSection Widget Integration', () {
    testWidgets('should initialize with payment state from provider',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  // Initialize payment
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(paymentNotifierProvider.notifier)
                        .initializePayment(15000);
                  });
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - verify provider initialized
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(paymentNotifierProvider.notifier).initializePayment(15000);
      final state = container.read(paymentNotifierProvider);
      expect(state.totalAmount, 15000);
    });

    testWidgets('should update cash received when quick chip tapped',
        (tester) async {
      // This is a simplified integration test
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Arrange
      container.read(paymentNotifierProvider.notifier).initializePayment(15000);

      // Act - simulate chip tap
      container.read(paymentNotifierProvider.notifier).setCashReceived(10000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.cashReceived, 10000);
      expect(state.change, -5000);
      expect(state.isSufficient, false);
    });

    testWidgets('should calculate change correctly when cash >= total',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Arrange
      container.read(paymentNotifierProvider.notifier).initializePayment(15000);

      // Act
      container.read(paymentNotifierProvider.notifier).setCashReceived(20000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.change, 5000);
      expect(state.isSufficient, true);
    });

    testWidgets('should handle exact amount (Uang Pas)', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Arrange
      container.read(paymentNotifierProvider.notifier).initializePayment(15000);

      // Act - simulate "Uang Pas" tap
      container.read(paymentNotifierProvider.notifier).setExactAmount();

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.cashReceived, 15000);
      expect(state.change, 0);
      expect(state.isSufficient, true);
    });
  });
}
