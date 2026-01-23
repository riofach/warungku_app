import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/payment_provider.dart';
import '../../data/providers/transaction_provider.dart';
import '../screens/transaction_success_screen.dart';
import 'quick_amount_chip.dart';

class CashPaymentSection extends ConsumerStatefulWidget {
  const CashPaymentSection({super.key});

  @override
  ConsumerState<CashPaymentSection> createState() =>
      _CashPaymentSectionState();
}

class _CashPaymentSectionState extends ConsumerState<CashPaymentSection> {
  final _cashController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final change = paymentState.change;
    final isSufficient = paymentState.isSufficient;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick amount chips
          const Text(
            'Pilih Nominal',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildQuickAmountChips(paymentState.totalAmount),

          const SizedBox(height: AppSpacing.lg),

          // Manual input
          const Text(
            'Atau Masukkan Manual',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCashInput(),

          const SizedBox(height: AppSpacing.lg),

          // Change display
          _buildChangeDisplay(change, isSufficient),

          const SizedBox(height: AppSpacing.lg),

          // Complete button
          _buildCompleteButton(isSufficient),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChips(int totalAmount) {
    final amounts = [
      ('Uang Pas', totalAmount),
      ('Rp 10.000', 10000),
      ('Rp 20.000', 20000),
      ('Rp 50.000', 50000),
      ('Rp 100.000', 100000),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: amounts.map((item) {
        final (label, amount) = item;
        return QuickAmountChip(
          label: label,
          onTap: () => _onQuickAmountTap(amount),
        );
      }).toList(),
    );
  }

  void _onQuickAmountTap(int amount) {
    ref.read(paymentNotifierProvider.notifier).setCashReceived(amount);
    _cashController.text = Formatters.formatRupiahShort(amount);
  }

  Widget _buildCashInput() {
    return TextField(
      controller: _cashController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Masukkan nominal',
        prefixText: 'Rp ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        RupiahInputFormatter(),
      ],
      onChanged: (value) {
        // Parse formatted value to integer
        final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
        final amount = int.tryParse(cleanValue) ?? 0;

        // Show warning if exceeds max
        if (amount > 100000000) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nominal maksimal Rp 100.000.000'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        ref.read(paymentNotifierProvider.notifier).setCashReceived(amount);
      },
    );
  }

  Widget _buildChangeDisplay(int change, bool isSufficient) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSufficient
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isSufficient ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isSufficient ? 'Kembalian' : 'Kurang',
            style: TextStyle(
              color: isSufficient ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            Formatters.formatRupiah(change.abs()),
            style: TextStyle(
              color: isSufficient ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(bool isSufficient) {
    return FilledButton(
      onPressed: (isSufficient && !_isProcessing) ? _handleComplete : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        backgroundColor: isSufficient ? AppColors.primary : null,
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
          : const Text('Selesai'),
    );
  }

  Future<void> _handleComplete() async {
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

        // Navigate to success screen using GoRouter instead of Navigator.push
        // to maintain proper route stack management
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
