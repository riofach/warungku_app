import 'item_unit_model.dart';

/// Local state model untuk unit variant sebelum disimpan ke database.
/// id != null → existing unit (edit). id == null → unit baru.
class ItemUnitDraft {
  final String? id;
  String label;
  int quantityBase;
  int sellPrice;
  int buyPrice;
  bool isActive;

  ItemUnitDraft({
    this.id,
    required this.label,
    required this.quantityBase,
    required this.sellPrice,
    this.buyPrice = 0,
    this.isActive = true,
  });

  /// Buat dari ItemUnit yang sudah ada di database
  factory ItemUnitDraft.fromUnit(ItemUnit unit) => ItemUnitDraft(
        id: unit.id,
        label: unit.label,
        quantityBase: unit.quantityBase,
        sellPrice: unit.sellPrice,
        buyPrice: unit.buyPrice,
        isActive: unit.isActive,
      );

  /// Default draft kosong
  factory ItemUnitDraft.empty() => ItemUnitDraft(
        label: '',
        quantityBase: 0,
        sellPrice: 0,
        buyPrice: 0,
      );

  bool get isNew => id == null;

  ItemUnitDraft copyWith({
    String? id,
    String? label,
    int? quantityBase,
    int? sellPrice,
    int? buyPrice,
    bool? isActive,
  }) =>
      ItemUnitDraft(
        id: id ?? this.id,
        label: label ?? this.label,
        quantityBase: quantityBase ?? this.quantityBase,
        sellPrice: sellPrice ?? this.sellPrice,
        buyPrice: buyPrice ?? this.buyPrice,
        isActive: isActive ?? this.isActive,
      );
}
