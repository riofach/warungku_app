import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/settings/data/repositories/settings_repository.dart';

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

  group('SettingsRepository', () {
    test('getSetting should return value when found', () async {
      // Arrange
      const key = 'test_key';
      const expectedValue = 'test_value';
      final responseData = {
        'id': '123',
        'key': key,
        'value': expectedValue,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // return Fake builder that resolves to responseData
      when(() => mockFilterBuilder.maybeSingle())
          .thenAnswer((_) => FakePostgrestTransformBuilder(responseData));

      // Act
      final result = await repository.getSetting(key);

      // Assert
      expect(result, expectedValue);
      verify(() => mockSupabaseClient.from('settings')).called(1);
      verify(() => mockFilterBuilder.eq('key', key)).called(1);
    });

    test('getSetting should return null when not found', () async {
      // Arrange
      const key = 'missing_key';

      when(() => mockFilterBuilder.maybeSingle())
          .thenAnswer((_) => FakePostgrestTransformBuilder(null));

      // Act
      final result = await repository.getSetting(key);

      // Assert
      expect(result, null);
    });

    test('updateSetting should call upsert', () async {
      // Arrange
      const key = 'test_key';
      const value = 'new_value';
      
      // Upsert returns a builder that resolves to a List
      final fakeBuilder = FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
      
      when(() => mockQueryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
          .thenAnswer((_) => fakeBuilder);

      // Act
      await repository.updateSetting(key, value);

      // Assert
      verify(() => mockSupabaseClient.from('settings')).called(1);
      final captured = verify(() => mockQueryBuilder.upsert(captureAny(), onConflict: captureAny(named: 'onConflict'))).captured;
      
      final data = captured[0] as Map<String, dynamic>;
      expect(data['key'], key);
      expect(data['value'], value);
      expect(data['updated_at'], isNotNull);
    });
  });
}
