import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';

/// Transaction success screen
/// Shown after successful payment completion (Story 4.5)
class TransactionSuccessScreen extends ConsumerWidget {
  final Transaction transaction;

  const TransactionSuccessScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success animation
              _buildSuccessIcon(),

              const SizedBox(height: AppSpacing.xl),

              // Success message
              const Text(
                'Transaksi Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Transaction code
              _buildTransactionCode(),

              const SizedBox(height: AppSpacing.lg),

              // Payment details
              _buildPaymentDetails(),

              const Spacer(),

              // New transaction button
              _buildNewTransactionButton(context),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.success,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionCode() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Kode Transaksi',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            transaction.code,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppColors.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Total amount
          _buildDetailRow(
            'Total Pembayaran',
            Formatters.formatRupiah(transaction.total),
            isBold: true,
          ),

          // Payment method specific details
          if (transaction.paymentMethod == 'cash') ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            _buildDetailRow(
              'Uang Diterima',
              Formatters.formatRupiah(transaction.cashReceived ?? 0),
            ),

            const SizedBox(height: AppSpacing.sm),

            _buildDetailRow(
              'Kembalian',
              Formatters.formatRupiah(transaction.changeAmount ?? 0),
              valueColor: AppColors.success,
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Payment method
          _buildDetailRow(
            'Metode Pembayaran',
            transaction.paymentMethod == 'cash' ? 'TUNAI' : 'QRIS',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNewTransactionButton(BuildContext context) {
    return FilledButton(
      onPressed: () => _handleNewTransaction(context),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        backgroundColor: AppColors.primary,
      ),
      child: const Text(
        'Transaksi Baru',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleNewTransaction(BuildContext context) {
    // Navigate back to POS screen and clear history
    context.go('/pos');
  }
}
