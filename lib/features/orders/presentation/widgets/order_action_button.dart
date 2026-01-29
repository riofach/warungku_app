import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../data/providers/orders_provider.dart';
import '../../data/models/order_model.dart';
import '../../utils/order_status_helper.dart';

class OrderActionButton extends ConsumerWidget {
  final Order order;

  const OrderActionButton({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAction = OrderStatusHelper.getNextStatusAction(
      order.status.name,
      deliveryType: order.deliveryType,
    );
    
    // If no action available (e.g. completed), return empty
    if (nextAction == null) return const SizedBox.shrink();

    final (nextStatus, buttonText) = nextAction;
    final state = ref.watch(orderControllerProvider);
    final isLoading = state.isLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isLoading
              ? null
              : () => _showConfirmation(context, ref, nextStatus, buttonText),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showConfirmation(
    BuildContext context,
    WidgetRef ref,
    String nextStatus,
    String buttonText,
  ) async {
    final title = 'Konfirmasi Status';
    String message = '';
    
    if (nextStatus == 'processing') {
      message = 'Proses pesanan ini?';
    } else if (nextStatus == 'ready') {
      // Use the button text (without "Siap ") to make the message more specific
      // e.g., "Pesanan sudah Diantar?" or "Pesanan sudah Diambil?"
      // But buttonText is "Siap Diantar" or "Siap Diambil".
      // Let's just use the button text to construct a natural sentence.
      final action = buttonText.replaceFirst('Siap ', '');
      message = 'Pesanan sudah siap $action?';
    } else if (nextStatus == 'completed') {
      message = 'Selesaikan pesanan? Aksi ini tidak dapat dibatalkan.';
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Ya, Lanjutkan',
      cancelLabel: 'Batal',
    );

    if (confirmed) {
      final controller = ref.read(orderControllerProvider.notifier);
      await controller.updateOrderStatus(order.id, nextStatus);
      
      if (context.mounted) {
         // Optional feedback
      }
    }
  }
}
