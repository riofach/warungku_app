import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/utils/formatters.dart';

void main() {
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
  });
}
