import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class GreetingHeader extends StatelessWidget {
  final String name;

  const GreetingHeader({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Format: "Jumat, 24 Januari 2026"
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $name! 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
