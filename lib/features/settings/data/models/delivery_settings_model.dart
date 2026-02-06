class DeliverySettingsModel {
  final bool isDeliveryEnabled;
  final String whatsappNumber;

  const DeliverySettingsModel({
    this.isDeliveryEnabled = false,
    this.whatsappNumber = '',
  });

  DeliverySettingsModel copyWith({
    bool? isDeliveryEnabled,
    String? whatsappNumber,
  }) {
    return DeliverySettingsModel(
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
    );
  }
}
