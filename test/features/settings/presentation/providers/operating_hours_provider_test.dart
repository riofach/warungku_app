import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/core/constants/app_constants.dart';
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
      when(() => repository.getSetting(AppConstants.settingOperatingHoursOpen))
          .thenAnswer((_) async => '09:00');
      when(() => repository.getSetting(AppConstants.settingOperatingHoursClose))
          .thenAnswer((_) async => '22:00');

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final state = await container.read(operatingHoursProvider.future);

      expect(state.open.hour, 9);
      expect(state.open.minute, 0);
      expect(state.close.hour, 22);
      expect(state.close.minute, 0);
    });

    test('saveOperatingHours should update repository and state', () async {
      when(() => repository.getSetting(AppConstants.settingOperatingHoursOpen))
          .thenAnswer((_) async => '08:00');
      when(() => repository.getSetting(AppConstants.settingOperatingHoursClose))
          .thenAnswer((_) async => '21:00');
      when(() => repository.updateSetting(any(), any()))
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      await container.read(operatingHoursProvider.future);

      const newOpen = TimeOfDay(hour: 7, minute: 30);
      const newClose = TimeOfDay(hour: 20, minute: 0);

      await container.read(operatingHoursProvider.notifier).saveOperatingHours(newOpen, newClose);

      verify(() => repository.updateSetting(AppConstants.settingOperatingHoursOpen, '07:30')).called(1);
      verify(() => repository.updateSetting(AppConstants.settingOperatingHoursClose, '20:00')).called(1);

      final newState = container.read(operatingHoursProvider).value;
      expect(newState?.open, newOpen);
      expect(newState?.close, newClose);
    });

    test('build should use defaults when repository returns null', () async {
      when(() => repository.getSetting(AppConstants.settingOperatingHoursOpen))
          .thenAnswer((_) async => null);
      when(() => repository.getSetting(AppConstants.settingOperatingHoursClose))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final state = await container.read(operatingHoursProvider.future);

      expect(state.open, const TimeOfDay(hour: 8, minute: 0));
      expect(state.close, const TimeOfDay(hour: 21, minute: 0));
    });
  });
}
