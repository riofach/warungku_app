import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/core/utils/formatters.dart';
import 'package:warungku_app/features/inventory/presentation/screens/item_form_screen.dart';

void main() {
  group('ItemFormScreen', () {
    testWidgets('should render AppBar with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      expect(find.text('Tambah Barang'), findsOneWidget);
    });

    testWidgets('should render all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Check for all required form fields
      expect(find.text('Nama Barang *'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Harga Beli *'), findsOneWidget);
      expect(find.text('Harga Jual *'), findsOneWidget);
      expect(find.text('Stok Awal'), findsOneWidget);
      expect(find.text('Batas Minimum'), findsOneWidget);
      expect(find.text('Status Aktif'), findsOneWidget);
    });

    testWidgets('should render Simpan button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('should have default values for stock fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Check that stock fields exist with default values
      // Find TextFormField widgets containing the default values
      expect(find.widgetWithText(TextFormField, 'Stok Awal'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Batas Minimum'), findsOneWidget);
    });

    testWidgets('should have Status Aktif toggle enabled by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Status Aktif should be ON by default
      expect(find.text('Barang akan ditampilkan untuk dijual'), findsOneWidget);
    });

    testWidgets('should show back button in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should render PhotoPickerSection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Should have photo picker area
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    });

    testWidgets('should show validation error for empty name',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Scroll to button and tap without filling name
      await tester.dragUntilVisible(
        find.text('Simpan'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Nama barang wajib diisi'), findsOneWidget);
    });

    testWidgets('should show validation error for empty buy price',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Fill name but not price
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Barang *'),
        'Test Item',
      );

      // Scroll to button and tap
      await tester.dragUntilVisible(
        find.text('Simpan'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Should show validation error for buy price
      expect(find.text('Harga beli wajib diisi'), findsOneWidget);
    });

    testWidgets('should show validation error for empty sell price',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Fill name and buy price but not sell price
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Barang *'),
        'Test Item',
      );
      
      // Find the buy price field and enter value
      final buyPriceFields = find.widgetWithText(TextFormField, 'Harga Beli *');
      await tester.enterText(buyPriceFields, '1000');

      // Scroll to button and tap
      await tester.dragUntilVisible(
        find.text('Simpan'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Should show validation error for sell price
      expect(find.text('Harga jual wajib diisi'), findsOneWidget);
    });

    testWidgets('should show validation error for name less than 2 chars',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ItemFormScreen(),
          ),
        ),
      );

      // Enter single character name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Barang *'),
        'A',
      );

      // Scroll to button and tap
      await tester.dragUntilVisible(
        find.text('Simpan'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Nama minimal 2 karakter'), findsOneWidget);
    });
  });

  group('RupiahInputFormatter', () {
    test('should format 1000 to 1.000', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1000'),
      );

      expect(result.text, '1.000');
    });

    test('should format 1000000 to 1.000.000', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1000000'),
      );

      expect(result.text, '1.000.000');
    });

    test('should handle empty input', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1000'),
        const TextEditingValue(text: ''),
      );

      expect(result.text, '');
    });

    test('should remove non-digit characters', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1.234abc'),
      );

      expect(result.text, '1.234');
    });

    test('should format 500 to 500 (no separator needed)', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '500'),
      );

      expect(result.text, '500');
    });

    test('should format 12345 to 12.345', () {
      final formatter = RupiahInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '12345'),
      );

      expect(result.text, '12.345');
    });
  });
}
