import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Order status enum matching database constraint
enum OrderStatus {
  pending,
  paid,
  processing,
  ready,
  delivered,
  completed,
  cancelled,
  failed;
  
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
  
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.paid:
        return 'Dibayar';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.delivered:
        return 'Diantar';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      case OrderStatus.failed:
        return 'Gagal';
    }
  }
  
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.paid:
        return AppColors.success;
      case OrderStatus.processing:
        return AppColors.primary;
      case OrderStatus.ready:
        return AppColors.secondary;
      case OrderStatus.delivered:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return AppColors.error;
    }
  }
  
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.paid:
        return Icons.check_circle;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.ready:
        return Icons.check_box;
      case OrderStatus.delivered:
        return Icons.delivery_dining;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.failed:
        return Icons.error;
    }
  }
}

/// Order model representing a website order
class Order {
  final String id;
  final String code;
  final String? housingBlockId;
  final String? housingBlockName;
  final String customerName;
  final String paymentMethod;
  final String deliveryType;
  final OrderStatus status;
  final int total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Order({
    required this.id,
    required this.code,
    this.housingBlockId,
    this.housingBlockName,
    required this.customerName,
    required this.paymentMethod,
    required this.deliveryType,
    required this.status,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle nested housing_block object
    String? blockName;
    if (json['housing_block'] != null) {
      blockName = json['housing_block']['name'] as String?;
    }
    
    return Order(
      id: json['id'] as String,
      code: json['code'] as String,
      housingBlockId: json['housing_block_id'] as String?,
      housingBlockName: blockName,
      customerName: json['customer_name'] as String,
      paymentMethod: json['payment_method'] as String,
      deliveryType: json['delivery_type'] as String,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      total: json['total'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  /// Get time ago string in Indonesian
  String get timeAgo => Formatters.formatRelativeTime(createdAt);

  Order copyWith({
    String? id,
    String? code,
    String? housingBlockId,
    String? housingBlockName,
    String? customerName,
    String? paymentMethod,
    String? deliveryType,
    OrderStatus? status,
    int? total,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      housingBlockId: housingBlockId ?? this.housingBlockId,
      housingBlockName: housingBlockName ?? this.housingBlockName,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryType: deliveryType ?? this.deliveryType,
      status: status ?? this.status,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
