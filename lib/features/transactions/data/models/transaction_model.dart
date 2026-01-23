import 'package:intl/intl.dart';

/// Admin info embedded in transaction for display purposes
class TransactionAdmin {
  final String id;
  final String? name;
  final String email;

  const TransactionAdmin({required this.id, this.name, required this.email});

  factory TransactionAdmin.fromJson(Map<String, dynamic> json) {
    return TransactionAdmin(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }

  /// Get display name (name or email prefix)
  String get displayName => name ?? email.split('@').first;

  /// Get initials for avatar
  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final trimmedName = name!.trim();
      final parts = trimmedName.split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return trimmedName[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() => 'TransactionAdmin(id: $id, name: $displayName)';
}

/// Transaction item model for POS transactions
class TransactionItem {
  final String id;
  final String transactionId;
  final String? itemId;
  final String itemName;
  final int quantity;
  final int buyPrice;
  final int sellPrice;
  final int subtotal;
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    this.itemId,
    required this.itemName,
    required this.quantity,
    required this.buyPrice,
    required this.sellPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String? ?? 'Unknown Item',
      quantity: json['quantity'] as int? ?? 1,
      buyPrice: json['buy_price'] as int? ?? 0,
      sellPrice: json['sell_price'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Calculate profit for this item
  int get profit => (sellPrice - buyPrice) * quantity;

  @override
  String toString() => 'TransactionItem(name: $itemName, qty: $quantity)';
}

/// Transaction model for POS transactions at warung
/// Includes admin tracking for FR5
class Transaction {
  final String id;
  final String code;
  final String? adminId;
  final String paymentMethod;
  final int? cashReceived;
  final int? changeAmount;
  final int total;
  final DateTime createdAt;

  // Related data (loaded separately)
  final TransactionAdmin? admin;
  final List<TransactionItem> items;

  const Transaction({
    required this.id,
    required this.code,
    this.adminId,
    required this.paymentMethod,
    this.cashReceived,
    this.changeAmount,
    required this.total,
    required this.createdAt,
    this.admin,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Parse admin if included in query
    TransactionAdmin? admin;
    if (json['admin'] != null && json['admin'] is Map<String, dynamic>) {
      admin = TransactionAdmin.fromJson(json['admin'] as Map<String, dynamic>);
    }

    // Parse transaction items if included
    List<TransactionItem> items = [];
    if (json['transaction_items'] != null &&
        json['transaction_items'] is List) {
      items = (json['transaction_items'] as List)
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Transaction(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      adminId: json['admin_id'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      cashReceived: json['cash_received'] as int?,
      changeAmount: json['change_amount'] as int?,
      total: json['total'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      admin: admin,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'admin_id': adminId,
      'payment_method': paymentMethod,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if this is a cash transaction
  bool get isCash => paymentMethod == 'cash';

  /// Check if this is a QRIS transaction
  bool get isQris => paymentMethod == 'qris';

  /// Get formatted cash received
  String get formattedCashReceived {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(cashReceived ?? 0);
  }

  /// Get formatted total price
  String get formattedTotal {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(total);
  }

  /// Get formatted change amount
  String get formattedChange {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(changeAmount ?? 0);
  }

  /// Get formatted created date
  String get formattedDate {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(createdAt.toLocal());
  }

  /// Get short date (for list view)
  String get shortDate {
    final formatter = DateFormat('dd/MM HH:mm', 'id_ID');
    return formatter.format(createdAt.toLocal());
  }

  /// Get admin display name (for FR5)
  String get adminName => admin?.displayName ?? 'Unknown';

  /// Calculate total profit from all items
  int get totalProfit {
    return items.fold<int>(0, (sum, item) => sum + item.profit);
  }

  /// Get item count
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Copy with updated fields
  Transaction copyWith({
    String? id,
    String? code,
    String? adminId,
    String? paymentMethod,
    int? cashReceived,
    int? changeAmount,
    int? total,
    DateTime? createdAt,
    TransactionAdmin? admin,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      code: code ?? this.code,
      adminId: adminId ?? this.adminId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      admin: admin ?? this.admin,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'Transaction(code: $code, total: $total, admin: $adminName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
