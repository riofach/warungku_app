import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/payment_provider.dart';

/// QRIS Payment section for POS (Story 4.4)
///
/// MVP implementation with manual payment confirmation.
/// Future: Integrate with Duitku/Tripay for real QRIS generation.
class QrisPaymentSection extends ConsumerWidget {
  const QrisPaymentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final totalAmount = paymentState.totalAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR Code section
          _buildQrCodeSection(),

          const SizedBox(height: AppSpacing.lg),

          // Total amount display
          _buildTotalDisplay(totalAmount),

          const SizedBox(height: AppSpacing.xl),

          // Confirmation button
          _buildConfirmButton(context),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Image.asset(
            'assets/images/qris-warung.jpeg',
            width: 250,
            height: 250,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalDisplay(int totalAmount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.formatRupiah(totalAmount),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return FilledButton(
      onPressed: () => _handleConfirm(context),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        backgroundColor: AppColors.success,
      ),
      child: const Text(
        'Pembayaran Diterima',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleConfirm(BuildContext context) {
    // TODO: Story 4.5 - Complete transaction & update stock
    // For now, just show a placeholder message
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Pembayaran berhasil dikonfirmasi'),
      ),
    );
  }
}
