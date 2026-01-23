/// Transaction model for POS transactions
/// Represents a completed sale transaction with payment details
class Transaction {
  final String id;
  final String code;
  final String? adminId;
  final String paymentMethod;
  final int? cashReceived;
  final int? changeAmount;
  final int total;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.code,
    this.adminId,
    required this.paymentMethod,
    this.cashReceived,
    this.changeAmount,
    required this.total,
    required this.createdAt,
  });

  /// Create Transaction from JSON (from Supabase)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      code: json['code'] as String,
      adminId: json['admin_id'] as String?,
      paymentMethod: json['payment_method'] as String,
      cashReceived: json['cash_received'] as int?,
      changeAmount: json['change_amount'] as int?,
      total: json['total'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Transaction to JSON (for Supabase)
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

  Transaction copyWith({
    String? id,
    String? code,
    String? adminId,
    String? paymentMethod,
    int? cashReceived,
    int? changeAmount,
    int? total,
    DateTime? createdAt,
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
    );
  }
}

/// Transaction item model
/// Represents individual items in a transaction
class TransactionItem {
  final String id;
  final String transactionId;
  final String? itemId; // Nullable for history (item might be deleted)
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

  /// Create TransactionItem from JSON (from Supabase)
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as int,
      buyPrice: json['buy_price'] as int,
      sellPrice: json['sell_price'] as int,
      subtotal: json['subtotal'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert TransactionItem to JSON (for Supabase)
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

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? itemId,
    String? itemName,
    int? quantity,
    int? buyPrice,
    int? sellPrice,
    int? subtotal,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
