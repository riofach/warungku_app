/// Housing Block model for delivery location management
/// Represents a housing block stored in the housing_blocks table
class HousingBlock {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HousingBlock({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create HousingBlock from Supabase JSON response
  factory HousingBlock.fromJson(Map<String, dynamic> json) {
    return HousingBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      // Handle null timestamps safely
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API (insert/update)
  /// Only includes name as that's all that needs to be sent
  Map<String, dynamic> toJson() => {
        'name': name,
      };

  /// Create a copy with updated fields
  HousingBlock copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HousingBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'HousingBlock(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HousingBlock && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
