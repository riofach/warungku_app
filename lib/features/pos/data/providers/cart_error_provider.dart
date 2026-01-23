import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for cart error message state
class CartErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? message) {
    state = message;
  }
}

/// Provider for cart error messages (e.g., stock limit reached)
/// Used to display SnackBar or other feedback to user
final cartErrorProvider = NotifierProvider<CartErrorNotifier, String?>(() {
  return CartErrorNotifier();
});
