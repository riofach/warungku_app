import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/transaction_model.dart';
import '../providers/payment_provider.dart';

class TransactionRepository {
  final SupabaseClient _supabase;

  TransactionRepository(this._supabase);

  Future<Transaction> createTransaction({
    required List<CartItem> items,
    required PaymentMethod paymentMethod,
    required int total,
    int? cashReceived,
    int? changeAmount,
  }) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      final itemsJson = items.map((cartItem) {
        return {
          'item_id': cartItem.item.id,
          'item_name': cartItem.displayName,
          'quantity': cartItem.quantity,
          'buy_price': cartItem.buyPrice,
          'sell_price': cartItem.sellPrice,
          'subtotal': cartItem.subtotal,
          'item_unit_id': cartItem.selectedUnit?.id,
          'quantity_base_used': cartItem.quantityBaseUsed,
        };
      }).toList();

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

      return Transaction.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
