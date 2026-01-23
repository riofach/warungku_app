import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/pos/data/providers/payment_provider.dart';

void main() {
  group('PaymentNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.paymentMethod, PaymentMethod.cash);
      expect(state.cashReceived, 0);
      expect(state.totalAmount, 0);
    });

    test('should initialize payment with total amount', () {
      // Act
      container.read(paymentNotifierProvider.notifier).initializePayment(15000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.totalAmount, 15000);
      expect(state.cashReceived, 0);
      expect(state.paymentMethod, PaymentMethod.cash);
    });

    test('should calculate positive change when cash > total', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(20000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.change, 5000);
      expect(state.isSufficient, true);
    });

    test('should calculate negative change when cash < total', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(10000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.change, -5000);
      expect(state.isSufficient, false);
    });

    test('should calculate zero change when cash equals total', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(15000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.change, 0);
      expect(state.isSufficient, true);
    });

    test('should set exact amount with setExactAmount', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setExactAmount();

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.cashReceived, 15000);
      expect(state.change, 0);
      expect(state.isSufficient, true);
    });

    test('should clamp cash to max 100 million', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(200000000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.cashReceived, 100000000);
    });

    test('should clamp negative cash to 0', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(-5000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.cashReceived, 0);
    });

    test('should change payment method', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      var state = container.read(paymentNotifierProvider);
      expect(state.paymentMethod, PaymentMethod.cash);

      // Act
      notifier.setPaymentMethod(PaymentMethod.qris);

      // Assert
      state = container.read(paymentNotifierProvider);
      expect(state.paymentMethod, PaymentMethod.qris);
    });

    test('should reset payment state', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);
      notifier.setCashReceived(20000);
      notifier.setPaymentMethod(PaymentMethod.qris);

      // Act
      notifier.reset();

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.totalAmount, 0);
      expect(state.cashReceived, 0);
      expect(state.paymentMethod, PaymentMethod.cash);
    });

    test('canComplete should be true when cash payment is sufficient', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(20000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.canComplete, true);
    });

    test('canComplete should be false when cash payment is insufficient', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);

      // Act
      notifier.setCashReceived(10000);

      // Assert
      final state = container.read(paymentNotifierProvider);
      expect(state.canComplete, false);
    });

    test('canComplete should be true for QRIS payment regardless of cash', () {
      // Arrange
      final notifier = container.read(paymentNotifierProvider.notifier);
      notifier.initializePayment(15000);
      notifier.setPaymentMethod(PaymentMethod.qris);

      // Act - set insufficient cash
      notifier.setCashReceived(5000);

      // Assert - still can complete because QRIS doesn't check cash
      final state = container.read(paymentNotifierProvider);
      expect(state.canComplete, true);
    });
  });

  group('PaymentState', () {
    test('should create initial state with given total', () {
      // Act
      final state = PaymentState.initial(25000);

      // Assert
      expect(state.totalAmount, 25000);
      expect(state.cashReceived, 0);
      expect(state.paymentMethod, PaymentMethod.cash);
    });

    test('copyWith should preserve unchanged values', () {
      // Arrange
      final original = PaymentState(
        paymentMethod: PaymentMethod.cash,
        cashReceived: 10000,
        totalAmount: 15000,
      );

      // Act
      final updated = original.copyWith(cashReceived: 20000);

      // Assert
      expect(updated.cashReceived, 20000);
      expect(updated.totalAmount, 15000); // unchanged
      expect(updated.paymentMethod, PaymentMethod.cash); // unchanged
    });

    test('copyWith should update all values when provided', () {
      // Arrange
      final original = PaymentState(
        paymentMethod: PaymentMethod.cash,
        cashReceived: 10000,
        totalAmount: 15000,
      );

      // Act
      final updated = original.copyWith(
        paymentMethod: PaymentMethod.qris,
        cashReceived: 20000,
        totalAmount: 30000,
      );

      // Assert
      expect(updated.paymentMethod, PaymentMethod.qris);
      expect(updated.cashReceived, 20000);
      expect(updated.totalAmount, 30000);
    });
  });
}
