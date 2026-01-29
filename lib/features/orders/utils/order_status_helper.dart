class OrderStatusHelper {
  /// Returns the next status and the button text for the action.
  /// Returns null if no action is available (e.g. completed/cancelled).
  static (String, String)? getNextStatusAction(String currentStatus, {String? deliveryType}) {
    switch (currentStatus) {
      case 'pending':
      case 'paid':
        return ('processing', 'Proses Pesanan');
      case 'processing':
        if (deliveryType?.toLowerCase() == 'delivery') {
          return ('ready', 'Siap Diantar');
        } else if (deliveryType?.toLowerCase() == 'pickup') {
          return ('ready', 'Siap Diambil');
        }
        return ('ready', 'Siap Diantar/Diambil');
      case 'ready':
        return ('completed', 'Selesai');
      default:
        return null;
    }
  }
}
