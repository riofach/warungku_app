import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/widgets/confirmation_dialog.dart';

void main() {
  group('LogoutConfirmationDialog', () {
    testWidgets('should display correct title "Keluar"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      // 'Keluar' appears twice: in title and in confirm button
      // This is expected - title is "Keluar" and confirm button is also "Keluar"
      expect(find.text('Keluar'), findsNWidgets(2));
    });

    testWidgets('should display "Yakin ingin keluar?" message (AC2)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      // This is the exact text required by AC2
      expect(find.text('Yakin ingin keluar?'), findsOneWidget);
    });

    testWidgets('should have Batal and Keluar buttons (AC2)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      // Both buttons should be present
      expect(find.text('Batal'), findsOneWidget);
      // 'Keluar' appears twice: in title and in confirm button
      expect(find.text('Keluar'), findsNWidgets(2));
    });

    testWidgets('should display logout icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationDialog(),
          ),
        ),
      );

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('should return false when Batal is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await LogoutConfirmationDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Yakin ingin keluar?'), findsOneWidget);

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('should return true when Keluar is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await LogoutConfirmationDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Yakin ingin keluar?'), findsOneWidget);

      // Tap the Keluar button (the one in actions, not title)
      // We need to find the TextButton with 'Keluar' text
      final keluarButtons = find.widgetWithText(TextButton, 'Keluar');
      await tester.tap(keluarButtons);
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });

  group('ConfirmationDialog', () {
    testWidgets('should display custom title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Custom Title',
              message: 'Custom message here',
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom message here'), findsOneWidget);
    });

    testWidgets('should use default button labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Test',
              message: 'Test message',
            ),
          ),
        ),
      );

      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya'), findsOneWidget);
    });

    testWidgets('should use custom button labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Test',
              message: 'Test message',
              confirmLabel: 'Confirm',
              cancelLabel: 'Cancel',
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('should display icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Test',
              message: 'Test message',
              icon: Icons.warning,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });

  group('DeleteConfirmationDialog', () {
    testWidgets('should display item name in title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(itemName: 'Barang'),
          ),
        ),
      );

      expect(find.text('Hapus Barang?'), findsOneWidget);
    });

    testWidgets('should display warning message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(itemName: 'Item'),
          ),
        ),
      );

      expect(find.text('Data yang dihapus tidak dapat dikembalikan.'), findsOneWidget);
    });

    testWidgets('should have delete icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteConfirmationDialog(itemName: 'Item'),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
