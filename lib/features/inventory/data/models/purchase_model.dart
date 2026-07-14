import '../../../../core/utils/formatters.dart';

/// Record of a stock purchase / restock event
class Purchase {
  final String id;
  final String itemId;
  final String? adminId;
  final int quantityBase;
  final int totalCost;
  final double costPerBase;
  final String? notes;
  final DateTime createdAt;

  /// Item name, populated from the `items(name)` join when listing purchases.
  /// Not a `purchases` column — null when the join isn't selected.
  final String? itemName;

  const Purchase({
    required this.id,
    required this.itemId,
    this.adminId,
    required this.quantityBase,
    required this.totalCost,
    required this.costPerBase,
    this.notes,
    required this.createdAt,
    this.itemName,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    // Nested item from `items(name)` embed, when present.
    final itemData = json['items'];
    return Purchase(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      adminId: json['admin_id'] as String?,
      quantityBase: json['quantity_base'] as int? ?? 0,
      totalCost: json['total_cost'] as int? ?? 0,
      costPerBase: (json['cost_per_base'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      itemName: itemData is Map<String, dynamic>
          ? itemData['name'] as String?
          : null,
    );
  }

  /// Display name — item name from join, falling back to a generic label.
  String get displayName => itemName ?? 'Barang';

  /// Total purchase cost, formatted as Rupiah.
  String get formattedTotalCost => Formatters.formatRupiah(totalCost);

  /// Cost per base unit, formatted as Rupiah (rounded).
  String get formattedCostPerBase =>
      Formatters.formatRupiah(costPerBase.round());

  /// Created date/time formatted for display (id_ID).
  String get formattedDate => Formatters.formatDateTime(createdAt);

  @override
  String toString() =>
      'Purchase(id: $id, itemId: $itemId, qty: $quantityBase, cost: $totalCost)';
}
