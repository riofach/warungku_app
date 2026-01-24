import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/dashboard/presentation/widgets/profit_card.dart';

void main() {
  group('ProfitCard', () {
    testWidgets('should display profit value when visible', (tester) async {
      // Arrange
      const profit = 500000;

      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfitCard(profit: profit),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Profit Hari Ini'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_outlined), findsOneWidget);
    });

    testWidgets('should toggle profit visibility when eye icon tapped',
        (tester) async {
      // Arrange
      const profit = 250000;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfitCard(profit: profit),
            ),
          ),
        ),
      );

      // Initially visible
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Act - Tap eye icon to hide
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Assert - Hidden
      expect(find.text('Rp •••••••'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.text('Rp 250.000'), findsNothing);

      // Act - Tap again to show
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Assert - Visible again
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.text('Rp •••••••'), findsNothing);
    });

    testWidgets('should display zero profit correctly', (tester) async {
      // Arrange
      const profit = 0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfitCard(profit: profit),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Rp 0'), findsOneWidget);
    });

    testWidgets('should handle large profit values correctly',
        (tester) async {
      // Arrange
      const profit = 10000000; // 10 million

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfitCard(profit: profit),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Rp 10.000.000'), findsOneWidget);
      expect(find.text('Profit Hari Ini'), findsOneWidget);

      // Hide and verify
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(find.text('Rp •••••••'), findsOneWidget);
      expect(find.text('Rp 10.000.000'), findsNothing);
    });
  });
}
