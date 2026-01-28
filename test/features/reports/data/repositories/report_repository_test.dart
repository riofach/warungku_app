import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/reports/data/models/top_item_model.dart';
import 'package:warungku_app/features/reports/data/repositories/report_repository.dart';

// Mock SupabaseClient
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late ReportRepository repository;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = ReportRepository(mockSupabaseClient);
  });

  group('ReportRepository', () {
    test('getTopSellingItems returns list of TopItem on success', () async {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 1, 31);
      
      // Mock response data from RPC
      final mockData = [
        {
          'item_id': '1',
          'item_name': 'Item A',
          'total_quantity': 100,
          'total_revenue': 1000000
        },
        {
          'item_id': '2',
          'item_name': 'Item B',
          'total_quantity': 50,
          'total_revenue': 500000
        }
      ];

      // Setup mock behavior
      when(() => mockSupabaseClient.rpc(
        'get_top_selling_items',
        params: any(named: 'params'),
      )).thenAnswer((_) async => mockData);

      // Execute
      final result = await repository.getTopSellingItems(startDate, endDate, limit: 5);

      // Verify
      expect(result, isA<List<TopItem>>());
      expect(result.length, 2);
      expect(result.first.itemName, 'Item A');
      expect(result.last.totalQuantity, 50);

      // Verify RPC was called with correct parameters
      verify(() => mockSupabaseClient.rpc(
        'get_top_selling_items',
        params: {
          'start_date': startDate.toUtc().toIso8601String(),
          'end_date': endDate.toUtc().toIso8601String(),
          'limit_count': 5,
        },
      )).called(1);
    });

    test('getTopSellingItems throws exception on error', () async {
      final startDate = DateTime.now();
      final endDate = DateTime.now();

      when(() => mockSupabaseClient.rpc(
        any(),
        params: any(named: 'params'),
      )).thenThrow(const PostgrestException(message: 'RPC Error'));

      expect(
        () => repository.getTopSellingItems(startDate, endDate),
        throwsA(isA<Exception>()),
      );
    });
  });
}
