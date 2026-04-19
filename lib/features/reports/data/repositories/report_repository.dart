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

      return (response as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat riwayat transaksi: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat transaksi.');
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
