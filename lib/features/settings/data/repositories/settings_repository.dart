import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final SupabaseClient _supabase;

  SettingsRepository(this._supabase);

  /// Get setting value by key. Returns null if not found.
  Future<String?> getSetting(String key) async {
    try {
      final response = await _supabase
          .from('settings')
          .select()
          .eq('key', key)
          .maybeSingle();

      if (response == null) return null;
      return SettingsModel.fromJson(response).value;
    } catch (e) {
      // Let the controller handle the error
      rethrow;
    }
  }

  /// Update or create setting
  Future<void> updateSetting(String key, String value) async {
    await _supabase.from('settings').upsert(
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'key',
    );
  }
}
