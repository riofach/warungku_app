import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/paginated_history_notifier.dart';
import '../models/purchase_model.dart';
import '../repositories/purchase_repository.dart';

/// Provider for [PurchaseRepository].
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

/// Infinite-scroll controller for the "Riwayat Pembelian" screen — paginates
/// all purchase (restock) records with an optional date range.
class PurchaseHistoryNotifier extends PaginatedHistoryNotifier<Purchase> {
  @override
  Future<List<Purchase>> fetchPage({
    required int limit,
    required int offset,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ref.read(purchaseRepositoryProvider).getPurchases(
          limit: limit,
          offset: offset,
          fromDate: fromDate,
          toDate: toDate,
        );
  }
}

final purchaseHistoryProvider =
    NotifierProvider<PurchaseHistoryNotifier, PaginatedState<Purchase>>(
  PurchaseHistoryNotifier.new,
);
