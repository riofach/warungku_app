import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/date_range_filter_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/paginated_list_view.dart';
import '../../data/models/purchase_model.dart';
import '../../data/providers/purchase_provider.dart';
import '../widgets/purchase_detail_sheet.dart';

/// Purchase history — "Riwayat Pembelian".
/// Lists all purchase (restock) records (newest first) with infinite-scroll
/// pagination and an optional date-range filter. Tapping a row opens a detail
/// bottom sheet.
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseHistoryProvider);
    final notifier = ref.read(purchaseHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembelian')),
      body: Column(
        children: [
          DateRangeFilterBar(
            fromDate: state.fromDate,
            toDate: state.toDate,
            onChanged: (range) => _applyRange(notifier, range),
          ),
          Expanded(
            child: PaginatedListView<Purchase>(
              state: state,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
              loadingMessage: 'Memuat pembelian...',
              emptyState: EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: state.hasDateFilter
                    ? 'Tidak ada pembelian'
                    : 'Belum ada pembelian',
                subtitle: state.hasDateFilter
                    ? 'Tidak ada pembelian pada rentang tanggal ini'
                    : 'Catatan pembelian & restock akan muncul di sini',
              ),
              itemBuilder: (context, purchase) =>
                  _PurchaseCard(purchase: purchase),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRange(PurchaseHistoryNotifier notifier, DateTimeRange? range) {
    if (range == null) {
      notifier.setDateRange(null, null);
      return;
    }
    final from = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    notifier.setDateRange(from, to);
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;

  const _PurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      purchase.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    purchase.formattedTotalCost,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qty: ${purchase.quantityBase}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Text(
                    purchase.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => PurchaseDetailSheet(
          purchase: purchase,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
