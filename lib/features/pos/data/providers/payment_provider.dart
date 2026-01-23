import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment method enum
enum PaymentMethod { cash, qris }

/// State for payment
class PaymentState {
  final PaymentMethod paymentMethod;
  final int cashReceived;
  final int totalAmount; // From cart

  const PaymentState({
    required this.paymentMethod,
    required this.cashReceived,
    required this.totalAmount,
  });

  factory PaymentState.initial(int totalAmount) => PaymentState(
        paymentMethod: PaymentMethod.cash,
        cashReceived: 0,
        totalAmount: totalAmount,
      );

  /// Calculate change (positive = customer gets change, negative = customer owes)
  int get change => cashReceived - totalAmount;

  /// Check if payment is sufficient
  bool get isSufficient => cashReceived >= totalAmount;

  /// Check if can complete payment
  bool get canComplete => paymentMethod == PaymentMethod.qris || isSufficient;

  PaymentState copyWith({
    PaymentMethod? paymentMethod,
    int? cashReceived,
    int? totalAmount,
  }) {
    return PaymentState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

/// Notifier for payment state
class PaymentNotifier extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    // Initial state with 0 total - will be set when payment sheet opens
    return PaymentState.initial(0);
  }

  /// Initialize payment with total from cart
  void initializePayment(int totalAmount) {
    state = PaymentState.initial(totalAmount);
  }

  /// Set payment method
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Set cash received amount
  void setCashReceived(int amount) {
    // Validate max amount (100 million)
    final validAmount = amount.clamp(0, 100000000);
    state = state.copyWith(cashReceived: validAmount);
  }

  /// Set exact amount (Uang Pas)
  void setExactAmount() {
    state = state.copyWith(cashReceived: state.totalAmount);
  }

  /// Reset payment state
  void reset() {
    state = PaymentState.initial(0);
  }
}

final paymentNotifierProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});

/// Provider for payment method
final paymentMethodProvider = Provider<PaymentMethod>((ref) {
  return ref.watch(paymentNotifierProvider).paymentMethod;
});

/// Provider for change amount
final changeAmountProvider = Provider<int>((ref) {
  return ref.watch(paymentNotifierProvider).change;
});

/// Provider for payment validity
final canCompletePaymentProvider = Provider<bool>((ref) {
  return ref.watch(paymentNotifierProvider).canComplete;
});
