import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/transaction_model.dart';

/// Repository for Transaction data operations
/// Handles CRUD operations and queries for transactions with admin tracking
class TransactionRepository {
  final SupabaseClient _client;

  TransactionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Query to select transactions with admin info (for FR5)
  static const String _selectWithAdmin = '''
    *,
    admin:users!transactions_admin_id_fkey(id, name, email),
    transaction_items(*)
  ''';

  /// Get all transactions with admin info, ordered by created_at descending
  /// Implements FR5: Track which admin created each transaction
  Future<List<Transaction>> getTransactions({
    int? limit,
    int? offset,
    DateTime? fromDate,
    DateTime? toDate,
    String? adminId,
  }) async {
    try {
      // Build query with all filters first, then order and limit
      PostgrestFilterBuilder query = _client
          .from(SupabaseConstants.tableTransactions)
          .select(_selectWithAdmin);

      // Apply date filters
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      // Filter by admin if specified
      if (adminId != null && adminId.isNotEmpty) {
        query = query.eq('admin_id', adminId);
      }

      // Apply ordering and pagination using transform builder
      PostgrestTransformBuilder transformQuery = query.order('created_at', ascending: false);

      if (limit != null && offset != null) {
        // Use range for pagination
        final start = offset;
        final end = offset + limit - 1;
        transformQuery = transformQuery.range(start, end);
      } else if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      final response = await transformQuery;
      
      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      rethrow;
    }
  }

  /// Get a single transaction by ID with admin info
  Future<Transaction?> getTransactionById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.tableTransactions)
          .select(_selectWithAdmin)
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Transaction.fromJson(response);
    } catch (e) {
      debugPrint('Error getting transaction by ID: $e');
      rethrow;
    }
  }

  /// Get transactions for today with admin info
  Future<List<Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getTransactions(
      fromDate: startOfDay,
      toDate: endOfDay,
    );
  }

  /// Get transactions by specific admin
  /// Useful for viewing what each admin has processed
  Future<List<Transaction>> getTransactionsByAdmin(String adminId) async {
    return getTransactions(adminId: adminId);
  }

  /// Get transaction count for today
  Future<int> getTodayTransactionCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from(SupabaseConstants.tableTransactions)
          .select('id')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting today transaction count: $e');
      return 0;
    }
  }

  /// Get today's total revenue (omset)
  Future<int> getTodayOmset() async {
    try {
      final transactions = await getTodayTransactions();
      return transactions.fold<int>(0, (sum, trx) => sum + trx.total);
    } catch (e) {
      debugPrint('Error getting today omset: $e');
      return 0;
    }
  }

  /// Get today's total profit
  Future<int> getTodayProfit() async {
    try {
      final transactions = await getTodayTransactions();
      return transactions.fold<int>(0, (sum, trx) => sum + trx.totalProfit);
    } catch (e) {
      debugPrint('Error getting today profit: $e');
      return 0;
    }
  }

  /// Generate unique transaction code
  /// Format: TRX-YYYYMMDD-XXXX
  Future<String> generateTransactionCode() async {
    try {
      final now = DateTime.now();
      final datePrefix = 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-';

      // Get today's transaction count
      final count = await getTodayTransactionCount();
      final sequence = (count + 1).toString().padLeft(4, '0');

      return '$datePrefix$sequence';
    } catch (e) {
      debugPrint('Error generating transaction code: $e');
      // Fallback to timestamp-based code
      return 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Stream for realtime transaction updates (optional - for dashboard)
  /// Note: Realtime stream doesn't support joins, so admin info is not included.
  /// Use getTransactions() for full data with admin info.
  Stream<List<Transaction>> watchTransactions() {
    return _client
        .from(SupabaseConstants.tableTransactions)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((json) => Transaction.fromJson(json))
            .toList());
  }
}
