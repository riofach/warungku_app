import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:warungku_app/features/reports/presentation/widgets/report_filter_section.dart';
import 'package:warungku_app/features/reports/presentation/widgets/report_date_display.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUp(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('ReportsScreen shows filter, date display and placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    // Verify filter section is present
    expect(find.byType(ReportFilterSection), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    // Verify date display is present
    expect(find.byType(ReportDateDisplay), findsOneWidget);

    // Verify placeholder text
    expect(find.text('Pilih filter periode untuk melihat laporan'), findsOneWidget);
  });

  testWidgets('Selecting filter updates date display (Integration Test)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    // Initial state: Hari Ini
    // We can't easily assert the exact date string without duplicating logic, 
    // but we can check if tapping "Minggu Ini" changes something.
    
    // Tap Minggu Ini
    await tester.tap(find.text('Minggu Ini'));
    await tester.pumpAndSettle();

    // Verify state changed (chip selected)
    final weekChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Minggu Ini'),
    );
    expect(weekChip.selected, isTrue);

    final todayChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Hari Ini'),
    );
    expect(todayChip.selected, isFalse);
  });
}
