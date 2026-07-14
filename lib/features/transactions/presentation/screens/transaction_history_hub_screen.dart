import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../settings/presentation/widgets/settings_tile.dart';

/// "Riwayat Transaksi" hub — lets the owner choose between sales (penjualan)
/// and purchase (pembelian) history.
class TransactionHistoryHubScreen extends StatelessWidget {
  const TransactionHistoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Penjualan',
            subtitle: 'Semua transaksi kasir (POS)',
            onTap: () => context.push(AppRoutes.salesHistory),
          ),
          SettingsTile(
            icon: Icons.shopping_cart_outlined,
            title: 'Riwayat Pembelian',
            subtitle: 'Semua pembelian & restock stok',
            onTap: () => context.push(AppRoutes.purchaseHistory),
          ),
        ],
      ),
    );
  }
}
