import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'cart_provider.dart';
import 'payment_provider.dart';
import 'pos_items_provider.dart';

/// Provider for transaction repository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final supabase = Supabase.instance.client;
  return TransactionRepository(supabase);
});

/// Notifier for transaction completion
class TransactionNotifier extends Notifier<AsyncValue<Transaction?>> {
  @override
  AsyncValue<Transaction?> build() {
    return const AsyncValue.data(null);
  }

  /// Complete transaction: save to database and update stock atomically
  ///
  /// This method:
  /// 1. Gets cart items and payment info from providers
  /// 2. Calls repository to create transaction (atomic with stock reduction)
  /// 3. On success: clears cart and resets payment state
  /// 4. Returns created transaction or throws exception
  Future<Transaction> completeTransaction() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(transactionRepositoryProvider);
      
      // Get cart and payment state
      final cartState = ref.read(cartNotifierProvider);
      final paymentState = ref.read(paymentNotifierProvider);

      // Validate cart is not empty
      if (cartState.isEmpty) {
        throw Exception('Keranjang kosong. Tambahkan item terlebih dahulu.');
      }

      // Validate payment is sufficient (for cash)
      if (paymentState.paymentMethod == PaymentMethod.cash &&
          !paymentState.isSufficient) {
        throw Exception('Uang yang diterima kurang dari total pembayaran.');
      }

      // Create transaction via repository (atomic with stock reduction)
      final transaction = await repository.createTransaction(
        items: cartState.items,
        paymentMethod: paymentState.paymentMethod,
        total: paymentState.totalAmount,
        cashReceived: paymentState.paymentMethod == PaymentMethod.cash
            ? paymentState.cashReceived
            : null,
        changeAmount: paymentState.paymentMethod == PaymentMethod.cash
            ? paymentState.change
            : null,
      );

      // Clear cart and reset payment on success
      ref.read(cartNotifierProvider.notifier).clearCart();
      ref.read(paymentNotifierProvider.notifier).reset();
      
      // Invalidate POS items provider to trigger refresh and update stock
      // This ensures the item list shows updated stock after transaction
      ref.invalidate(posItemsNotifierProvider);

      // Update state to success
      state = AsyncValue.data(transaction);

      return transaction;
    } catch (e, st) {
      // Update state to error
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      state = AsyncValue.error(errorMessage, st);
      rethrow; // Re-throw for UI to handle
    }
  }

  /// Reset transaction state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for transaction notifier
final transactionNotifierProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<Transaction?>>(
  () => TransactionNotifier(),
);

/// Provider to check if transaction is loading
final isTransactionLoadingProvider = Provider<bool>((ref) {
  final transactionState = ref.watch(transactionNotifierProvider);
  return transactionState.isLoading;
});
