import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable confirmation dialog
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya',
    this.cancelLabel = 'Batal',
    this.confirmColor,
    this.icon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor = confirmColor ??
        (isDestructive ? AppColors.error : AppColors.primary);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: effectiveConfirmColor,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: effectiveConfirmColor,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  /// Show confirmation dialog and return result
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }
}

/// Delete confirmation dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final String itemName;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Hapus $itemName?',
      message: 'Data yang dihapus tidak dapat dikembalikan.',
      confirmLabel: 'Hapus',
      icon: Icons.delete_outline,
      isDestructive: true,
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String itemName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(itemName: itemName),
    );
    return result ?? false;
  }
}

/// Logout confirmation dialog
/// Displays: "Yakin ingin keluar?" with "Batal" and "Keluar" options
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfirmationDialog(
      title: 'Keluar',
      message: 'Yakin ingin keluar?',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout,
      isDestructive: true,
    );
  }

  /// Show logout confirmation dialog
  /// Returns true if user confirms, false otherwise
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmationDialog(),
    );
    return result ?? false;
  }
}
