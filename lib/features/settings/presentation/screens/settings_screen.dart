import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Settings/Menu screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Account section
          _SectionHeader(title: 'Akun'),
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Profil Admin',
            subtitle: SupabaseService.currentUser?.email ?? 'admin',
            onTap: () {
              // TODO: Navigate to profile
            },
          ),
          
          // Data Management section
          _SectionHeader(title: 'Kelola Data'),
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
            icon: Icons.location_on_outlined,
            title: 'Blok Perumahan',
            subtitle: 'Kelola area delivery',
            onTap: () {
              // TODO: Navigate to housing blocks
            },
          ),

          // Reports section
          _SectionHeader(title: 'Laporan'),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            title: 'Laporan Penjualan',
            subtitle: 'Lihat laporan & export PDF',
            onTap: () => context.push(AppRoutes.reports),
          ),

          // Settings section
          _SectionHeader(title: 'Pengaturan'),
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

          const SizedBox(height: AppSpacing.lg),

          // Logout button
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await SupabaseService.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
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
