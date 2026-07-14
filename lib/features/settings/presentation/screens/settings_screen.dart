import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../widgets/account_header.dart';
import '../widgets/settings_tile.dart';

/// Menu / Settings screen — role-aware.
///
/// Owner sees full sections: Kelola Data, Laporan, Pengaturan, Admin,
/// Development Tools.
/// Kasir sees a minimal screen: account info + logout only.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const AccountHeader(),
          const SizedBox(height: AppSpacing.md),

          if (isOwner) ...[
            const _SectionHeader(title: 'Kelola Data'),
            SettingsTile(
              icon: Icons.inventory_2_outlined,
              title: 'Barang',
              subtitle: 'Kelola produk warung',
              onTap: () => context.push(AppRoutes.items),
            ),
            SettingsTile(
              icon: Icons.shopping_cart_checkout,
              title: 'Input Pembelian',
              subtitle: 'Catat pembelian & update stok',
              onTap: () => context.push(AppRoutes.purchaseFlow),
            ),
            SettingsTile(
              icon: Icons.category_outlined,
              title: 'Kategori',
              subtitle: 'Kelola kategori barang',
              onTap: () => context.push(AppRoutes.categories),
            ),

            const _SectionHeader(title: 'Laporan'),
            SettingsTile(
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Transaksi',
              subtitle: 'Lihat riwayat penjualan & pembelian',
              onTap: () => context.push(AppRoutes.transactionHistory),
            ),

            const _SectionHeader(title: 'Pengaturan'),
            SettingsTile(
              icon: Icons.schedule_outlined,
              title: 'Jam Operasional',
              subtitle: 'Atur waktu buka tutup',
              onTap: () => context.push(AppRoutes.settingsOperatingHours),
            ),
            SettingsTile(
              icon: Icons.settings_outlined,
              title: 'Delivery & WhatsApp',
              subtitle: 'Atur pengiriman & kontak',
              onTap: () => context.push(AppRoutes.settingsDelivery),
            ),

            const _SectionHeader(title: 'Akun'),
            SettingsTile(
              icon: Icons.group_outlined,
              title: 'Kelola Akun',
              subtitle: 'Tambah atau kelola akun owner & kasir',
              onTap: () => context.push(AppRoutes.adminManagement),
            ),

            const _SectionHeader(title: 'Development Tools'),
            const _SimulationButton(),
          ],

          const SizedBox(height: AppSpacing.lg),

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

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await LogoutConfirmationDialog.show(context);

    if (confirmed && context.mounted) {
      final success = await ref.read(authNotifierProvider.notifier).signOut();

      if (!success && context.mounted) {
        final authState = ref.read(authNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authState.errorMessage ?? 'Gagal keluar dari aplikasi',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      } else if (success && context.mounted) {
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
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.science, color: AppColors.primary),
        title: const Text(
          'Simulasi Pesanan Baru',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Buat pesanan dummy untuk testing'),
        onTap: _isLoading ? null : _simulateOrder,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLogout;

  const _LogoutButton({required this.isLoading, required this.onLogout});

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
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
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
