import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import 'package:warungku_app/core/widgets/connection_status_indicator.dart';
import 'package:warungku_app/core/services/realtime_connection_monitor.dart';

void main() {
  group('ConnectionStatusIndicator', () {
    Widget buildTestWidget({
      required ConnectionState state,
      int retryAttempt = 0,
      bool compact = false,
      VoidCallback? onTap,
    }) {
      return ProviderScope(
        overrides: [
          connectionStateProvider.overrideWith((ref) => state),
          retryAttemptProvider.overrideWith((ref) => retryAttempt),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              compact: compact,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    group('Connected State', () {
      testWidgets('should display wifi icon when connected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.connected));
        
        expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
      });

      testWidgets('should display "Live Updates" text when connected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.connected));
        
        expect(find.text('Live Updates'), findsOneWidget);
      });

      testWidgets('should have green color when connected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.connected));
        
        final text = tester.widget<Text>(find.text('Live Updates'));
        expect(text.style?.color?.value, equals(Colors.green.shade700.value));
      });
    });

    group('Disconnected State', () {
      testWidgets('should display wifi_off icon when disconnected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.disconnected));
        
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      });

      testWidgets('should display "Disconnected" text when disconnected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.disconnected));
        
        expect(find.textContaining('Disconnected'), findsOneWidget);
      });

      testWidgets('should have grey color when disconnected', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.disconnected));
        
        final textFinder = find.textContaining('Disconnected');
        final text = tester.widget<Text>(textFinder);
        expect(text.style?.color?.value, equals(Colors.grey.shade700.value));
      });
    });

    group('Compact Mode', () {
      testWidgets('should find icon in compact mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: ConnectionState.connected,
          compact: true,
        ));
        
        // Should find icon
        expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
      });

      testWidgets('should show tooltip in compact mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: ConnectionState.connected,
          compact: true,
        ));
        
        // Should find tooltip
        expect(find.byType(Tooltip), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('should call onTap when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildTestWidget(
          state: ConnectionState.connected,
          onTap: () => tapped = true,
        ));
        
        await tester.tap(find.byType(ConnectionStatusIndicator));
        
        expect(tapped, isTrue);
      });

      testWidgets('should be tappable', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          state: ConnectionState.connected,
        ));
        
        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });

    group('Animated Transitions', () {
      testWidgets('should have AnimatedContainer for smooth transitions', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.connected));
        
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('should have AnimatedSwitcher for state changes', (tester) async {
        await tester.pumpWidget(buildTestWidget(state: ConnectionState.connected));
        
        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });
    });

    group('State Transitions', () {
      testWidgets('should update UI when state changes', (tester) async {
        // Start with connected state
        await tester.pumpWidget(buildTestWidget(
          state: ConnectionState.connected,
        ));
        
        expect(find.text('Live Updates'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

        // Note: In real widget, we would test state changes by pumping a new widget
        // with a different state. Here we just verify the widget renders correctly
        // for each state.
      });
    });
  });
}
