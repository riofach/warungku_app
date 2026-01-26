import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../data/providers/report_data_provider.dart';
import 'transaction_list_item.dart';

class TransactionListSection extends ConsumerWidget {
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const TransactionListSection({
    super.key,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(reportTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Tidak ada transaksi pada periode ini',
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: transactions.length,
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return TransactionListItem(
              transaction: transaction,
              onTap: () {
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
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorWidget(
            message: 'Gagal memuat transaksi',
            onRetry: () => ref.invalidate(reportTransactionsProvider),
          ),
        ),
      ),
    );
  }
}
