import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/admin_account.dart';
import '../../data/providers/admin_management_provider.dart';
import '../widgets/add_admin_dialog.dart';

/// Admin List Screen
/// FR2: Owner dapat membuat akun admin tambahan
/// Shows list of admin accounts and allows creating new ones
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Admin'),
      ),
      body: _buildBody(adminListState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddAdmin(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Admin'),
      ),
    );
  }

  Widget _buildBody(AdminListState state) {
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
          return _AdminCard(admin: admin);
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
}

/// Admin card widget
class _AdminCard extends StatelessWidget {
  final AdminAccount admin;

  const _AdminCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: admin.isOwner ? AppColors.primary : AppColors.secondary,
          child: Text(
            admin.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                admin.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (admin.isOwner)
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
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              admin.email,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Bergabung ${dateFormat.format(admin.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
