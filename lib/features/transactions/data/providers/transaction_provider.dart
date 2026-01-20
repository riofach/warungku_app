import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

/// Constants for transaction pagination
class TransactionConstants {
  TransactionConstants._();
  
  static const int defaultPageLimit = 20;
  static const int maxFetchLimit = 100;
}

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Provider to get all transactions with admin info
/// Implements FR5: Shows which admin made each transaction
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions(limit: TransactionConstants.maxFetchLimit);
});

/// Provider to get today's transactions
final todayTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTodayTransactions();
});

/// Provider to get a single transaction by ID
final transactionByIdProvider = FutureProvider.family<Transaction?, String>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionById(id);
});

/// Provider to get transactions filtered by admin ID
/// Useful for seeing which admin processed which transactions
final transactionsByAdminProvider = FutureProvider.family<List<Transaction>, String>((ref, adminId) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionsByAdmin(adminId);
});

/// Provider for today's transaction count
final todayTransactionCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTodayTransactionCount();
});

/// Provider for today's omset (revenue)
final todayOmsetProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTodayOmset();
});

/// Provider for today's profit
final todayProfitProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTodayProfit();
});

/// State class for filtered transactions
class TransactionFilterState {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? adminId;
  final int limit;
  final int offset;

  const TransactionFilterState({
    this.fromDate,
    this.toDate,
    this.adminId,
    this.limit = TransactionConstants.defaultPageLimit,
    this.offset = 0,
  });

  TransactionFilterState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? adminId,
    int? limit,
    int? offset,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearAdminId = false,
  }) {
    return TransactionFilterState(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      adminId: clearAdminId ? null : (adminId ?? this.adminId),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilterState &&
          runtimeType == other.runtimeType &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          adminId == other.adminId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      fromDate.hashCode ^
      toDate.hashCode ^
      adminId.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

/// Notifier for managing transaction filters using Riverpod 3.x style
class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() {
    return const TransactionFilterState();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      fromDate: from,
      toDate: to,
      clearFromDate: from == null,
      clearToDate: to == null,
    );
  }

  void setAdminFilter(String? adminId) {
    state = state.copyWith(
      adminId: adminId,
      clearAdminId: adminId == null,
    );
  }

  void nextPage() {
    state = state.copyWith(offset: state.offset + state.limit);
  }

  void previousPage() {
    if (state.offset >= state.limit) {
      state = state.copyWith(offset: state.offset - state.limit);
    }
  }

  void resetFilters() {
    state = const TransactionFilterState();
  }
}

/// Provider for transaction filter state
final transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(() {
  return TransactionFilterNotifier();
});

/// Provider for filtered transactions
final filteredTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);
  
  return repo.getTransactions(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    adminId: filter.adminId,
    limit: filter.limit,
    offset: filter.offset,
  );
});
