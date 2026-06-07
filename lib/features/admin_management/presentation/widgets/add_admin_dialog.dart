import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/data/models/user_role.dart';
import '../../data/providers/admin_management_provider.dart';

/// Dialog for adding a new account (owner or kasir).
///
/// Owner stays signed in after creation — the admin-management Edge Function
/// performs the create server-side with the service role, so the local
/// session is untouched.
class AddAdminDialog extends ConsumerStatefulWidget {
  const AddAdminDialog({super.key});

  /// Show the dialog and return true if account was created.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddAdminDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.kasir;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createAdminNotifierProvider);

    ref.listen<CreateAdminState>(createAdminNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        ref.read(createAdminNotifierProvider.notifier).reset();
        if (mounted) Navigator.of(context).pop(true);
      }
    });

    return AlertDialog(
      title: const Text('Tambah Akun'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  if (value.trim().length < 2) {
                    return 'Nama minimal 2 karakter';
                  }
                  return null;
                },
                enabled: !createState.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'contoh@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email wajib diisi';
                  }
                  if (!Validators.isValidEmail(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
                enabled: !createState.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimal 8 karakter',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  if (value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
                enabled: !createState.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.kasir,
                    child: Text(
                      'Kasir (akses Dashboard & POS)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: UserRole.owner,
                    child: Text(
                      'Owner (akses penuh)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: createState.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
              ),

              if (createState.hasError) ...[
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
                          createState.errorMessage ?? 'Terjadi kesalahan',
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: createState.isLoading
              ? null
              : () {
                  ref.read(createAdminNotifierProvider.notifier).reset();
                  Navigator.of(context).pop(false);
                },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: createState.isLoading ? null : _handleSubmit,
          child: createState.isLoading
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
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(createAdminNotifierProvider.notifier).createAdmin(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
          );
    }
  }
}
