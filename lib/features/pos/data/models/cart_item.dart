import '../../../inventory/data/models/item_model.dart';
import '../../../inventory/data/models/item_unit_model.dart';

/// Cart item for POS transactions.
/// For has_units items, selectedUnit must be provided.
/// cartKey uniquely identifies this cart entry.
class CartItem {
  final Item item;
  final int quantity;
  final ItemUnit? selectedUnit;

  const CartItem({
    required this.item,
    required this.quantity,
    this.selectedUnit,
  });

  /// Unique key in cart: "{itemId}_{unitId}" for unit items, else itemId
  String get cartKey =>
      selectedUnit != null ? '${item.id}_${selectedUnit!.id}' : item.id;

  int get sellPrice =>
      selectedUnit != null ? selectedUnit!.sellPrice : item.sellPrice;

  int get buyPrice =>
      selectedUnit != null ? selectedUnit!.buyPrice : item.buyPrice;

  int get subtotal => sellPrice * quantity;

  /// Base units consumed per 1 quantity sold
  int get quantityBaseUsed =>
      selectedUnit != null ? selectedUnit!.quantityBase : 1;

  String get displayName =>
      selectedUnit != null ? '${item.name} (${selectedUnit!.label})' : item.name;

  CartItem copyWith({
    Item? item,
    int? quantity,
    ItemUnit? selectedUnit,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
    );
  }

  @override
  String toString() =>
      'CartItem(key: $cartKey, qty: $quantity, subtotal: $subtotal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          cartKey == other.cartKey;

  @override
  int get hashCode => cartKey.hashCode;
}
