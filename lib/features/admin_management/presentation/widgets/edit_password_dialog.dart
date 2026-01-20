import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/admin_account.dart';
import '../../data/providers/admin_management_provider.dart';

/// Dialog for editing admin password
/// FR2a: Owner dapat mengubah password admin
/// AC2-AC4: Edit password dialog with validation
class EditPasswordDialog extends ConsumerStatefulWidget {
  final AdminAccount admin;

  const EditPasswordDialog({
    super.key,
    required this.admin,
  });

  /// Show the dialog and return true if password was updated successfully
  static Future<bool> show(BuildContext context, AdminAccount admin) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditPasswordDialog(admin: admin),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EditPasswordDialog> createState() => _EditPasswordDialogState();
}

class _EditPasswordDialogState extends ConsumerState<EditPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(updatePasswordNotifierProvider);

    return AlertDialog(
      title: Text('Ubah Password ${widget.admin.displayName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !actionState.isLoading,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                hintText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password wajib diisi';
                }
                if (value.length < 8) {
                  return 'Password minimal 8 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm password field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              enabled: !actionState.isLoading,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                hintText: 'Masukkan ulang password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password wajib diisi';
                }
                if (value != _passwordController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
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
      ),
      actions: [
        TextButton(
          onPressed: actionState.isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: actionState.isLoading ? null : _handleSubmit,
          child: actionState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(updatePasswordNotifierProvider.notifier);
    final success = await notifier.updatePassword(
      userId: widget.admin.id,
      newPassword: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
      notifier.reset();
    }
  }
}
