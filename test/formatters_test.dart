import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku_app/core/utils/formatters.dart';

void main() {
  // Initialize locale data before tests
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Formatters', () {
    test('formatRupiah should format correctly', () {
      expect(Formatters.formatRupiah(0), 'Rp 0');
      expect(Formatters.formatRupiah(1000), 'Rp 1.000');
      expect(Formatters.formatRupiah(15000), 'Rp 15.000');
      expect(Formatters.formatRupiah(1500000), 'Rp 1.500.000');
    });

    test('formatRupiahShort should format without prefix', () {
      expect(Formatters.formatRupiahShort(1000), '1.000');
      expect(Formatters.formatRupiahShort(15000), '15.000');
    });

    test('formatStock should return correct format', () {
      expect(Formatters.formatStock(0), 'Habis');
      expect(Formatters.formatStock(5, threshold: 10), 'Sisa 5');
      expect(Formatters.formatStock(15, threshold: 10), '15');
    });

    test('generateOrderCode should have correct format', () {
      final code = Formatters.generateOrderCode(1);
      expect(code.startsWith('WRG-'), true);
      expect(code.endsWith('-0001'), true);
    });

    test('generateTransactionCode should have correct format', () {
      final code = Formatters.generateTransactionCode(5);
      expect(code.startsWith('TRX-'), true);
      expect(code.endsWith('-0005'), true);
    });

    // Code Review Fix: Test for formatDateCompact
    test('formatDateCompact should format with short month', () {
      final testDate = DateTime(2026, 1, 15);
      final formatted = Formatters.formatDateCompact(testDate);
      // Should be in format "dd MMM yyyy" with Indonesian locale
      expect(formatted, contains('15'));
      expect(formatted, contains('2026'));
      // Check length is reasonable for "15 Jan 2026" format
      expect(formatted.length, greaterThanOrEqualTo(10));
    });
  });
}
