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

  /// Query to select transactions with their line items.
  ///
  /// Admin info and item names are resolved via separate batch lookups
  /// ([_enrichAdminNames] / [_enrichItemNames]) rather than PostgREST embeds:
  /// `transactions.admin_id` has NO foreign key to `users` in the schema, so an
  /// `admin:users!transactions_admin_id_fkey(...)` embed fails with PGRST200.
  static const String _selectWithItems = '''
    *,
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
          .select(_selectWithItems);

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

      final list = (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();

      final withAdmins = await _enrichAdminNames(list);
      return _enrichItemNames(withAdmins);
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
          .select(_selectWithItems)
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      final enriched = await _enrichItemNames(
        await _enrichAdminNames([Transaction.fromJson(response)]),
      );
      return enriched.first;
    } catch (e) {
      debugPrint('Error getting transaction by ID: $e');
      rethrow;
    }
  }

  /// Batch-fetch admin names and enrich transactions.
  ///
  /// `transactions.admin_id` has no FK to `users`, so admin info can't be
  /// embedded via PostgREST. Seed from the current auth session first (so the
  /// logged-in owner resolves even without a `public.users` row), then
  /// supplement from `public.users` for any other admins.
  Future<List<Transaction>> _enrichAdminNames(
      List<Transaction> transactions) async {
    final adminIds = transactions
        .map((t) => t.adminId)
        .whereType<String>()
        .toSet()
        .toList();

    if (adminIds.isEmpty) return transactions;

    final adminMap = <String, TransactionAdmin>{};
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      final meta = currentUser.userMetadata ?? {};
      adminMap[currentUser.id] = TransactionAdmin(
        id: currentUser.id,
        name: meta['name'] as String?,
        email: currentUser.email ?? '',
      );
    }

    try {
      final usersResponse = await _client
          .from('users')
          .select('id, name, email')
          .inFilter('id', adminIds);

      for (final row in usersResponse as List) {
        final id = row['id'] as String;
        adminMap[id] = TransactionAdmin.fromJson(row as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('⚠️ Admin name lookup failed: $e');
    }

    return transactions.map((t) {
      if (t.adminId == null || t.admin != null) return t;
      final admin = adminMap[t.adminId!];
      if (admin == null) return t;
      return t.copyWith(admin: admin);
    }).toList();
  }

  /// Batch-fetch item names and enrich transaction line items.
  ///
  /// `transaction_items` carries no item name (it comes from the `items`
  /// table), so resolve names in one batched lookup keyed by `item_id`.
  Future<List<Transaction>> _enrichItemNames(
      List<Transaction> transactions) async {
    final itemIds = transactions
        .expand((t) => t.items)
        .map((i) => i.itemId)
        .whereType<String>()
        .toSet()
        .toList();

    if (itemIds.isEmpty) return transactions;

    try {
      final itemsResponse = await _client
          .from(SupabaseConstants.tableItems)
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
