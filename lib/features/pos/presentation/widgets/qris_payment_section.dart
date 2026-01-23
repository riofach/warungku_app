import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/payment_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../screens/transaction_success_screen.dart';

/// QRIS Payment section for POS (Story 4.4)
///
/// MVP implementation with manual payment confirmation.
/// Future: Integrate with Duitku/Tripay for real QRIS generation.
class QrisPaymentSection extends ConsumerStatefulWidget {
  const QrisPaymentSection({super.key});

  @override
  ConsumerState<QrisPaymentSection> createState() =>
      _QrisPaymentSectionState();
}

class _QrisPaymentSectionState extends ConsumerState<QrisPaymentSection> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
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
          _buildConfirmButton(),
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

  Widget _buildConfirmButton() {
    return FilledButton(
      onPressed: !_isProcessing ? _handleConfirm : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        backgroundColor: AppColors.success,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Pembayaran Diterima',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _handleConfirm() async {
    // Set processing state
    setState(() {
      _isProcessing = true;
    });

    try {
      // Complete transaction via provider
      final transaction = await ref
          .read(transactionNotifierProvider.notifier)
          .completeTransaction();

      // Navigate to success screen if still mounted
      if (mounted) {
        // Pop the payment bottom sheet first
        Navigator.of(context).pop();

        // Navigate to success screen using GoRouter
        context.push('/transaction-success', extra: transaction);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Reset processing state if still mounted
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
