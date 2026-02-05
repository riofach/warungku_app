import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/features/settings/presentation/providers/operating_hours_provider.dart';
import 'package:warungku_app/features/settings/presentation/screens/operating_hours_screen.dart';

class MockOperatingHoursNotifier extends AsyncNotifier<OperatingHours>
    with Mock
    implements OperatingHoursNotifier {}

void main() {
  late MockOperatingHoursNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockOperatingHoursNotifier();
    when(() => mockNotifier.build()).thenAnswer(
      (_) async => const OperatingHours(
        open: TimeOfDay(hour: 8, minute: 0),
        close: TimeOfDay(hour: 21, minute: 0),
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        operatingHoursProvider.overrideWith(() => mockNotifier),
      ],
      child: const MaterialApp(
        home: OperatingHoursScreen(),
      ),
    );
  }

  testWidgets('renders correct title and fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Jam Operasional'), findsOneWidget);
    expect(find.text('Jam Buka'), findsOneWidget);
    expect(find.text('Jam Tutup'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
  });
}
