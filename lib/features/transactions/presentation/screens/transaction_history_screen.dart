import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/date_range_filter_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/paginated_list_view.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';
import '../widgets/transaction_detail_sheet.dart';

/// Sales history — "Riwayat Penjualan".
/// Lists all POS transactions (newest first) with infinite-scroll pagination
/// and an optional date-range filter. Tapping a row opens the existing
/// transaction detail bottom sheet.
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesHistoryProvider);
    final notifier = ref.read(salesHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penjualan')),
      body: Column(
        children: [
          DateRangeFilterBar(
            fromDate: state.fromDate,
            toDate: state.toDate,
            onChanged: (range) => _applyRange(notifier, range),
          ),
          Expanded(
            child: PaginatedListView<Transaction>(
              state: state,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
              loadingMessage: 'Memuat transaksi...',
              emptyState: EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: state.hasDateFilter
                    ? 'Tidak ada transaksi'
                    : 'Belum ada transaksi',
                subtitle: state.hasDateFilter
                    ? 'Tidak ada penjualan pada rentang tanggal ini'
                    : 'Transaksi POS akan muncul di sini',
              ),
              itemBuilder: (context, trx) => _TransactionCard(transaction: trx),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRange(SalesHistoryNotifier notifier, DateTimeRange? range) {
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

/// Transaction card widget showing transaction details with admin info (FR5)
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showTransactionDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: code and payment method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.code,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _PaymentMethodBadge(method: transaction.paymentMethod),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Total and time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.formattedTotal,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  Text(
                    transaction.shortDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),

              const Divider(height: AppSpacing.lg),

              // Admin info row (FR5: Track Transactions by Admin)
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    child: Text(
                      transaction.admin?.initials ?? '?',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diproses oleh',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                        Text(
                          transaction.adminName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
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
                      '${transaction.itemCount} item',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
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

  void _showTransactionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => TransactionDetailSheet(
          transaction: transaction,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Payment method badge widget
class _PaymentMethodBadge extends StatelessWidget {
  final String method;

  const _PaymentMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final isQris = method == 'qris';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isQris
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isQris ? Icons.qr_code : Icons.payments_outlined,
            size: 14,
            color: isQris ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            isQris ? 'QRIS' : 'Tunai',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isQris ? AppColors.primary : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
