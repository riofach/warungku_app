import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final value = await repository.getSetting('operating_hours');
    
    if (value != null) {
      try {
        final parts = value.split('-');
        if (parts.length == 2) {
          final open = Formatters.parseTimeOfDay(parts[0]);
          final close = Formatters.parseTimeOfDay(parts[1]);
          return OperatingHours(open: open, close: close);
        }
      } catch (e) {
        // Fallback to default on error
      }
    }
    
    // Default values: 08:00 - 21:00
    return const OperatingHours(
      open: TimeOfDay(hour: 8, minute: 0),
      close: TimeOfDay(hour: 21, minute: 0),
    );
  }

  Future<void> saveOperatingHours(TimeOfDay open, TimeOfDay close) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      final openStr = Formatters.formatTimeOfDay(open);
      final closeStr = Formatters.formatTimeOfDay(close);
      final value = '$openStr-$closeStr';
      
      await repository.updateSetting('operating_hours', value);
      
      return OperatingHours(open: open, close: close);
    });
  }
}

final operatingHoursProvider = AsyncNotifierProvider<OperatingHoursNotifier, OperatingHours>(() {
  return OperatingHoursNotifier();
});
