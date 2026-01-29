import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late OrderRepository repository;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = OrderRepository(supabase: mockSupabase);
  });

  test('repository can be instantiated', () {
    expect(repository, isNotNull);
  });
}
