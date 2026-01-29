import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/order_model.dart';

/// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

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

  /// Get order by ID with full details (items, housing block)
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tableOrders)
          .select('''
            *,
            housing_block:housing_blocks(id, name),
            order_items:order_items(
              *,
              items:items(name, image_url)
            )
          ''')
          .eq(SupabaseConstants.colId, orderId)
          .single()
          .timeout(_timeout);
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: ${e.toString()}');
    }
  }

  /// Get real-time stream of all orders
  Stream<List<Order>> getOrdersStream() {
    return _supabase
        .from(SupabaseConstants.tableOrders)
        .stream(primaryKey: [SupabaseConstants.colId])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Order.fromJson(json)).toList());
  }

  /// Create a dummy order for testing/simulation
  Future<void> createDummyOrder() async {
    // 1. Fetch a real item to ensure FK constraint
    final itemResponse = await _supabase
        .from(SupabaseConstants.tableItems)
        .select('${SupabaseConstants.colId}, ${SupabaseConstants.colSellPrice}, ${SupabaseConstants.colName}')
        .limit(1)
        .maybeSingle();

    if (itemResponse == null) {
      throw Exception('Tidak ada item di database. Tambahkan item terlebih dahulu.');
    }

    final itemId = itemResponse[SupabaseConstants.colId] as String;
    final itemPrice = itemResponse[SupabaseConstants.colSellPrice] as int;
    final itemName = itemResponse[SupabaseConstants.colName] as String;

    // 2. Prepare dummy order data
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // WRG-SIM-12345
    final code = 'WRG-SIM-${timestamp.toString().substring(timestamp.toString().length - 6)}';
    final qty = 1 + (DateTime.now().second % 3); // 1-3 items
    final total = itemPrice * qty;

    // 3. Insert Order
    final orderResponse = await _supabase
        .from(SupabaseConstants.tableOrders)
        .insert({
          SupabaseConstants.colCode: code,
          SupabaseConstants.colCustomerName: 'Simulated User',
          SupabaseConstants.colPaymentMethod: 'qris',
          SupabaseConstants.colDeliveryType: 'delivery',
          SupabaseConstants.colStatus: 'paid', // Trigger "New Order" flow immediately
          SupabaseConstants.colTotal: total,
          // housing_block_id can be null or fetched if needed, keeping simple
        })
        .select()
        .single();

    final orderId = orderResponse[SupabaseConstants.colId] as String;

    // 4. Insert Order Items
    await _supabase.from(SupabaseConstants.tableOrderItems).insert({
      SupabaseConstants.colOrderId: orderId,
      SupabaseConstants.colItemId: itemId,
      'item_name': itemName, // Assuming table has item_name column based on error
      SupabaseConstants.colQuantity: qty,
      SupabaseConstants.colPrice: itemPrice,
      SupabaseConstants.colSubtotal: total,
    });
  }
}
