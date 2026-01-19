/// Validation utilities for form inputs
class Validators {
  Validators._();

  /// Check if email format is valid
  static bool isValidEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!isValidEmail(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validate password (min 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field ini'} wajib diisi';
    }
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field ini'} wajib diisi';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Masukkan angka yang valid';
    }
    if (number < 0) {
      return 'Angka tidak boleh negatif';
    }
    return null;
  }

  /// Validate price (positive number)
  static String? validatePrice(String? value) {
    return validatePositiveNumber(value, fieldName: 'Harga');
  }

  /// Validate stock (non-negative number)
  static String? validateStock(String? value) {
    return validatePositiveNumber(value, fieldName: 'Stok');
  }

  /// Validate phone number (Indonesian format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    // Remove non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  /// Validate customer name
  static String? validateCustomerName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }
}
