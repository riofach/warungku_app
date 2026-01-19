/// Supabase-related constants for WarungKu Digital
library;

class SupabaseConstants {
  SupabaseConstants._();

  // ===========================================
  // TABLE NAMES (snake_case as per PostgreSQL convention)
  // ===========================================
  
  static const String tableCategories = 'categories';
  static const String tableItems = 'items';
  static const String tableHousingBlocks = 'housing_blocks';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableSettings = 'settings';

  // ===========================================
  // STORAGE BUCKETS
  // ===========================================
  
  static const String bucketProductImages = 'product-images';

  // ===========================================
  // COLUMN NAMES - Categories
  // ===========================================
  
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // ===========================================
  // COLUMN NAMES - Items
  // ===========================================
  
  static const String colCategoryId = 'category_id';
  static const String colBuyPrice = 'buy_price';
  static const String colSellPrice = 'sell_price';
  static const String colStock = 'stock';
  static const String colStockThreshold = 'stock_threshold';
  static const String colImageUrl = 'image_url';
  static const String colIsActive = 'is_active';

  // ===========================================
  // COLUMN NAMES - Orders
  // ===========================================
  
  static const String colCode = 'code';
  static const String colHousingBlockId = 'housing_block_id';
  static const String colCustomerName = 'customer_name';
  static const String colPaymentMethod = 'payment_method';
  static const String colDeliveryType = 'delivery_type';
  static const String colStatus = 'status';
  static const String colTotal = 'total';

  // ===========================================
  // COLUMN NAMES - Order/Transaction Items
  // ===========================================
  
  static const String colOrderId = 'order_id';
  static const String colTransactionId = 'transaction_id';
  static const String colItemId = 'item_id';
  static const String colQuantity = 'quantity';
  static const String colPrice = 'price';
  static const String colSubtotal = 'subtotal';

  // ===========================================
  // COLUMN NAMES - Transactions
  // ===========================================
  
  static const String colCashReceived = 'cash_received';
  static const String colChange = 'change';
  static const String colAdminId = 'admin_id';

  // ===========================================
  // COLUMN NAMES - Settings
  // ===========================================
  
  static const String colKey = 'key';
  static const String colValue = 'value';

  // ===========================================
  // REALTIME CHANNELS
  // ===========================================
  
  static const String channelOrders = 'orders-channel';
  static const String channelItems = 'items-channel';

  // ===========================================
  // QUERY HELPERS
  // ===========================================
  
  /// Select all columns
  static const String selectAll = '*';

  /// Select items with category
  static const String selectItemsWithCategory = '''
    *,
    category:categories(id, name)
  ''';

  /// Select orders with housing block and items
  static const String selectOrdersWithDetails = '''
    *,
    housing_block:housing_blocks(id, name),
    order_items(
      *,
      item:items(id, name, image_url)
    )
  ''';

  /// Select transactions with items
  static const String selectTransactionsWithItems = '''
    *,
    transaction_items(
      *,
      item:items(id, name, image_url, sell_price)
    )
  ''';
}
