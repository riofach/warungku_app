import '../../../inventory/data/models/item_model.dart';

/// Cart item model for POS transactions
/// Represents an item in the shopping cart with quantity
class CartItem {
  final Item item;
  final int quantity;

  const CartItem({
    required this.item,
    required this.quantity,
  });

  /// Calculated subtotal for this cart item
  int get subtotal => item.sellPrice * quantity;

  /// Create a copy with updated fields
  CartItem copyWith({
    Item? item,
    int? quantity,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() =>
      'CartItem(item: ${item.name}, quantity: $quantity, subtotal: $subtotal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          item.id == other.item.id;

  @override
  int get hashCode => item.id.hashCode;
}
