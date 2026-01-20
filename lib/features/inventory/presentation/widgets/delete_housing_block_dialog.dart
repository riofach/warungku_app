import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/housing_block_model.dart';
import '../../data/providers/housing_blocks_provider.dart';

/// Dialog for confirming housing block deletion
/// AC6-AC7: Delete confirmation with warning
class DeleteHousingBlockDialog extends ConsumerWidget {
  final HousingBlock block;

  const DeleteHousingBlockDialog({
    super.key,
    required this.block,
  });

  /// Show the dialog and return true if housing block was deleted successfully
  static Future<bool> show(BuildContext context, HousingBlock block) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteHousingBlockDialog(block: block),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(deleteHousingBlockNotifierProvider);

    return AlertDialog(
      title: const Text('Hapus Blok?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning message - AC6: Single message as per spec
          Text(
            'Yakin ingin menghapus blok "${block.name}"? Pesanan dengan blok ini akan tetap tercatat.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          // Block info card
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    block.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (actionState.hasError) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      actionState.errorMessage ?? 'Terjadi kesalahan',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: actionState.isLoading
              ? null
              : () {
                  ref.read(deleteHousingBlockNotifierProvider.notifier).reset();
                  Navigator.of(context).pop(false);
                },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: actionState.isLoading
              ? null
              : () => _handleDelete(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: actionState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Hapus'),
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(deleteHousingBlockNotifierProvider.notifier);
    final success = await notifier.deleteBlock(block.id);

    if (success && context.mounted) {
      notifier.reset();
      Navigator.of(context).pop(true);
    }
  }
}
