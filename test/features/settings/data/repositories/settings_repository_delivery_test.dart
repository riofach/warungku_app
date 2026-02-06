import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/settings/data/repositories/settings_repository.dart';
import 'package:warungku_app/core/constants/app_constants.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

// Fake for awaitable builders
class FakePostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T _result;
  FakePostgrestTransformBuilder(this._result);

  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue, {Function? onError}) async {
    return onValue(_result);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _result;
  FakePostgrestFilterBuilder(this._result);

  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue, {Function? onError}) async {
    return onValue(_result);
  }
}

void main() {
  late SettingsRepository repository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    repository = SettingsRepository(mockSupabaseClient);

    // Default chain
    when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockFilterBuilder);
    when(() => mockFilterBuilder.eq(any(), any())).thenAnswer((_) => mockFilterBuilder);
  });

  group('SettingsRepository (Delivery & WhatsApp)', () {
    test('should update delivery_enabled setting correctly', () async {
      // Arrange
      const key = AppConstants.settingDeliveryEnabled;
      const value = 'true';
      
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      
      when(() => mockQueryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
          .thenAnswer((_) => fakeBuilder);

      // Act
      await repository.updateSetting(key, value);

      // Assert
      final captured = verify(() => mockQueryBuilder.upsert(captureAny(), onConflict: captureAny(named: 'onConflict'))).captured;
      final data = captured[0] as Map<String, dynamic>;
      
      expect(data['key'], key);
      expect(data['value'], value);
    });

    test('should update whatsapp_number setting correctly', () async {
      // Arrange
      const key = AppConstants.settingWhatsappNumber;
      const value = '6281234567890';
      
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      
      when(() => mockQueryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
          .thenAnswer((_) => fakeBuilder);

      // Act
      await repository.updateSetting(key, value);

      // Assert
      final captured = verify(() => mockQueryBuilder.upsert(captureAny(), onConflict: captureAny(named: 'onConflict'))).captured;
      final data = captured[0] as Map<String, dynamic>;
      
      expect(data['key'], key);
      expect(data['value'], value);
    });

    test('should retrieve delivery_enabled setting', () async {
      // Arrange
      const key = AppConstants.settingDeliveryEnabled;
      const expectedValue = 'false';
      final responseData = {
        'id': 'uuid-123',
        'key': key,
        'value': expectedValue,
        'updated_at': DateTime.now().toIso8601String(),
      };

      when(() => mockFilterBuilder.maybeSingle())
          .thenAnswer((_) => FakePostgrestTransformBuilder(responseData));

      // Act
      final result = await repository.getSetting(key);

      // Assert
      expect(result, expectedValue);
      verify(() => mockFilterBuilder.eq('key', key)).called(1);
    });
  });
}
