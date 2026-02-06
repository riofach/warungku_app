import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_settings_model.dart';
import '../../data/providers/settings_provider.dart';
import '../../../../core/constants/app_constants.dart';

class DeliverySettingsNotifier extends AsyncNotifier<DeliverySettingsModel> {
  @override
  FutureOr<DeliverySettingsModel> build() async {
    return _loadSettings();
  }

  Future<DeliverySettingsModel> _loadSettings() async {
    final repository = ref.read(settingsRepositoryProvider);
    
    // Load enabled state
    final enabledStr = await repository.getSetting(AppConstants.settingDeliveryEnabled);
    final isEnabled = enabledStr == 'true';

    // Load whatsapp number
    final number = await repository.getSetting(AppConstants.settingWhatsappNumber);
    
    return DeliverySettingsModel(
      isDeliveryEnabled: isEnabled,
      whatsappNumber: number ?? '',
    );
  }

  /// Toggles delivery status and saves immediately to database
  Future<void> updateDeliveryStatus(bool isEnabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    
    // Optimistic update
    final previousState = state;
    state = AsyncValue.data(state.value!.copyWith(isDeliveryEnabled: isEnabled));

    try {
      await repository.updateSetting(AppConstants.settingDeliveryEnabled, isEnabled.toString());
    } catch (e, stack) {
      // Revert on error
      state = previousState;
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Saves settings (mainly WhatsApp number, but can handle both for legacy reasons if needed)
  /// Now primarily used for the "Simpan" button
  Future<void> saveSettings({required bool isEnabled, required String number}) async {
    final repository = ref.read(settingsRepositoryProvider);
    
    // Update repository
    // We update both just in case, or we could just update the number.
    // Given the UI allows toggling delivery separately now, we should respect the current toggle state passed in
    // or rely on the state. However, the UI passes the values from the form.
    await Future.wait([
      repository.updateSetting(AppConstants.settingDeliveryEnabled, isEnabled.toString()),
      repository.updateSetting(AppConstants.settingWhatsappNumber, number),
    ]);
    
    // Update state
    state = AsyncValue.data(DeliverySettingsModel(
      isDeliveryEnabled: isEnabled,
      whatsappNumber: number,
    ));
  }
}

final deliverySettingsProvider = AsyncNotifierProvider<DeliverySettingsNotifier, DeliverySettingsModel>(() {
  return DeliverySettingsNotifier();
});
