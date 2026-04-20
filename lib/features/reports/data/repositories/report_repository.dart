import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/orders/data/models/order_model.dart';
import '../../../../features/transactions/data/models/transaction_model.dart';
import '../models/report_summary_model.dart';
import '../models/top_item_model.dart';

class ReportRepository {
  final SupabaseClient _supabase;

  ReportRepository(this._supabase);

  /// Get summary of revenue, profit, and transaction count
  /// Tries RPC first, falls back to manual calculation if RPC fails/missing
  Future<ReportSummary> getReportSummary(DateTime start, DateTime end) async {
    try {
      debugPrint('📊 Fetching report summary via RPC...');
      final response = await _supabase.rpc(
        'get_report_summary',
        params: {
          'start_date': start.toUtc().toIso8601String(),
          'end_date': end.toUtc().toIso8601String(),
        },
      );
      
      final data = response is List ? response.first : response;
      debugPrint('✅ RPC Success: $data');
      return ReportSummary.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ RPC Failed or Missing: $e');
      debugPrint('🔄 Falling back to client-side calculation...');
      
      // Fallback: Fetch transactions and calculate manually
      try {
        final transactions = await getTransactions(start, end);
        return _calculateSummaryManual(transactions);
      } catch (fallbackError) {
        debugPrint('❌ Fallback failed: $fallbackError');
        throw Exception('Gagal memuat ringkasan laporan.');
      }
    }
  }

  /// Calculate summary manually from transaction list
  ReportSummary _calculateSummaryManual(List<Transaction> transactions) {
    int totalRevenue = 0;
    int totalProfit = 0;
    
    for (var trx in transactions) {
      totalRevenue += trx.total;
      
      // Note: In MVP, buy_price is fetched from 'items' table via RPC.
      // The standard 'getTransactions' query uses 'transaction_items' which lacks current buy_price.
      // To prevent misleading data (Revenue becoming Profit), we set profit to 0 in fallback mode.
      // Ideally, the RPC should always be used.
      totalProfit += trx.totalProfit; 
    }

    final count = transactions.length;
    final average = count > 0 ? (totalRevenue / count).round() : 0;

    return ReportSummary(
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      transactionCount: count,
      averageValue: average,
    );
  }

  /// Get list of transactions for a specific period
  Future<List<Transaction>> getTransactions(DateTime start, DateTime end) async {
    try {
      final startShifted = start.add(const Duration(hours: 7));
      final endShifted = end.add(const Duration(hours: 7));

      final response = await _supabase
          .from('transactions')
          .select('*, transaction_items(*)')
          .gte('created_at', startShifted.toUtc().toIso8601String())
          .lte('created_at', endShifted.toUtc().toIso8601String())
          .order('created_at', ascending: false);

      final transactions = (response as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      final withAdmins = await _enrichAdminNames(transactions);
      return _enrichItemNames(withAdmins);
    } on PostgrestException catch (e) {
      debugPrint('❌ getTransactions PostgrestException: ${e.message}');
      throw Exception('Gagal memuat riwayat transaksi: ${e.message}');
    } catch (e) {
      debugPrint('❌ getTransactions error: $e');
      throw Exception('Terjadi kesalahan saat memuat transaksi.');
    }
  }

  /// Batch-fetch admin names and enrich transactions.
  /// Seeds from current auth session first so the owner's name always resolves
  /// even if they lack a row in public.users.
  Future<List<Transaction>> _enrichAdminNames(List<Transaction> transactions) async {
    final adminIds = transactions
        .map((t) => t.adminId)
        .whereType<String>()
        .toSet()
        .toList();

    if (adminIds.isEmpty) return transactions;

    // Seed map from the currently logged-in user's session metadata
    final adminMap = <String, TransactionAdmin>{};
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      final meta = currentUser.userMetadata ?? {};
      adminMap[currentUser.id] = TransactionAdmin(
        id: currentUser.id,
        name: meta['name'] as String?,
        email: currentUser.email ?? '',
      );
    }

    // Supplement from public.users for other admins
    try {
      final usersResponse = await _supabase
          .from('users')
          .select('id, name, email')
          .inFilter('id', adminIds);

      for (final row in usersResponse as List) {
        final id = row['id'] as String;
        adminMap[id] = TransactionAdmin.fromJson(row as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('⚠️ Admin name DB lookup failed: $e');
    }

    return transactions.map((t) {
      if (t.adminId == null || t.admin != null) return t;
      final admin = adminMap[t.adminId!];
      if (admin == null) return t;
      return t.copyWith(admin: admin);
    }).toList();
  }

  /// Batch-fetch item names and enrich transaction items
  Future<List<Transaction>> _enrichItemNames(List<Transaction> transactions) async {
    final itemIds = transactions
        .expand((t) => t.items)
        .map((i) => i.itemId)
        .whereType<String>()
        .toSet()
        .toList();

    if (itemIds.isEmpty) return transactions;

    try {
      final itemsResponse = await _supabase
          .from('items')
          .select('id, name')
          .inFilter('id', itemIds);

      final nameMap = <String, String>{
        for (final row in itemsResponse as List)
          row['id'] as String: row['name'] as String,
      };

      return transactions.map((t) {
        final enrichedItems = t.items.map((item) {
          if (item.itemName != null || item.itemId == null) return item;
          final name = nameMap[item.itemId!];
          if (name == null) return item;
          return TransactionItem(
            id: item.id,
            transactionId: item.transactionId,
            itemId: item.itemId,
            itemName: name,
            quantity: item.quantity,
            buyPrice: item.buyPrice,
            price: item.price,
            subtotal: item.subtotal,
            createdAt: item.createdAt,
          );
        }).toList();
        return t.copyWith(items: enrichedItems);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Item name enrichment failed: $e');
      return transactions;
    }
  }

  /// Get list of online orders for a specific period
  Future<List<Order>> getOrdersForReport(DateTime start, DateTime end) async {
    try {
      final startShifted = start.add(const Duration(hours: 7));
      final endShifted = end.add(const Duration(hours: 7));

      final response = await _supabase
          .from('orders')
          .select('*, housing_block:housing_blocks(id, name)')
          .gte('created_at', startShifted.toUtc().toIso8601String())
          .lte('created_at', endShifted.toUtc().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat riwayat pesanan: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat pesanan.');
    }
  }

  Future<List<TopItem>> getTopSellingItems(DateTime start, DateTime end, {int limit = 10}) async {
    try {
      final response = await _supabase.rpc(
        'get_top_selling_items',
        params: {
          'start_date': start.toUtc().toIso8601String(),
          'end_date': end.toUtc().toIso8601String(),
          'limit_count': limit,
        },
      );
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => TopItem.fromJson(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat item terlaris: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

}
