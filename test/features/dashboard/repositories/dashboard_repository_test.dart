import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/dashboard/data/models/dashboard_summary.dart';
import 'package:warungku_app/features/dashboard/data/repositories/dashboard_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final Future<T> _future;

  FakePostgrestFilterBuilder(this._future);

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  late DashboardRepository repository;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = DashboardRepository(mockSupabase);
  });

  group('DashboardRepository', () {
    test('getTodaySummary should return DashboardSummary when RPC call is successful', () async {
      // Arrange
      final mockResponse = {
        'omset': 1000000,
        'profit': 250000,
        'transaction_count': 10,
        'date': '2026-01-24',
      };

      when(() => mockSupabase.rpc(any(), params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(Future.value(mockResponse)));

      // Act
      final result = await repository.getTodaySummary();

      // Assert
      expect(result, isA<DashboardSummary>());
      expect(result.omset, 1000000);
      expect(result.profit, 250000);
      expect(result.transactionCount, 10);
      verify(() => mockSupabase.rpc('get_dashboard_summary')).called(1);
    });

    test('getTodaySummary should throw Exception with Indonesian message on PostgrestException', () async {
      // Arrange
      final exception = const PostgrestException(message: 'Database error');
      when(() => mockSupabase.rpc(any(), params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(Future.error(exception)));

      // Act & Assert
      expect(
        repository.getTodaySummary(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Gagal memuat data dashboard'))),
      );
    });

    test('getTodaySummary should throw general Exception on unknown error', () async {
      // Arrange
      final exception = Exception('Unknown error');
      when(() => mockSupabase.rpc(any(), params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(Future.error(exception)));

      // Act & Assert
      expect(
        repository.getTodaySummary(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Terjadi kesalahan'))),
      );
    });
  });
}
