import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/category_model.dart';
import '../../data/providers/categories_provider.dart';

/// Dialog for confirming category deletion
/// AC6-AC8: Delete confirmation with item warning
class DeleteCategoryDialog extends ConsumerWidget {
  final Category category;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
  });

  /// Show the dialog and return true if category was deleted successfully
  static Future<bool> show(BuildContext context, Category category) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteCategoryDialog(category: category),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(deleteCategoryNotifierProvider);

    return AlertDialog(
      title: const Text('Hapus Kategori?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning message
          Text(
            'Yakin ingin menghapus kategori "${category.name}"?',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          // Item warning if category has items
          if (category.itemCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Kategori ini memiliki ${category.itemCount} barang. '
                      'Barang tersebut akan menjadi tidak berkategori.',
                      style: const TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Category info card
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
                    Icons.category,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${category.itemCount} barang',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
                  ref.read(deleteCategoryNotifierProvider.notifier).reset();
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
    final notifier = ref.read(deleteCategoryNotifierProvider.notifier);
    final success = await notifier.deleteCategory(category.id);

    if (success && context.mounted) {
      notifier.reset();
      Navigator.of(context).pop(true);
    }
  }
}
