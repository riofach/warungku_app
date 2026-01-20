import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/admin_account.dart';
import '../../data/providers/admin_management_provider.dart';

/// Dialog for confirming admin deletion
/// FR2b: Owner dapat menghapus akun admin
/// AC5-AC6: Delete confirmation dialog
class DeleteAdminDialog extends ConsumerWidget {
  final AdminAccount admin;

  const DeleteAdminDialog({
    super.key,
    required this.admin,
  });

  /// Show the dialog and return true if admin was deleted successfully
  static Future<bool> show(BuildContext context, AdminAccount admin) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAdminDialog(admin: admin),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(deleteAdminNotifierProvider);

    return AlertDialog(
      title: const Text('Hapus Admin?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yakin ingin menghapus admin ${admin.displayName}? Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          // Admin info card
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
                CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  radius: 20,
                  child: Text(
                    admin.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        admin.email,
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
                  ref.read(deleteAdminNotifierProvider.notifier).reset();
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
    final notifier = ref.read(deleteAdminNotifierProvider.notifier);
    final success = await notifier.deleteAdmin(userId: admin.id);

    if (success && context.mounted) {
      Navigator.of(context).pop(true);
      notifier.reset();
    }
  }
}
