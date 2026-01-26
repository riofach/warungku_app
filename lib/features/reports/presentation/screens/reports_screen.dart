import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/report_date_display.dart';
import '../widgets/report_filter_section.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const ReportFilterSection(),
          const SizedBox(height: AppSpacing.md),
          const ReportDateDisplay(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Center(
              child: Text(
                'Pilih filter periode untuk melihat laporan',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
