import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/item_unit_model.dart';
import '../models/purchase_model.dart';

class PurchaseRepository {
  static const Duration _timeout = Duration(seconds: 30);

  /// Create a purchase record and update stock + buy prices via Supabase RPC.
  /// Returns the created [Purchase] plus suggested buy prices per unit.
  ///
  /// [quantityBase] — in the item's base unit (grams for gram items, pcs for pcs items)
  /// [totalCost]   — total purchase cost in Rupiah
  Future<({Purchase purchase, int suggestedBuyPrice, List<Map<String, dynamic>> suggestedPerUnit})>
      createPurchase({
    required String itemId,
    required int quantityBase,
    required int totalCost,
    String? notes,
  }) async {
    try {
      final adminId = SupabaseService.client.auth.currentUser?.id;

      final response = await SupabaseService.client.rpc(
        'create_purchase',
        params: {
          'p_item_id': itemId,
          'p_quantity_base': quantityBase,
          'p_total_cost': totalCost,
          'p_admin_id': adminId,
          'p_notes': notes,
        },
      ).timeout(_timeout);

      final data = response as Map<String, dynamic>;

      final purchase = Purchase(
        id: data['id'] as String,
        itemId: data['item_id'] as String,
        adminId: adminId,
        quantityBase: data['quantity_base'] as int,
        totalCost: data['total_cost'] as int,
        costPerBase: (data['cost_per_base'] as num).toDouble(),
        notes: notes,
        createdAt: DateTime.now(),
      );

      final suggestedBuyPrice =
          (data['suggested_buy_price'] as num?)?.toInt() ?? 0;

      final suggestedPerUnit = (data['suggested_prices_per_unit'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];

      return (
        purchase: purchase,
        suggestedBuyPrice: suggestedBuyPrice,
        suggestedPerUnit: suggestedPerUnit,
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal menyimpan pembelian: $e');
    }
  }

  /// Get all purchase records (newest first), with the item name joined in.
  ///
  /// Supports pagination ([limit]/[offset]) and an optional date range
  /// ([fromDate] inclusive / [toDate] inclusive) for tracking.
  ///
  /// Note: `purchases.admin_id` has no FK to `users`, so the admin name cannot
  /// be embedded here — only the item name (`items(name)`) is joined.
  Future<List<Purchase>> getPurchases({
    int? limit,
    int? offset,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      PostgrestFilterBuilder query = SupabaseService.client
          .from(SupabaseConstants.tablePurchases)
          .select('*, items(name)');

      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      PostgrestTransformBuilder transformQuery =
          query.order('created_at', ascending: false);

      if (limit != null && offset != null) {
        transformQuery = transformQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery.timeout(_timeout);

      return (response as List)
          .map((json) => Purchase.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat riwayat pembelian: $e');
    }
  }

  /// Get purchase history for an item
  Future<List<Purchase>> getPurchasesByItem(String itemId) async {
    try {
      final response = await SupabaseService.client
          .from('purchases')
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false)
          .timeout(_timeout);

      return (response as List)
          .map((json) => Purchase.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat riwayat pembelian: $e');
    }
  }

  // ── Item Unit CRUD ────────────────────────────────────────────────

  Future<List<ItemUnit>> getItemUnits(String itemId) async {
    try {
      final response = await SupabaseService.client
          .from('item_units')
          .select()
          .eq('item_id', itemId)
          .order('quantity_base', ascending: false)
          .timeout(_timeout);

      return (response as List)
          .map((json) => ItemUnit.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat satuan: $e');
    }
  }

  Future<ItemUnit> createItemUnit({
    required String itemId,
    required String label,
    required int quantityBase,
    required int sellPrice,
    int buyPrice = 0,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('item_units')
          .insert({
            'item_id': itemId,
            'label': label,
            'quantity_base': quantityBase,
            'sell_price': sellPrice,
            'buy_price': buyPrice,
            'is_active': true,
          })
          .select()
          .single()
          .timeout(_timeout);

      return ItemUnit.fromJson(response);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal menyimpan satuan: $e');
    }
  }

  Future<ItemUnit> updateItemUnit({
    required String unitId,
    required String label,
    required int quantityBase,
    required int sellPrice,
    required int buyPrice,
    required bool isActive,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('item_units')
          .update({
            'label': label,
            'quantity_base': quantityBase,
            'sell_price': sellPrice,
            'buy_price': buyPrice,
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', unitId)
          .select()
          .single()
          .timeout(_timeout);

      return ItemUnit.fromJson(response);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memperbarui satuan: $e');
    }
  }

  Future<void> deleteItemUnit(String unitId) async {
    try {
      await SupabaseService.client
          .from('item_units')
          .delete()
          .eq('id', unitId)
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal menghapus satuan: $e');
    }
  }
}
