import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'item_unit_model.dart';

const Object _undefined = Object();

enum StockStatus { normal, low, outOfStock }

extension StockStatusExtension on StockStatus {
  Color get color {
    switch (this) {
      case StockStatus.normal:
        return AppColors.stockSafe;
      case StockStatus.low:
        return AppColors.stockWarning;
      case StockStatus.outOfStock:
        return AppColors.stockCritical;
    }
  }

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
  final bool hasUnits;
  final String baseUnit;
  final List<ItemUnit> units;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    this.hasUnits = false,
    this.baseUnit = 'pcs',
    this.units = const [],
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
  });

  StockStatus get stockStatus {
    if (stock == 0) return StockStatus.outOfStock;
    if (stock <= stockThreshold) return StockStatus.low;
    return StockStatus.normal;
  }

  List<ItemUnit> get activeUnits =>
      units.where((u) => u.isActive).toList()
        ..sort((a, b) => b.quantityBase.compareTo(a.quantityBase));

  /// Display stock string: "15,0 Kg" for gram items, "50 pcs" otherwise
  String get displayStock {
    if (hasUnits && baseUnit == 'gram') {
      return '${(stock / 1000).toStringAsFixed(1).replaceAll('.', ',')} Kg';
    }
    return '$stock $baseUnit';
  }

  /// Display unit label for input forms (e.g. "Kg" for gram items)
  String get inputUnitLabel {
    if (baseUnit == 'gram') return 'Kg';
    return baseUnit;
  }

  /// Factor to convert display input → stored base unit (1000 for gram→Kg)
  int get inputToBaseMultiplier => baseUnit == 'gram' ? 1000 : 1;

  factory Item.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    }

    final unitsList = <ItemUnit>[];
    if (json['item_units'] != null && json['item_units'] is List) {
      for (final u in json['item_units'] as List) {
        unitsList.add(ItemUnit.fromJson(u as Map<String, dynamic>));
      }
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
      hasUnits: json['has_units'] as bool? ?? false,
      baseUnit: json['base_unit'] as String? ?? 'pcs',
      units: unitsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      categoryName: catName,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'stock_threshold': stockThreshold,
        'image_url': imageUrl,
        'is_active': isActive,
        'has_units': hasUnits,
        'base_unit': baseUnit,
      };

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
    bool? hasUnits,
    String? baseUnit,
    List<ItemUnit>? units,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? categoryName = _undefined,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId:
          categoryId == _undefined ? this.categoryId : categoryId as String?,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      imageUrl: imageUrl == _undefined ? this.imageUrl : imageUrl as String?,
      isActive: isActive ?? this.isActive,
      hasUnits: hasUnits ?? this.hasUnits,
      baseUnit: baseUnit ?? this.baseUnit,
      units: units ?? this.units,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName == _undefined
          ? this.categoryName
          : categoryName as String?,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, name: $name, stock: $stock, hasUnits: $hasUnits)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
