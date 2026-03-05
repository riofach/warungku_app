// lib/core/services/local_notification_service.dart
// Story 7-8: Android Push Notification saat Order Baru Masuk
//
// Service untuk menampilkan notifikasi lokal Android (flutter_local_notifications).
// Tidak menggunakan Firebase FCM — trigger sudah ada di client (Supabase Realtime).
//
// Pattern dua tahap:
//   1. initialize()       — setup plugin saja, dipanggil di main() SEBELUM runApp()
//   2. requestPermission() — minta izin notifikasi, dipanggil SETELAH widget tree aktif
//                            (via addPostFrameCallback di _WarungKuAppState.initState())
//
// Alasan pemisahan: requestNotificationsPermission() membutuhkan Android Activity
// yang sudah aktif. Memanggil sebelum runApp() menyebabkan dialog izin tidak muncul.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// Provider untuk LocalNotificationService — dapat diakses via Riverpod.
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

/// Service untuk menampilkan notifikasi push lokal Android.
///
/// Menggunakan [FlutterLocalNotificationsPlugin] untuk menampilkan
/// heads-up notification saat order baru masuk dari website.
///
/// **Pola Penggunaan (Dua Tahap):**
/// 1. [initialize()] — setup plugin saja, WAJIB dipanggil di `main()` SEBELUM `runApp()`.
/// 2. [requestPermission()] — request izin notifikasi Android 13+, dipanggil
///    SETELAH widget tree aktif (via `addPostFrameCallback` di `_WarungKuAppState.initState()`).
///
/// Jika izin ditolak, in-app banner (Story 7-7) tetap berfungsi sebagai fallback.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel ID dan nama untuk pesanan masuk
  static const _channelId = 'orders_channel';
  static const _channelName = 'Pesanan Masuk';
  static const _channelDesc = 'Notifikasi untuk pesanan baru dari website';

  /// **Tahap 1**: Inisialisasi plugin notifikasi.
  ///
  /// Dipanggil sekali di [main()] sebelum [runApp()].
  /// Hanya setup plugin dan callback tap — TIDAK melakukan request izin.
  /// Request izin dilakukan terpisah via [requestPermission()].
  static Future<void> initialize() async {
    debugPrint('[LOCAL_NOTIFICATION] 🔧 Initializing plugin...');

    // Konfigurasi inisialisasi untuk Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    // Inisialisasi plugin dengan callback untuk tap notifikasi
    final initialized = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    debugPrint('[LOCAL_NOTIFICATION] ✅ Plugin initialized: $initialized');
  }

  /// **Tahap 2**: Request izin notifikasi untuk Android 13+ (API 33+).
  ///
  /// WAJIB dipanggil SETELAH widget tree aktif agar Android Activity sudah
  /// tersedia. Gunakan `addPostFrameCallback` di `_WarungKuAppState.initState()`.
  ///
  /// Jika ditolak, hanya log warning — in-app banner tetap sebagai fallback.
  static Future<void> requestPermission() async {
    debugPrint('[LOCAL_NOTIFICATION] 🔑 Requesting notification permission...');

    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint('[LOCAL_NOTIFICATION] 📋 Permission granted: $granted');
      } else {
        debugPrint(
          '[LOCAL_NOTIFICATION] ℹ️ Not Android — permission request skipped',
        );
      }
    } catch (e) {
      // Jangan crash jika permission request gagal — fallback ke in-app banner
      debugPrint(
        '[LOCAL_NOTIFICATION] ⚠️ Permission request failed (non-fatal): $e',
      );
    }
  }

  /// Callback saat notifikasi di-tap oleh user.
  ///
  /// Menggunakan [rootNavigatorKey] dari [app_router.dart] untuk
  /// navigate ke halaman Pesanan ([AppRoutes.orders]).
  /// AC 3: Tap notifikasi → navigate ke halaman Pesanan.
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      '[LOCAL_NOTIFICATION] 👆 Notification tapped. Payload: ${response.payload}',
    );

    // Navigate ke halaman Pesanan menggunakan rootNavigatorKey
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go(AppRoutes.orders);
      debugPrint('[LOCAL_NOTIFICATION] ✅ Navigated to orders screen');
    } else {
      debugPrint(
        '[LOCAL_NOTIFICATION] ⚠️ Could not navigate — context is null',
      );
    }
  }

  /// Tampilkan notifikasi push Android untuk order baru.
  ///
  /// AC 2: Notifikasi muncul dalam ≤5 detik dengan judul "🛒 Pesanan Baru!"
  /// dan isi "[nama customer] — tap untuk lihat detail".
  ///
  /// [orderId] digunakan sebagai unique notification ID (via hashCode).
  /// [customerName] ditampilkan di body notifikasi.
  /// [orderCode] disimpan sebagai payload untuk referensi.
  Future<void> showNewOrderNotification({
    required String orderId,
    required String customerName,
    required String orderCode,
  }) async {
    debugPrint(
      '[LOCAL_NOTIFICATION] 🔔 Showing notification for order: $orderCode ($customerName)',
    );

    try {
      // Konfigurasi channel Android dengan importance HIGH untuk heads-up notification
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance:
            Importance.high, // AC 2: HIGH importance = heads-up notification
        priority: Priority.high,
        playSound: true, // AC 2: suara notifikasi default sistem
        enableVibration: true,
        ticker: 'Pesanan baru',
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      // AC 2: Judul "🛒 Pesanan Baru!" dan isi "[nama customer] — tap untuk lihat detail"
      // AC 5: orderId.hashCode sebagai notification ID → tidak ada duplikat per order
      await _plugin.show(
        orderId.hashCode, // Unique per order ID
        '🛒 Pesanan Baru!', // AC 2: Judul
        '$customerName — tap untuk lihat detail', // AC 2: Isi
        details,
        payload: orderId, // Untuk navigasi saat tap
      );

      debugPrint('[LOCAL_NOTIFICATION] ✅ Notification shown for: $orderCode');
    } catch (e) {
      // Jangan crash jika notifikasi gagal — in-app banner tetap berfungsi
      debugPrint(
        '[LOCAL_NOTIFICATION] ⚠️ Failed to show notification (non-fatal): $e',
      );
    }
  }
}
