/// Category model for inventory management
/// Represents a product category stored in the categories table
class Category {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount; // Computed from query, not stored

  const Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
  });

  /// Create Category from Supabase JSON response
  /// Handles nested items count from the query:
  /// select('id, name, created_at, updated_at, items(count)')
  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle nested items count from Supabase query
    // The query returns items as a list with count objects
    final itemsData = json['items'] as List?;
    int count = 0;
    if (itemsData != null && itemsData.isNotEmpty) {
      // Supabase returns [{count: X}] for count queries
      final firstItem = itemsData.first;
      if (firstItem is Map<String, dynamic>) {
        count = (firstItem['count'] as int?) ?? 0;
      }
    }

    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      // Handle null timestamps safely
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      itemCount: count,
    );
  }

  /// Convert to JSON for API (insert/update)
  /// Only includes name as that's all that needs to be sent
  Map<String, dynamic> toJson() => {
        'name': name,
      };

  /// Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, itemCount: $itemCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
