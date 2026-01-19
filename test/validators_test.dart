import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('should return error for empty email', () {
        expect(Validators.validateEmail(''), 'Email wajib diisi');
        expect(Validators.validateEmail(null), 'Email wajib diisi');
      });

      test('should return error for invalid email format', () {
        expect(Validators.validateEmail('invalid'), 'Format email tidak valid');
        expect(Validators.validateEmail('invalid@'), 'Format email tidak valid');
        expect(Validators.validateEmail('@test.com'), 'Format email tidak valid');
      });

      test('should return null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), null);
        expect(Validators.validateEmail('user.name@domain.co.id'), null);
      });
    });

    group('validatePassword', () {
      test('should return error for empty password', () {
        expect(Validators.validatePassword(''), 'Password wajib diisi');
        expect(Validators.validatePassword(null), 'Password wajib diisi');
      });

      test('should return error for short password', () {
        expect(Validators.validatePassword('12345'), 'Password minimal 6 karakter');
      });

      test('should return null for valid password', () {
        expect(Validators.validatePassword('123456'), null);
        expect(Validators.validatePassword('securePassword123'), null);
      });
    });

    group('validateRequired', () {
      test('should return error for empty value', () {
        expect(
          Validators.validateRequired('', fieldName: 'Nama'),
          'Nama wajib diisi',
        );
      });

      test('should return null for non-empty value', () {
        expect(Validators.validateRequired('John', fieldName: 'Nama'), null);
      });
    });

    group('validatePositiveNumber', () {
      test('should return error for empty value', () {
        expect(
          Validators.validatePositiveNumber('', fieldName: 'Stok'),
          'Stok wajib diisi',
        );
      });

      test('should return error for non-numeric value', () {
        expect(
          Validators.validatePositiveNumber('abc', fieldName: 'Stok'),
          'Masukkan angka yang valid',
        );
      });

      test('should return error for negative number', () {
        expect(
          Validators.validatePositiveNumber('-5', fieldName: 'Stok'),
          'Angka tidak boleh negatif',
        );
      });

      test('should return null for valid positive number', () {
        expect(Validators.validatePositiveNumber('10', fieldName: 'Stok'), null);
        expect(Validators.validatePositiveNumber('0', fieldName: 'Stok'), null);
      });
    });

    group('validateCustomerName', () {
      test('should return error for empty name', () {
        expect(Validators.validateCustomerName(''), 'Nama wajib diisi');
      });

      test('should return error for too short name', () {
        expect(Validators.validateCustomerName('A'), 'Nama minimal 2 karakter');
      });

      test('should return null for valid name', () {
        expect(Validators.validateCustomerName('John'), null);
        expect(Validators.validateCustomerName('Ahmad Wijaya'), null);
      });
    });
  });
}
