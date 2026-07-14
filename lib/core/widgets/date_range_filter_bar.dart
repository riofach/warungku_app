import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A compact filter bar that lets the user pick a date range for a history
/// list. Shows the active range (or a neutral label) and a clear button.
///
/// Emits `null` when the range is cleared. Reused by the sales & purchase
/// history screens.
class DateRangeFilterBar extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTimeRange?> onChanged;

  const DateRangeFilterBar({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onChanged,
  });

  bool get _hasRange => fromDate != null && toDate != null;

  String get _label {
    if (!_hasRange) return 'Filter tanggal';
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    return '${fmt.format(fromDate!)} – ${fmt.format(toDate!)}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = _hasRange
        ? DateTimeRange(start: fromDate!, end: toDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Pilih rentang tanggal',
      saveText: 'Terapkan',
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickRange(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _hasRange ? AppColors.primary : AppColors.textSecondary,
                side: BorderSide(
                  color: _hasRange ? AppColors.primary : AppColors.border,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_hasRange) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
              color: AppColors.textSecondary,
              tooltip: 'Hapus filter',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
