import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/report_filter_provider.dart';

class ReportDateDisplay extends ConsumerStatefulWidget {
  const ReportDateDisplay({super.key});

  @override
  ConsumerState<ReportDateDisplay> createState() => _ReportDateDisplayState();
}

class _ReportDateDisplayState extends ConsumerState<ReportDateDisplay> {
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportFilterProvider);
    final range = state.dateRange;
    final start = range.start;
    final end = range.end;

    // Check if same day
    final isSameDay = start.year == end.year && 
                      start.month == end.month && 
                      start.day == end.day;

    String text;
    if (isSameDay) {
      text = DateFormat('dd MMMM yyyy', 'id_ID').format(start);
    } else {
      text = '${_formatDate(start)} - ${_formatDate(end)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
