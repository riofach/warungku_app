import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Format DateTime to Indonesian date in WIB: "15 Januari 2026"
  static String formatDate(DateTime date) {
    final wibDate = toWIB(date);
    return DateFormat('d MMMM yyyy', 'id_ID').format(wibDate);
  }

  /// Konversi DateTime UTC ke WIB (Asia/Jakarta, UTC+7)
  static DateTime toWIB(DateTime date) {
    // Jika date sudah dalam UTC atau local, konversi ke WIB
    return date.toUtc().add(const Duration(hours: 7));
  }

  /// Format DateTime to Indonesian date with time in WIB: "15 Januari 2026, 10:30"
  static String formatDateTime(DateTime date) {
    final wibDate = toWIB(date);
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(wibDate);
  }

  /// Format DateTime to short date in WIB: "15/01/2026"
  static String formatDateShort(DateTime date) {
    final wibDate = toWIB(date);
    return DateFormat('dd/MM/yyyy').format(wibDate);
  }

  /// Format DateTime to compact date with short month in WIB: "15 Jan 2026"
  /// Used for admin list cards, compact displays
  static String formatDateCompact(DateTime date) {
    final wibDate = toWIB(date);
    return DateFormat('dd MMM yyyy', 'id_ID').format(wibDate);
  }

  /// Format DateTime to time only in WIB: "10:30"
  static String formatTime(DateTime date) {
    final wibDate = toWIB(date);
    return DateFormat('HH:mm').format(wibDate);
  }

  /// Format DateTime to relative time in WIB: "5 menit yang lalu"
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB now
    final wibDate = toWIB(date);
    final difference = now.difference(wibDate);

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

  /// Format TimeOfDay to "HH:mm" (e.g. 08:30)
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parse "HH:mm" string to TimeOfDay
  static TimeOfDay parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) throw const FormatException("Invalid time format");
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      rethrow;
    }
  }
}

/// Global convenience functions
String formatRupiah(int amount) => Formatters.formatRupiah(amount);
String formatDate(DateTime date) => Formatters.formatDate(date);
String formatDateTime(DateTime date) => Formatters.formatDateTime(date);

/// Rupiah input formatter for price fields
/// Converts input to formatted Rupiah: 3500 -> 3.500
/// Use with TextFormField inputFormatters
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse and format with thousand separators
    final number = int.parse(digitsOnly);
    final formatted = _formatWithSeparator(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(int number) {
    final chars = number.toString().split('').reversed.toList();
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add('.');
      }
      result.add(chars[i]);
    }
    return result.reversed.join();
  }
}
