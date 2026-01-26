import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/report_data_provider.dart';
import 'summary_card.dart';

class ReportSummarySection extends ConsumerWidget {
  const ReportSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: summaryAsync.when(
        data: (summary) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: SummaryCard(
                      title: 'Total Omset',
                      value: formatRupiah(summary.totalRevenue),
                      icon: Icons.attach_money,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: SummaryCard(
                      title: 'Total Profit',
                      value: formatRupiah(summary.totalProfit),
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: SummaryCard(
                      title: 'Transaksi',
                      value: summary.transactionCount.toString(),
                      icon: Icons.receipt_long,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: SummaryCard(
                      title: 'Rata-rata',
                      value: formatRupiah(summary.averageValue),
                      icon: Icons.analytics,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => _buildLoadingState(),
        error: (error, _) => Center(
          child: Text(
            'Gagal memuat ringkasan',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: SummaryCard(
                  title: 'Total Omset',
                  value: '-',
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                  isLoading: true,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: SummaryCard(
                  title: 'Total Profit',
                  value: '-',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  isLoading: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: const [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: SummaryCard(
                  title: 'Transaksi',
                  value: '-',
                  icon: Icons.receipt_long,
                  color: AppColors.warning,
                  isLoading: true,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: SummaryCard(
                  title: 'Rata-rata',
                  value: '-',
                  icon: Icons.analytics,
                  color: AppColors.secondary,
                  isLoading: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
