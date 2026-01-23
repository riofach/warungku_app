import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/data/models/item_model.dart';
import '../models/cart_item.dart';

/// State for cart
class CartState {
  final List<CartItem> items;

  const CartState({
    required this.items,
  });

  factory CartState.initial() => const CartState(items: []);

  /// Total number of items in cart (sum of quantities)
  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Total number of unique items in cart
  int get uniqueItemCount => items.length;

  /// Total price of all items in cart
  int get totalPrice =>
      items.fold<int>(0, (sum, item) => sum + item.subtotal);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get cart item by item id
  CartItem? getCartItem(String itemId) {
    try {
      return items.firstWhere((cartItem) => cartItem.item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Check if item is in cart
  bool containsItem(String itemId) {
    return items.any((cartItem) => cartItem.item.id == itemId);
  }

  /// Get quantity of specific item in cart
  int getQuantity(String itemId) {
    final cartItem = getCartItem(itemId);
    return cartItem?.quantity ?? 0;
  }

  CartState copyWith({
    List<CartItem>? items,
  }) {
    return CartState(
      items: items ?? this.items,
    );
  }
}

/// Notifier for cart state management
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState.initial();
  }

  /// Add item to cart
  /// If item already exists, increment quantity
  void addItem(Item item, {int quantity = 1}) {
    final existingIndex =
        state.items.indexWhere((cartItem) => cartItem.item.id == item.id);

    if (existingIndex >= 0) {
      // Item exists, increment quantity
      final updatedItems = [...state.items];
      final existingItem = updatedItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Check stock limit
      if (newQuantity > item.stock) {
        return; // Cannot add more than available stock
      }

      updatedItems[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedItems);
    } else {
      // New item, add to cart
      if (quantity > item.stock) {
        quantity = item.stock; // Cap at available stock
      }
      if (quantity > 0) {
        final cartItem = CartItem(
          item: item,
          quantity: quantity,
        );
        state = state.copyWith(items: [...state.items, cartItem]);
      }
    }
  }

  /// Update quantity of item in cart
  void updateQuantity(String itemId, int quantity) {
    final index =
        state.items.indexWhere((cartItem) => cartItem.item.id == itemId);

    if (index >= 0) {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        removeItem(itemId);
      } else {
        // Update quantity (with stock limit check)
        final updatedItems = [...state.items];
        final existingItem = updatedItems[index];
        final maxQuantity = existingItem.item.stock;
        final newQuantity = quantity > maxQuantity ? maxQuantity : quantity;

        updatedItems[index] = existingItem.copyWith(quantity: newQuantity);
        state = state.copyWith(items: updatedItems);
      }
    }
  }

  /// Increment quantity of item in cart
  void incrementQuantity(String itemId) {
    final cartItem = state.getCartItem(itemId);
    if (cartItem != null) {
      // Check stock limit before incrementing
      if (cartItem.quantity < cartItem.item.stock) {
        updateQuantity(itemId, cartItem.quantity + 1);
      }
    }
  }

  /// Decrement quantity of item in cart
  void decrementQuantity(String itemId) {
    final cartItem = state.getCartItem(itemId);
    if (cartItem != null) {
      updateQuantity(itemId, cartItem.quantity - 1);
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    final updatedItems =
        state.items.where((cartItem) => cartItem.item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Clear all items from cart
  void clearCart() {
    state = CartState.initial();
  }

  /// Check if can add more of specific item (stock limit)
  bool canAddMore(String itemId) {
    final cartItem = state.getCartItem(itemId);
    if (cartItem == null) return true;
    return cartItem.quantity < cartItem.item.stock;
  }
}

/// Provider for cart state
final cartNotifierProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

/// Provider for cart total quantity (for badge)
final cartTotalQuantityProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).totalQuantity;
});

/// Provider for cart total price
final cartTotalPriceProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).totalPrice;
});

/// Provider to check if cart is empty
final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartNotifierProvider).isEmpty;
});

/// Provider for cart unique item count
final cartUniqueItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).uniqueItemCount;
});
