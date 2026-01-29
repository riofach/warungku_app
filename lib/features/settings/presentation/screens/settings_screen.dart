import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../orders/data/repositories/order_repository.dart';

/// Settings/Menu screen
/// FR48: Admin dapat melihat informasi akun dan profil warung
/// FR4: Admin dapat logout dari aplikasi
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Account section
          const _SectionHeader(title: 'Akun'),
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Profil Admin',
            subtitle: currentUser?.email ?? 'admin',
            onTap: () {
              // TODO: Navigate to profile
            },
          ),

          // Data Management section
          const _SectionHeader(title: 'Kelola Data'),
          _MenuTile(
            icon: Icons.inventory_2_outlined,
            title: 'Barang',
            subtitle: 'Kelola produk warung',
            onTap: () => context.push(AppRoutes.items),
          ),
          _MenuTile(
            icon: Icons.category_outlined,
            title: 'Kategori',
            subtitle: 'Kelola kategori barang',
            onTap: () => context.push(AppRoutes.categories),
          ),
          _MenuTile(
            icon: Icons.location_city_outlined,
            title: 'Blok Perumahan',
            subtitle: 'Kelola blok untuk delivery',
            onTap: () => context.push(AppRoutes.housingBlocks),
          ),

          // Reports section
          const _SectionHeader(title: 'Laporan'),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            title: 'Laporan Penjualan',
            subtitle: 'Lihat laporan & export PDF',
            onTap: () => context.push(AppRoutes.reports),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Transaksi',
            subtitle: 'Lihat semua transaksi kasir',
            onTap: () => context.push(AppRoutes.transactionHistory),
          ),

          // Settings section
          const _SectionHeader(title: 'Pengaturan'),
          _MenuTile(
            icon: Icons.schedule_outlined,
            title: 'Jam Operasional',
            subtitle: 'Atur waktu buka tutup',
            onTap: () {
              // TODO: Navigate to operating hours
            },
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Lainnya',
            subtitle: 'WhatsApp, Delivery, dll',
            onTap: () {
              // TODO: Navigate to settings detail
            },
          ),

          // Admin Management section (Owner only)
          if (currentUser?.isOwner ?? false) ...[
            const _SectionHeader(title: 'Admin'),
            _MenuTile(
              icon: Icons.group_outlined,
              title: 'Kelola Admin',
              subtitle: 'Tambah atau kelola akun admin',
              onTap: () => context.push(AppRoutes.adminManagement),
            ),
          ],

          // Development Tools
          const _SectionHeader(title: 'Development Tools'),
          const _SimulationButton(),

          const SizedBox(height: AppSpacing.lg),

          // Logout button
          _LogoutButton(
            isLoading: authState.isLoading,
            onLogout: () async {
              await _handleLogout(context, ref);
            },
          ),
        ],
      ),
    );
  }

  /// Handle logout flow
  /// Shows confirmation dialog, then calls AuthNotifier.signOut()
  /// Shows error SnackBar if logout fails
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog - AC2
    final confirmed = await LogoutConfirmationDialog.show(context);

    if (confirmed && context.mounted) {
      // Call AuthNotifier.signOut() - AC3
      final success = await ref.read(authNotifierProvider.notifier).signOut();

      if (!success && context.mounted) {
        // Show error message if logout failed
        final authState = ref.read(authNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'Gagal keluar dari aplikasi'),
            backgroundColor: AppColors.error,
          ),
        );
        // Clear the error state
        ref.read(authNotifierProvider.notifier).clearError();
      } else if (success && context.mounted) {
        // Navigation is handled by go_router redirect
        // when auth state changes to unauthenticated
        context.go(AppRoutes.login);
      }
    }
  }
}

class _SimulationButton extends ConsumerStatefulWidget {
  const _SimulationButton();

  @override
  ConsumerState<_SimulationButton> createState() => _SimulationButtonState();
}

class _SimulationButtonState extends ConsumerState<_SimulationButton> {
  bool _isLoading = false;

  Future<void> _simulateOrder() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(orderRepositoryProvider).createDummyOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulated Order Created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simulasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: ListTile(
        leading: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.science, color: AppColors.primary),
        title: const Text(
          'Simulasi Pesanan Baru',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Buat pesanan dummy untuk testing'),
        onTap: _isLoading ? null : _simulateOrder,
      ),
    );
  }
}


/// Logout button widget
/// Shows loading state during logout process
class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLogout;

  const _LogoutButton({
    required this.isLoading,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onLogout,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.errorLight),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            )
          : const Icon(Icons.logout, color: AppColors.error),
      label: Text(
        isLoading ? 'Keluar...' : 'Keluar',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
