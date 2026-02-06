import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/core/constants/app_constants.dart';
import 'package:warungku_app/features/settings/data/models/delivery_settings_model.dart';
import 'package:warungku_app/features/settings/data/repositories/settings_repository.dart';
import 'package:warungku_app/features/settings/data/providers/settings_provider.dart';
import 'package:warungku_app/features/settings/presentation/providers/delivery_settings_provider.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockSettingsRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('DeliverySettingsNotifier', () {
    test('build loads settings from repository', () async {
      // Arrange
      when(() => mockRepository.getSetting(AppConstants.settingDeliveryEnabled))
          .thenAnswer((_) async => 'true');
      when(() => mockRepository.getSetting(AppConstants.settingWhatsappNumber))
          .thenAnswer((_) async => '628123');

      // Act
      final model = await container.read(deliverySettingsProvider.future);

      // Assert
      expect(model.isDeliveryEnabled, true);
      expect(model.whatsappNumber, '628123');
      verify(() => mockRepository.getSetting(AppConstants.settingDeliveryEnabled)).called(1);
      verify(() => mockRepository.getSetting(AppConstants.settingWhatsappNumber)).called(1);
    });

    test('build handles null values (defaults)', () async {
      // Arrange
      when(() => mockRepository.getSetting(any()))
          .thenAnswer((_) async => null);

      // Act
      final model = await container.read(deliverySettingsProvider.future);

      // Assert
      expect(model.isDeliveryEnabled, false); // Default
      expect(model.whatsappNumber, ''); // Default
    });

    test('updateDeliveryStatus updates repository and state immediately', () async {
      // Arrange
      when(() => mockRepository.getSetting(any()))
          .thenAnswer((_) async => null); // Initial load
      
      await container.read(deliverySettingsProvider.future);

      when(() => mockRepository.updateSetting(any(), any()))
          .thenAnswer((_) async {});

      // Act
      await container.read(deliverySettingsProvider.notifier).updateDeliveryStatus(true);

      // Assert
      verify(() => mockRepository.updateSetting(AppConstants.settingDeliveryEnabled, 'true')).called(1);
      // Verify whatsapp update was NOT called
      verifyNever(() => mockRepository.updateSetting(AppConstants.settingWhatsappNumber, any()));

      final state = container.read(deliverySettingsProvider);
      expect(state.value!.isDeliveryEnabled, true);
    });

    test('saveSettings updates repository and state', () async {
       // Arrange
      when(() => mockRepository.getSetting(any()))
          .thenAnswer((_) async => null); // Initial load
      
      // Initialize
      await container.read(deliverySettingsProvider.future);

      when(() => mockRepository.updateSetting(any(), any()))
          .thenAnswer((_) async {});

      // Act
      await container.read(deliverySettingsProvider.notifier).saveSettings(
        isEnabled: true,
        number: '628999',
      );

      // Assert
      verify(() => mockRepository.updateSetting(AppConstants.settingDeliveryEnabled, 'true')).called(1);
      verify(() => mockRepository.updateSetting(AppConstants.settingWhatsappNumber, '628999')).called(1);

      final state = container.read(deliverySettingsProvider);
      expect(state.value!.isDeliveryEnabled, true);
      expect(state.value!.whatsappNumber, '628999');
    });
  });
}
