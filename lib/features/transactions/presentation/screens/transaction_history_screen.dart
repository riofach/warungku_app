import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';

/// Transaction History Screen
/// Displays all transactions with admin info (FR5)
class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, ref),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Transaksi POS akan muncul di sini',
              );
            }
            return _TransactionList(transactions: transactions);
          },
          loading: () => const LoadingWidget(message: 'Memuat transaksi...'),
          error: (error, stack) => AppErrorWidget(
            message: 'Gagal memuat transaksi',
            onRetry: () => ref.invalidate(transactionsProvider),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

/// Transaction list widget
class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group transactions by date
    final groupedTransactions = _groupByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final entry = groupedTransactions.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(date: entry.key),
            ...entry.value.map((trx) => _TransactionCard(transaction: trx)),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    for (final trx in transactions) {
      final dateKey = _formatDateKey(trx.createdAt);
      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(trx);
      } else {
        grouped[dateKey] = [trx];
      }
    }
    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hari Ini';
    } else if (transactionDate == yesterday) {
      return 'Kemarin';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Date header for grouped transactions
class _DateHeader extends StatelessWidget {
  final String date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        date,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

/// Transaction card widget showing transaction details with admin info
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
                  // Admin avatar
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
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
                  // Admin name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diproses oleh',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                        ),
                        Text(
                          transaction.adminName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Item count
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
        builder: (context, scrollController) => _TransactionDetailSheet(
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

/// Transaction detail bottom sheet
class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;
  final ScrollController scrollController;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Transaksi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      transaction.code,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                _PaymentMethodBadge(method: transaction.paymentMethod),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Admin info (FR5)
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Diproses oleh',
                  value: transaction.adminName,
                ),
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Waktu',
                  value: transaction.formattedDate,
                ),
                if (transaction.isCash) ...[
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Uang diterima',
                    value: 'Rp ${transaction.cashReceived ?? 0}',
                  ),
                  _DetailRow(
                    icon: Icons.change_circle_outlined,
                    label: 'Kembalian',
                    value: transaction.formattedChange,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Items
                Text(
                  'Item',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (transaction.items.isEmpty)
                  Text(
                    'Detail item tidak tersedia',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ...transaction.items.map((item) => _ItemRow(item: item)),
                const Divider(height: AppSpacing.lg),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      transaction.formattedTotal,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Item row widget for transaction detail
class _ItemRow extends StatelessWidget {
  final TransactionItem item;

  const _ItemRow({required this.item});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${item.quantity} x ${_formatCurrency(item.sellPrice)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.subtotal),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Filter bottom sheet
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transaksi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(transactionFilterProvider.notifier).resetFilters();
                  ref.invalidate(transactionsProvider);
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Periode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: 'Hari Ini',
                selected: _isTodaySelected(filter),
                onSelected: () => _selectToday(ref, context),
              ),
              _FilterChip(
                label: 'Minggu Ini',
                selected: _isThisWeekSelected(filter),
                onSelected: () => _selectThisWeek(ref, context),
              ),
              _FilterChip(
                label: 'Bulan Ini',
                selected: _isThisMonthSelected(filter),
                onSelected: () => _selectThisMonth(ref, context),
              ),
              _FilterChip(
                label: 'Semua',
                selected: filter.fromDate == null && filter.toDate == null,
                onSelected: () {
                  ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
                  ref.invalidate(transactionsProvider);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  bool _isTodaySelected(TransactionFilterState filter) {
    if (filter.fromDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filterDate = DateTime(filter.fromDate!.year, filter.fromDate!.month, filter.fromDate!.day);
    return filterDate == today;
  }

  bool _isThisWeekSelected(TransactionFilterState filter) {
    if (filter.fromDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final filterDate = DateTime(filter.fromDate!.year, filter.fromDate!.month, filter.fromDate!.day);
    return filterDate == DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  bool _isThisMonthSelected(TransactionFilterState filter) {
    if (filter.fromDate == null) return false;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final filterDate = DateTime(filter.fromDate!.year, filter.fromDate!.month, filter.fromDate!.day);
    return filterDate == startOfMonth;
  }

  void _selectToday(WidgetRef ref, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    ref.read(transactionFilterProvider.notifier).setDateRange(today, tomorrow);
    ref.invalidate(transactionsProvider);
    Navigator.pop(context);
  }

  void _selectThisWeek(WidgetRef ref, BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));
    ref.read(transactionFilterProvider.notifier).setDateRange(startDate, endDate);
    ref.invalidate(transactionsProvider);
    Navigator.pop(context);
  }

  void _selectThisMonth(WidgetRef ref, BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    ref.read(transactionFilterProvider.notifier).setDateRange(startOfMonth, endOfMonth);
    ref.invalidate(transactionsProvider);
    Navigator.pop(context);
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}
