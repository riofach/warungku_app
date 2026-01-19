import 'package:intl/intl.dart';

/// Formatting utilities for currency, date, and other values
class Formatters {
  Formatters._();

  // Currency formatter for Indonesian Rupiah
  static final _currencyFormat = NumberFormat('#,###', 'id_ID');

  /// Format integer to Rupiah string: 3500 -> "Rp 3.500"
  static String formatRupiah(int amount) {
    return 'Rp ${_currencyFormat.format(amount)}';
  }

  /// Format integer to short Rupiah: 3500 -> "3.500"
  static String formatRupiahShort(int amount) {
    return _currencyFormat.format(amount);
  }

  /// Format DateTime to Indonesian date: "15 Januari 2026"
  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  /// Format DateTime to Indonesian date with time: "15 Januari 2026, 10:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  /// Format DateTime to short date: "15/01/2026"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format DateTime to time only: "10:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format DateTime to relative time: "5 menit yang lalu"
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Format stock with indicator
  static String formatStock(int stock, {int threshold = 10}) {
    if (stock == 0) {
      return 'Habis';
    } else if (stock <= threshold) {
      return 'Sisa $stock';
    }
    return '$stock';
  }

  /// Format order code: WRG-20260115-0001
  static String generateOrderCode(int sequence) {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final seqStr = sequence.toString().padLeft(4, '0');
    return 'WRG-$dateStr-$seqStr';
  }

  /// Format transaction code: TRX-20260115-0001
  static String generateTransactionCode(int sequence) {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final seqStr = sequence.toString().padLeft(4, '0');
    return 'TRX-$dateStr-$seqStr';
  }
}
