import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/models/admin_account.dart';
import '../../data/providers/admin_management_provider.dart';
import '../widgets/add_admin_dialog.dart';
import '../widgets/delete_admin_dialog.dart';
import '../widgets/edit_password_dialog.dart';

/// Kelola Akun screen — owner-only. Lists owner & kasir accounts from
/// public.users with edit-password / delete actions.
///
/// Self-protection: actions are hidden for the owner's own account.
/// Owner-protection: actions are hidden for ALL owner rows (an owner can be
/// removed only by another owner who is not them).
class AdminListScreen extends ConsumerStatefulWidget {
  const AdminListScreen({super.key});

  @override
  ConsumerState<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends ConsumerState<AdminListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminListNotifierProvider.notifier).loadAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminListState = ref.watch(adminListNotifierProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun'),
      ),
      body: _buildBody(adminListState, currentUser?.id),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddAdmin(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Akun'),
      ),
    );
  }

  Widget _buildBody(AdminListState state, String? currentUserId) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => ref.read(adminListNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada akun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tambahkan akun untuk membantu\nmengelola warung',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminListNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: state.admins.length,
        itemBuilder: (context, index) {
          final admin = state.admins[index];
          final isSelf = currentUserId == admin.id;
          // Hide actions for self AND for any owner row (owners are managed
          // out of band, not by other peers).
          return _AdminCard(
            admin: admin,
            showActions: !isSelf && !admin.isOwner,
            onEditPassword: () => _handleEditPassword(context, admin),
            onDelete: () => _handleDeleteAdmin(context, admin),
          );
        },
      ),
    );
  }

  Future<void> _handleAddAdmin(BuildContext context) async {
    final success = await AddAdminDialog.show(context);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleEditPassword(BuildContext context, AdminAccount admin) async {
    final success = await EditPasswordDialog.show(context, admin);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password ${admin.displayName} berhasil diubah'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleDeleteAdmin(BuildContext context, AdminAccount admin) async {
    final success = await DeleteAdminDialog.show(context, admin);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun ${admin.displayName} berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _AdminCard extends StatelessWidget {
  final AdminAccount admin;
  final bool showActions;
  final VoidCallback? onEditPassword;
  final VoidCallback? onDelete;

  const _AdminCard({
    required this.admin,
    required this.showActions,
    this.onEditPassword,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: admin.isOwner ? AppColors.primary : AppColors.secondary,
              child: Text(
                admin.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          admin.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _RoleBadge(role: admin.role),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    admin.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bergabung ${Formatters.formatDateCompact(admin.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            if (showActions) ...[
              IconButton(
                onPressed: onEditPassword,
                icon: const Icon(Icons.lock_reset),
                tooltip: 'Ubah Password',
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Hapus Akun',
                color: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == UserRole.owner;
    final color = isOwner ? AppColors.primary : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
