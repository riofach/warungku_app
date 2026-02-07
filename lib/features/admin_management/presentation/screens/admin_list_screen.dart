import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/models/admin_account.dart';
import '../../data/providers/admin_management_provider.dart';
import '../widgets/add_admin_dialog.dart';
import '../widgets/delete_admin_dialog.dart';
import '../widgets/edit_password_dialog.dart';

/// Admin List Screen
/// FR2: Owner dapat membuat akun admin tambahan
/// FR2a: Owner dapat mengubah password admin
/// FR2b: Owner dapat menghapus akun admin
/// Shows list of admin accounts with edit/delete actions
class AdminListScreen extends ConsumerStatefulWidget {
  const AdminListScreen({super.key});

  @override
  ConsumerState<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends ConsumerState<AdminListScreen> {
  @override
  void initState() {
    super.initState();
    // Load admins when screen opens
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
        title: const Text('Kelola Admin'),
      ),
      body: _buildBody(adminListState, currentUser?.id),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddAdmin(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Admin'),
      ),
    );
  }

  Widget _buildBody(AdminListState state, String? currentUserId) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
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
              'Belum ada admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tambahkan admin untuk membantu\nmengelola warung',
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
          // AC7: Self-protection - hide actions for owner's own account
          final isSelf = currentUserId == admin.id;
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
          content: Text('Admin berhasil ditambahkan'),
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
          content: Text('Admin ${admin.displayName} berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Admin card widget with actions
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
            // Avatar
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
            
            // Info
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
                      if (admin.isOwner) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Owner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
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
                    // LOW-3 FIX: Use centralized formatter instead of local DateFormat
                    'Bergabung ${Formatters.formatDateCompact(admin.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions (only shown for non-self, non-owner admins)
            if (showActions) ...[
              // Edit password button
              IconButton(
                onPressed: onEditPassword,
                icon: const Icon(Icons.lock_reset),
                tooltip: 'Ubah Password',
                color: AppColors.textSecondary,
              ),
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Hapus Admin',
                color: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
