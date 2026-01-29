class OrderStatusHelper {
  /// Returns the next status and the button text for the action.
  /// Returns null if no action is available (e.g. completed/cancelled).
  static (String, String)? getNextStatusAction(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
      case 'paid':
        return ('processing', 'Proses Pesanan');
      case 'processing':
        return ('ready', 'Siap Diantar/Diambil');
      case 'ready':
        return ('completed', 'Selesai');
      default:
        return null;
    }
  }
}
