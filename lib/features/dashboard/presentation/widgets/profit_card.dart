import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

class ProfitCard extends StatefulWidget {
  final int profit;

  const ProfitCard({
    super.key,
    required this.profit,
  });

  @override
  State<ProfitCard> createState() => _ProfitCardState();
}

class _ProfitCardState extends State<ProfitCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.trending_up_outlined,
                  color: AppColors.success,
                  size: 28,
                ),
                IconButton(
                  icon: Icon(
                    _isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isVisible = !_isVisible),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Profit Hari Ini',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isVisible ? Formatters.formatRupiah(widget.profit) : 'Rp •••••••',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isVisible ? null : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
