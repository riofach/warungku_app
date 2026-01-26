import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/report_filter_provider.dart';

class ReportFilterSection extends ConsumerWidget {
  const ReportFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(reportFilterProvider).period;
    final notifier = ref.read(reportFilterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Hari Ini',
              isSelected: currentPeriod == ReportPeriod.today,
              onSelected: (selected) {
                if (selected) notifier.setPeriod(ReportPeriod.today);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Minggu Ini',
              isSelected: currentPeriod == ReportPeriod.week,
              onSelected: (selected) {
                if (selected) notifier.setPeriod(ReportPeriod.week);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Bulan Ini',
              isSelected: currentPeriod == ReportPeriod.month,
              onSelected: (selected) {
                if (selected) notifier.setPeriod(ReportPeriod.month);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Custom',
              isSelected: currentPeriod == ReportPeriod.custom,
              onSelected: (selected) async {
                if (selected) {
                  final initialDateRange = ref.read(reportFilterProvider).dateRange;
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: initialDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (result != null) {
                    notifier.setCustomRange(result);
                  } else if (currentPeriod != ReportPeriod.custom) {
                    // If cancelled and not already custom, don't change anything
                    // But if it was switching TO custom, we might want to stay on previous
                    // However, chip onSelected is triggered.
                    // If we want to strictly follow AC "If admin cancels the picker, the previous filter remains active."
                    // Since we haven't set the period yet, doing nothing here preserves the previous state.
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}
