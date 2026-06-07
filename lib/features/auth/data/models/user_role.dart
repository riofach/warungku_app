/// User role for warungku_app.
///
/// - [owner]: Pemilik warung. Akses penuh: Dashboard, POS (Kasir), Pesanan,
///   Laporan, Menu lengkap (kelola barang/kategori, laporan, pengaturan,
///   kelola akun, dev tools).
/// - [kasir]: Karyawan kasir. Akses terbatas: Dashboard, POS (Kasir), Menu
///   minimal (info akun + logout). Semua route owner-only di-redirect ke /pos.
enum UserRole {
  owner('owner'),
  kasir('kasir');

  final String value;
  const UserRole(this.value);

  /// Parse role from DB/metadata string. Returns null for null, unknown, or
  /// legacy values (e.g. 'admin') — caller must default-deny on null.
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }

  /// Human-readable label in Indonesian.
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.kasir:
        return 'Kasir';
    }
  }
}
