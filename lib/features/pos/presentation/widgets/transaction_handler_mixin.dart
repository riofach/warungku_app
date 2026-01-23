import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/providers/transaction_provider.dart';

/// Mixin to handle common transaction completion logic across payment sections
mixin TransactionHandlerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isProcessing = false;

  Future<void> handleTransaction(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function() onComplete,
  ) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final transaction = await ref
          .read(transactionNotifierProvider.notifier)
          .completeTransaction();

      if (mounted) {
        // Pop the payment bottom sheet first
        Navigator.of(context).pop();
        
        // Navigate to success screen using GoRouter
        context.push('/transaction-success', extra: transaction);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
}
