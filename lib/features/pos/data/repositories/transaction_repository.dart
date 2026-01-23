import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/transaction_model.dart';
import '../providers/payment_provider.dart';

/// Repository for transaction operations
/// Handles POS transaction creation with atomic stock reduction
class TransactionRepository {
  final SupabaseClient _supabase;

  TransactionRepository(this._supabase);

  /// Create a POS transaction atomically with stock reduction
  /// Calls Supabase RPC function `create_pos_transaction`
  ///
  /// Parameters:
  /// - [items]: List of cart items to be included in transaction
  /// - [paymentMethod]: Cash or QRIS
  /// - [total]: Total transaction amount
  /// - [cashReceived]: Amount of cash received (null for QRIS)
  /// - [changeAmount]: Change to return to customer (null for QRIS)
  ///
  /// Returns created [Transaction] object
  ///
  /// Throws [Exception] if transaction fails
  Future<Transaction> createTransaction({
    required List<CartItem> items,
    required PaymentMethod paymentMethod,
    required int total,
    int? cashReceived,
    int? changeAmount,
  }) async {
    try {
      // Get current admin ID from Supabase Auth
      final adminId = _supabase.auth.currentUser?.id;

      // Convert cart items to JSON array for RPC
      final itemsJson = items.map((cartItem) {
        return {
          'item_id': cartItem.item.id,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity,
          'buy_price': cartItem.item.buyPrice,
          'sell_price': cartItem.item.sellPrice,
          'subtotal': cartItem.subtotal,
        };
      }).toList();

      // Call Supabase RPC function for atomic transaction
      final response = await _supabase.rpc(
        'create_pos_transaction',
        params: {
          'p_admin_id': adminId,
          'p_payment_method': paymentMethod.name,
          'p_total': total,
          'p_items': itemsJson,
          'p_cash_received': cashReceived,
          'p_change_amount': changeAmount,
        },
      );

      // Parse response to Transaction model
      return Transaction.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Database error (e.g., stock insufficient, constraint violation)
      throw Exception('Gagal menyimpan transaksi: ${e.message}');
    } catch (e) {
      // General error (network, parsing, etc.)
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
