import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/features/settings/data/models/delivery_settings_model.dart';
import 'package:warungku_app/features/settings/presentation/providers/delivery_settings_provider.dart';
import 'package:warungku_app/features/settings/presentation/screens/delivery_settings_screen.dart';

class MockDeliverySettingsNotifier extends AsyncNotifier<DeliverySettingsModel>
    with Mock
    implements DeliverySettingsNotifier {}

void main() {
  late MockDeliverySettingsNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockDeliverySettingsNotifier();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        deliverySettingsProvider.overrideWith(() => mockNotifier),
      ],
      child: const MaterialApp(
        home: DeliverySettingsScreen(),
      ),
    );
  }

  testWidgets('renders correct initial state', (tester) async {
    // Arrange
    when(() => mockNotifier.build()).thenAnswer(
      (_) async => const DeliverySettingsModel(
        isDeliveryEnabled: true,
        whatsappNumber: '628123',
      ),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Delivery & WhatsApp'), findsOneWidget);
    expect(find.text('Aktifkan Delivery'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('628123'), findsOneWidget);
  });

  testWidgets('toggling switch calls updateDeliveryStatus immediately', (tester) async {
    // Arrange
    when(() => mockNotifier.build()).thenAnswer(
      (_) async => const DeliverySettingsModel(
        isDeliveryEnabled: false,
        whatsappNumber: '',
      ),
    );
    when(() => mockNotifier.updateDeliveryStatus(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Toggle switch
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // Verify immediate call
    verify(() => mockNotifier.updateDeliveryStatus(true)).called(1);
  });

  testWidgets('calls saveSettings when valid', (tester) async {
    // Arrange
    when(() => mockNotifier.build()).thenAnswer(
      (_) async => const DeliverySettingsModel(
        isDeliveryEnabled: false,
        whatsappNumber: '',
      ),
    );
    when(() => mockNotifier.saveSettings(isEnabled: any(named: 'isEnabled'), number: any(named: 'number')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Enter valid number
    await tester.enterText(find.byType(TextField), '628123456789');
    await tester.pump();

    // Tap save
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    // Verify save called
    // isEnabled is false (default in this test setup) because we didn't toggle it
    verify(() => mockNotifier.saveSettings(isEnabled: false, number: '628123456789')).called(1);
  });
}
