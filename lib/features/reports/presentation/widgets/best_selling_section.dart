import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/providers/report_data_provider.dart';
import 'top_item_card.dart';

class BestSellingSection extends ConsumerWidget {
  const BestSellingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topItemsState = ref.watch(topSellingItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Barang Terlaris',
            style: AppTypography.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        topItemsState.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Belum ada data penjualan',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return TopItemCard(
                  item: items[index],
                  rank: index + 1,
                );
              },
            );
          },
          loading: () => _buildShimmer(),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppErrorWidget(
              message: 'Gagal memuat data',
              details: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.refresh(topSellingItemsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: List.generate(3, (index) => 
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          )
        ),
      ),
    );
  }
}
