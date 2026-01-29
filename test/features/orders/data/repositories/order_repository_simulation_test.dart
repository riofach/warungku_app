import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';
import 'package:warungku_app/core/constants/supabase_constants.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late OrderRepository repository;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    
    // Default mock behavior for chaining
    // .from() returns SupabaseQueryBuilder (implements Future), use thenAnswer
    when(() => mockSupabase.from(any())).thenAnswer((_) => mockQueryBuilder);
    
    // .update() returns PostgrestFilterBuilder (implements Future), use thenAnswer
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockFilterBuilder);
    
    // .eq() returns PostgrestFilterBuilder (implements Future), use thenAnswer
    when(() => mockFilterBuilder.eq(any(), any())).thenAnswer((_) => mockFilterBuilder);
    
    // .timeout() returns Future<T>, use thenAnswer with async
    when(() => mockFilterBuilder.timeout(any())).thenAnswer((_) async => {});

    repository = OrderRepository(supabase: mockSupabase);
  });

  test('repository can be instantiated', () {
    expect(repository, isNotNull);
  });

  group('updateOrderStatus', () {
    test('should call supabase update with correct parameters', () async {
      // Arrange
      const orderId = 'test-order-id';
      const newStatus = 'processing';

      // Act
      await repository.updateOrderStatus(orderId, newStatus);

      // Assert
      verify(() => mockSupabase.from(SupabaseConstants.tableOrders)).called(1);
      
      // Verify update called with correct data
      final capturedUpdate = verify(() => mockQueryBuilder.update(captureAny())).captured.single;
      final updateData = (capturedUpdate as Map).cast<String, dynamic>();
      expect(updateData[SupabaseConstants.colStatus], newStatus);
      expect(updateData.containsKey('updated_at'), true);
      
      verify(() => mockFilterBuilder.eq(SupabaseConstants.colId, orderId)).called(1);
    });

    test('should throw exception when supabase fails', () async {
      // Arrange
      // Overwrite the default stub for this specific test
      when(() => mockFilterBuilder.timeout(any()))
          .thenThrow(const PostgrestException(message: 'Connection error'));

      // Act & Assert
      expect(
        () => repository.updateOrderStatus('id', 'status'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Gagal memperbarui status'),
        )),
      );
    });
  });
}
