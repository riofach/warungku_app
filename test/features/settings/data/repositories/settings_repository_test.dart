import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/settings/data/repositories/settings_repository.dart';

// Mock Supabase Client
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late SettingsRepository repository;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = SettingsRepository(mockSupabaseClient);
  });

  group('SettingsRepository', () {
    test('methods exist', () {
      expect(repository.getSetting, isNotNull);
      expect(repository.updateSetting, isNotNull);
    });
  });
}
