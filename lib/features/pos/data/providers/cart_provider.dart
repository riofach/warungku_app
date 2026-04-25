import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/data/models/item_model.dart';
import '../../../inventory/data/models/item_unit_model.dart';
import '../models/cart_item.dart';
import 'cart_error_provider.dart';

class CartState {
  final List<CartItem> items;

  const CartState({required this.items});

  factory CartState.initial() => const CartState(items: []);

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  int get uniqueItemCount => items.length;

  int get totalPrice => items.fold<int>(0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartItem? getByKey(String cartKey) {
    try {
      return items.firstWhere((ci) => ci.cartKey == cartKey);
    } catch (_) {
      return null;
    }
  }

  bool containsKey(String cartKey) =>
      items.any((ci) => ci.cartKey == cartKey);

  int getQuantityByKey(String cartKey) =>
      getByKey(cartKey)?.quantity ?? 0;

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState.initial();

  /// Add item to cart. For has_units items, pass selectedUnit.
  void addItem(Item item, {int quantity = 1, ItemUnit? selectedUnit}) {
    final tempCart = CartItem(
      item: item,
      quantity: quantity,
      selectedUnit: selectedUnit,
    );
    final cartKey = tempCart.cartKey;

    // Stock check
    final maxAvail = selectedUnit != null
        ? selectedUnit.availableFrom(item.stock)
        : item.stock;

    final existingIndex =
        state.items.indexWhere((ci) => ci.cartKey == cartKey);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final newQty = existing.quantity + quantity;

      if (newQty > maxAvail) {
        ref.read(cartErrorProvider.notifier).setError(
            'Stok ${item.name}${selectedUnit != null ? " (${selectedUnit.label})" : ""} tidak mencukupi (sisa: $maxAvail)');
        return;
      }

      final updatedItems = [...state.items];
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      if (quantity > maxAvail) {
        ref.read(cartErrorProvider.notifier).setError(
            'Stok ${item.name}${selectedUnit != null ? " (${selectedUnit.label})" : ""} tidak mencukupi (sisa: $maxAvail)');
        return;
      }
      if (quantity > 0) {
        state = state.copyWith(items: [...state.items, tempCart]);
      }
    }
  }

  void updateQuantity(String cartKey, int quantity) {
    final index = state.items.indexWhere((ci) => ci.cartKey == cartKey);
    if (index < 0) return;

    if (quantity <= 0) {
      removeItem(cartKey);
      return;
    }

    final existing = state.items[index];
    final maxAvail = existing.selectedUnit != null
        ? existing.selectedUnit!.availableFrom(existing.item.stock)
        : existing.item.stock;

    if (quantity > maxAvail) {
      ref.read(cartErrorProvider.notifier).setError(
          'Stok ${existing.item.name} tidak mencukupi (sisa: $maxAvail)');
    }

    final newQty = quantity > maxAvail ? maxAvail : quantity;
    final updatedItems = [...state.items];
    updatedItems[index] = existing.copyWith(quantity: newQty);
    state = state.copyWith(items: updatedItems);
  }

  void incrementQuantity(String cartKey) {
    final ci = state.getByKey(cartKey);
    if (ci == null) return;
    final maxAvail = ci.selectedUnit != null
        ? ci.selectedUnit!.availableFrom(ci.item.stock)
        : ci.item.stock;
    if (ci.quantity < maxAvail) {
      updateQuantity(cartKey, ci.quantity + 1);
    } else {
      ref.read(cartErrorProvider.notifier).setError(
          'Stok ${ci.item.name} tidak mencukupi (sisa: $maxAvail)');
    }
  }

  void decrementQuantity(String cartKey) {
    final ci = state.getByKey(cartKey);
    if (ci != null) updateQuantity(cartKey, ci.quantity - 1);
  }

  void removeItem(String cartKey) {
    state = state.copyWith(
        items: state.items.where((ci) => ci.cartKey != cartKey).toList());
  }

  void clearCart() => state = CartState.initial();

  bool canAddMore(String cartKey) {
    final ci = state.getByKey(cartKey);
    if (ci == null) return true;
    final maxAvail = ci.selectedUnit != null
        ? ci.selectedUnit!.availableFrom(ci.item.stock)
        : ci.item.stock;
    return ci.quantity < maxAvail;
  }
}

final cartNotifierProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final cartTotalQuantityProvider =
    Provider<int>((ref) => ref.watch(cartNotifierProvider).totalQuantity);

final cartTotalPriceProvider =
    Provider<int>((ref) => ref.watch(cartNotifierProvider).totalPrice);

final cartIsEmptyProvider =
    Provider<bool>((ref) => ref.watch(cartNotifierProvider).isEmpty);

final cartUniqueItemCountProvider =
    Provider<int>((ref) => ref.watch(cartNotifierProvider).uniqueItemCount);
