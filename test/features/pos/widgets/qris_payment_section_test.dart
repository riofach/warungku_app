import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/presentation/widgets/qris_payment_section.dart';

void main() {
  group('QrisPaymentSection Widget Tests', () {
    testWidgets('should render QrisPaymentSection correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QrisPaymentSection(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(QrisPaymentSection), findsOneWidget);
    });

    testWidgets('should display QR code image from assets',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QrisPaymentSection(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      // Look for Image widget with the correct asset path
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/qris-warung.jpeg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display "Pembayaran Diterima" button',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QrisPaymentSection(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('Pembayaran Diterima'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('should trigger callback when "Pembayaran Diterima" tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QrisPaymentSection(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Act
      final button = find.text('Pembayaran Diterima');
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Assert
      // Should show placeholder SnackBar (Story 4.5 will complete this)
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Pembayaran berhasil dikonfirmasi'),
        findsOneWidget,
      );
    });

    testWidgets('should display total amount label',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QrisPaymentSection(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('Total Pembayaran'), findsOneWidget);
    });
  });
}
