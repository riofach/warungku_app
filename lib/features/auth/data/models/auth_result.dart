/// Auth result model for authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final String? successMessage;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.successMessage,
  });

  /// Success result
  factory AuthResult.success() => const AuthResult(success: true);

  /// Success result with custom message
  factory AuthResult.successWithMessage(String message) => AuthResult(
        success: true,
        successMessage: message,
      );

  /// Error result
  factory AuthResult.error(String message, {String? code}) => AuthResult(
        success: false,
        errorMessage: message,
        errorCode: code,
      );

  /// Error result from exception
  factory AuthResult.fromException(Object e) {
    String message = 'Terjadi kesalahan. Silakan coba lagi.';
    String? code;

    if (e is Exception) {
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid_credentials')) {
        message = 'Email atau password salah';
        code = 'invalid_credentials';
      } else if (errorString.contains('email not confirmed')) {
        message = 'Email belum dikonfirmasi';
        code = 'email_not_confirmed';
      } else if (errorString.contains('network') ||
          errorString.contains('socket') ||
          errorString.contains('connection')) {
        message = 'Tidak ada koneksi internet';
        code = 'network_error';
      } else if (errorString.contains('too many requests') ||
          errorString.contains('rate limit')) {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
        code = 'rate_limit';
      }
    }

    return AuthResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  @override
  String toString() =>
      'AuthResult(success: $success, errorMessage: $errorMessage, code: $errorCode)';
}
