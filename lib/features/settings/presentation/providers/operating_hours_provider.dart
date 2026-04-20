import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/core/constants/app_constants.dart';
import 'package:warungku_app/core/utils/formatters.dart';
import '../../data/providers/settings_provider.dart';

class OperatingHours {
  final TimeOfDay open;
  final TimeOfDay close;

  const OperatingHours({required this.open, required this.close});
}

class OperatingHoursNotifier extends AsyncNotifier<OperatingHours> {
  @override
  Future<OperatingHours> build() async {
    return _loadOperatingHours();
  }

  Future<OperatingHours> _loadOperatingHours() async {
    final repository = ref.read(settingsRepositoryProvider);
    final openValue = await repository.getSetting(AppConstants.settingOperatingHoursOpen);
    final closeValue = await repository.getSetting(AppConstants.settingOperatingHoursClose);

    try {
      final open = openValue != null ? Formatters.parseTimeOfDay(openValue) : const TimeOfDay(hour: 8, minute: 0);
      final close = closeValue != null ? Formatters.parseTimeOfDay(closeValue) : const TimeOfDay(hour: 21, minute: 0);
      return OperatingHours(open: open, close: close);
    } catch (e) {
      // Fallback to default on error
    }

    return const OperatingHours(
      open: TimeOfDay(hour: 8, minute: 0),
      close: TimeOfDay(hour: 21, minute: 0),
    );
  }

  Future<void> saveOperatingHours(TimeOfDay open, TimeOfDay close) async {
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final openStr = Formatters.formatTimeOfDay(open);
      final closeStr = Formatters.formatTimeOfDay(close);

      await repository.updateSetting(AppConstants.settingOperatingHoursOpen, openStr);
      await repository.updateSetting(AppConstants.settingOperatingHoursClose, closeStr);

      state = AsyncValue.data(OperatingHours(open: open, close: close));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final operatingHoursProvider = AsyncNotifierProvider<OperatingHoursNotifier, OperatingHours>(() {
  return OperatingHoursNotifier();
});
