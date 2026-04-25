/// Model for a selling unit variant of an item (e.g. 1Kg, ½Kg, ¼Kg)
class ItemUnit {
  final String id;
  final String itemId;
  final String label;
  final int quantityBase;
  final int sellPrice;
  final int buyPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemUnit({
    required this.id,
    required this.itemId,
    required this.label,
    required this.quantityBase,
    required this.sellPrice,
    required this.buyPrice,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Available quantity given a base stock value
  int availableFrom(int stockBase) {
    if (quantityBase <= 0) return 0;
    return stockBase ~/ quantityBase;
  }

  factory ItemUnit.fromJson(Map<String, dynamic> json) => ItemUnit(
        id: json['id'] as String,
        itemId: json['item_id'] as String,
        label: json['label'] as String,
        quantityBase: json['quantity_base'] as int? ?? 1,
        sellPrice: json['sell_price'] as int? ?? 0,
        buyPrice: json['buy_price'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'label': label,
        'quantity_base': quantityBase,
        'sell_price': sellPrice,
        'buy_price': buyPrice,
        'is_active': isActive,
      };

  ItemUnit copyWith({
    String? id,
    String? itemId,
    String? label,
    int? quantityBase,
    int? sellPrice,
    int? buyPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ItemUnit(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        label: label ?? this.label,
        quantityBase: quantityBase ?? this.quantityBase,
        sellPrice: sellPrice ?? this.sellPrice,
        buyPrice: buyPrice ?? this.buyPrice,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemUnit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ItemUnit(id: $id, label: $label, qty: $quantityBase)';
}
