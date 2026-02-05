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
    // Don't set state to loading to avoid rebuilding the UI with a loading spinner
    // instead, we return the Future and let the UI handle the loading state (e.g. on the button)
    
    // Optimistic update or wait for result? 
    // Let's wait for result to ensure DB is updated.
    
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final openStr = Formatters.formatTimeOfDay(open);
      final closeStr = Formatters.formatTimeOfDay(close);
      final value = '$openStr-$closeStr';
      
      await repository.updateSetting('operating_hours', value);
      
      // Update state with new values only after success
      state = AsyncValue.data(OperatingHours(open: open, close: close));
    } catch (e, stack) {
      // If error, we can optionally update state to error, but usually 
      // for form submissions we just throw so UI can show snackbar
      // and keep the form data visible.
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final operatingHoursProvider = AsyncNotifierProvider<OperatingHoursNotifier, OperatingHours>(() {
  return OperatingHoursNotifier();
});
