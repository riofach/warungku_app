import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/order_model.dart';

class OrderRepository {
  final SupabaseClient _supabase;
  final Duration _timeout;

  OrderRepository({
    SupabaseClient? supabase,
    Duration timeout = const Duration(seconds: 10),
  })  : _supabase = supabase ?? Supabase.instance.client,
        _timeout = timeout;

  /// Get new orders (pending or paid)
  Future<List<Order>> getNewOrders({int limit = 5}) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tableOrders)
          .select('''
            *,
            housing_block:housing_blocks(id, name)
          ''')
          .inFilter('status', ['pending', 'paid'])
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      
      return (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
    } catch (e) {
      // Allow specific error handling if needed, but here we just rethrow with message
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
    }
  }
}
