class TopItem {
  final String itemId;
  final String itemName;
  final int totalQuantity;
  final int totalRevenue;

  const TopItem({
    required this.itemId,
    required this.itemName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      totalQuantity: (json['total_quantity'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toInt(),
    );
  }
}
