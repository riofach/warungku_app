import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/payment_provider.dart';
import 'cash_payment_section.dart';
import 'qris_payment_section.dart';

class PaymentBottomSheet extends ConsumerStatefulWidget {
  const PaymentBottomSheet({super.key});

  @override
  ConsumerState<PaymentBottomSheet> createState() =>
      _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Initialize payment with cart total
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartTotal = ref.read(cartTotalPriceProvider);
      ref.read(paymentNotifierProvider.notifier).initializePayment(cartTotal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = ref.watch(cartTotalPriceProvider);
    final paymentMethod = ref.watch(paymentMethodProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with total
          _buildHeader(context, cartTotal),

          // Payment method tabs
          _buildPaymentMethodTabs(ref),

          const Divider(height: 1),

          // Payment content based on method
          Flexible(
            child: paymentMethod == PaymentMethod.cash
                ? const CashPaymentSection()
                : const QrisPaymentSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatRupiah(total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleClose(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTabs(WidgetRef ref) {
    final currentMethod = ref.watch(paymentMethodProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodTab(
              ref,
              label: 'Tunai',
              icon: Icons.payments_outlined,
              method: PaymentMethod.cash,
              isSelected: currentMethod == PaymentMethod.cash,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildMethodTab(
              ref,
              label: 'QRIS',
              icon: Icons.qr_code_2_outlined,
              method: PaymentMethod.qris,
              isSelected: currentMethod == PaymentMethod.qris,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab(
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required PaymentMethod method,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () =>
          ref.read(paymentNotifierProvider.notifier).setPaymentMethod(method),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClose(BuildContext context) async {
    final paymentState = ref.read(paymentNotifierProvider);
    final navigator = Navigator.of(context);

    // If cash already entered, confirm cancel
    if (paymentState.cashReceived > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('Batalkan Pembayaran?'),
          content: const Text('Nominal yang sudah dimasukkan akan hilang.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Batalkan'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        ref.read(paymentNotifierProvider.notifier).reset();
        navigator.pop();
      }
    } else {
      navigator.pop();
    }
  }
}
