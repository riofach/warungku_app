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

  const Purchase({
    required this.id,
    required this.itemId,
    this.adminId,
    required this.quantityBase,
    required this.totalCost,
    required this.costPerBase,
    this.notes,
    required this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
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
      );

  @override
  String toString() =>
      'Purchase(id: $id, itemId: $itemId, qty: $quantityBase, cost: $totalCost)';
}
