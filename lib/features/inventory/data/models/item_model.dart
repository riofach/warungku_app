import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Sentinel object for copyWith nullable field handling
const Object _undefined = Object();

/// Stock status enum for visual indicators
/// Determines the color and label of stock badges
enum StockStatus {
  /// Stock is above threshold - normal level
  normal,

  /// Stock is at or below threshold - low level warning
  low,

  /// Stock is zero - out of stock critical
  outOfStock,
}

/// Extension on StockStatus for color and label helpers
extension StockStatusExtension on StockStatus {
  /// Get the color for this stock status
  Color get color {
    switch (this) {
      case StockStatus.normal:
        return AppColors.stockSafe; // Green #10B981
      case StockStatus.low:
        return AppColors.stockWarning; // Yellow #F59E0B
      case StockStatus.outOfStock:
        return AppColors.stockCritical; // Red #EF4444
    }
  }

  /// Get the Indonesian label for this stock status
  String get label {
    switch (this) {
      case StockStatus.normal:
        return 'Tersedia';
      case StockStatus.low:
        return 'Stok Menipis';
      case StockStatus.outOfStock:
        return 'Habis';
    }
  }

  /// Get the icon for this stock status
  IconData get icon {
    switch (this) {
      case StockStatus.normal:
        return Icons.check_circle;
      case StockStatus.low:
        return Icons.warning;
      case StockStatus.outOfStock:
        return Icons.error;
    }
  }
}

/// Item model for inventory management
/// Represents a product stored in the items table
class Item {
  final String id;
  final String? categoryId;
  final String name;
  final int buyPrice;
  final int sellPrice;
  final int stock;
  final int stockThreshold;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional: Category name from join query
  final String? categoryName;

  const Item({
    required this.id,
    this.categoryId,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    this.stockThreshold = 10,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
  });

  /// Computed property for stock status
  /// Determines visual indicator based on stock vs threshold
  StockStatus get stockStatus {
    if (stock == 0) return StockStatus.outOfStock;
    if (stock <= stockThreshold) return StockStatus.low;
    return StockStatus.normal;
  }

  /// Create Item from Supabase JSON response
  /// Handles nested category from join query:
  /// select('*, categories(name)')
  factory Item.fromJson(Map<String, dynamic> json) {
    // Handle nested category from join
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    }

    return Item(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      buyPrice: json['buy_price'] as int? ?? 0,
      sellPrice: json['sell_price'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      stockThreshold: json['stock_threshold'] as int? ?? 10,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      categoryName: catName,
    );
  }

  /// Convert to JSON for API operations (insert/update)
  /// Excludes id, created_at as those are managed by database
  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'stock_threshold': stockThreshold,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  /// Create a copy with updated fields
  /// Uses sentinel pattern to allow setting nullable fields to null
  /// Example: item.copyWith(categoryId: null) will set categoryId to null
  Item copyWith({
    String? id,
    Object? categoryId = _undefined,
    String? name,
    int? buyPrice,
    int? sellPrice,
    int? stock,
    int? stockThreshold,
    Object? imageUrl = _undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? categoryName = _undefined,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId: categoryId == _undefined
          ? this.categoryId
          : categoryId as String?,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      imageUrl: imageUrl == _undefined ? this.imageUrl : imageUrl as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName == _undefined
          ? this.categoryName
          : categoryName as String?,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, name: $name, stock: $stock, status: $stockStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
