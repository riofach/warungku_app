/// App-wide constants for WarungKu Digital
library;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'WarungKu';
  static const String appVersion = '1.0.0';

  // Default Settings
  static const String defaultOperatingHoursOpen = '08:00';
  static const String defaultOperatingHoursClose = '21:00';
  static const int defaultStockThreshold = 10;

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Transaction Code Prefix
  static const String transactionCodePrefix = 'TRX';
  static const String orderCodePrefix = 'WRG';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentQris = 'qris';

  // Delivery Types
  static const String deliveryTypeDelivery = 'delivery';
  static const String deliveryTypePickup = 'pickup';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusPaid = 'paid';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';
  static const String orderStatusFailed = 'failed';

  // Settings Keys
  static const String settingOperatingHoursOpen = 'operating_hours_open';
  static const String settingOperatingHoursClose = 'operating_hours_close';
  static const String settingWhatsappNumber = 'whatsapp_number';
  static const String settingDeliveryEnabled = 'delivery_enabled';
  static const String settingWarungName = 'warung_name';
}
