# Changelog

Semua perubahan penting pada aplikasi WarungKu didokumentasikan di file ini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.0.0/),
dan proyek ini memakai [Semantic Versioning](https://semver.org/lang/id/).

## [1.3.0] - 2026-07-14

### Ditambahkan
- **Tombol "Download Invoice"** di detail transaksi kasir (POS) dan detail pesanan online. Tombol membuka halaman tracking web (`https://warungluthfan.my.id/tracking/{kode}`) sesuai kode pesanan, tempat invoice PDF bisa diunduh.
- **Riwayat Transaksi terpisah**: menu "Riwayat Transaksi" kini berisi dua sub-menu — **Riwayat Penjualan** (semua transaksi POS) dan **Riwayat Pembelian** (semua pencatatan pembelian / restock stok).
- **Pagination infinite-scroll** (±20 data per halaman) dan **filter rentang tanggal** (Dari–Sampai) pada Riwayat Penjualan & Riwayat Pembelian untuk mempermudah pelacakan.
- **Lokalisasi Bahasa Indonesia** untuk komponen Material (date range picker, dll.) melalui `flutter_localizations`.

### Diperbaiki
- Error `PGRST200 "Could not find a relationship between 'transactions' and 'users'"` di Riwayat Penjualan. Query transaksi tidak lagi mengandalkan foreign key `transactions → users` yang memang tidak ada di skema; nama admin dan nama item kini di-resolve lewat lookup batch terpisah.
- Crash `No MaterialLocalizations found` saat membuka filter tanggal (akibat aplikasi belum mendaftarkan `flutter_localizations`).

### Teknis
- Dependency baru: `url_launcher`, `flutter_localizations`.
- Widget/komponen reusable baru: `DownloadInvoiceButton`, `DateRangeFilterBar`, `PaginatedListView`, dan base `PaginatedHistoryNotifier`.
