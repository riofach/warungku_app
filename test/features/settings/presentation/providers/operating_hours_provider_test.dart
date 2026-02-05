import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/features/settings/data/repositories/settings_repository.dart';
import 'package:warungku_app/features/settings/data/providers/settings_provider.dart';
import 'package:warungku_app/features/settings/presentation/providers/operating_hours_provider.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  group('OperatingHoursProvider', () {
    test('build should load from repository and parse correctly', () async {
      when(() => repository.getSetting('operating_hours'))
          .thenAnswer((_) async => '09:00-22:00');

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Read the provider
      final state = await container.read(operatingHoursProvider.future);

      expect(state.open.hour, 9);
      expect(state.open.minute, 0);
      expect(state.close.hour, 22);
      expect(state.close.minute, 0);
    });

    test('saveOperatingHours should update repository and state', () async {
      when(() => repository.getSetting('operating_hours'))
          .thenAnswer((_) async => '08:00-21:00');
      when(() => repository.updateSetting(any(), any()))
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Wait for init
      await container.read(operatingHoursProvider.future);

      // Save new hours
      const newOpen = TimeOfDay(hour: 7, minute: 30);
      const newClose = TimeOfDay(hour: 20, minute: 0);
      
      await container.read(operatingHoursProvider.notifier).saveOperatingHours(newOpen, newClose);

      // Verify repository called
      verify(() => repository.updateSetting('operating_hours', '07:30-20:00')).called(1);
      
      // Verify state updated
      final newState = container.read(operatingHoursProvider).value;
      expect(newState?.open, newOpen);
      expect(newState?.close, newClose);
    });
  });
}
