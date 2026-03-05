import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/supabase_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/realtime_connection_monitor.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/orders/presentation/widgets/new_order_notification_overlay_host.dart';
import 'features/dashboard/data/providers/new_orders_provider.dart';
import 'features/orders/data/providers/orders_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await SupabaseService.initialize();

  // Story 7-8: Inisialisasi local notification service SEBELUM runApp()
  // WAJIB dipanggil di sini karena FlutterLocalNotificationsPlugin
  // harus diinisialisasi di luar widget tree.
  await LocalNotificationService.initialize();

  runApp(const ProviderScope(child: WarungKuApp()));
}

class WarungKuApp extends ConsumerStatefulWidget {
  const WarungKuApp({super.key});

  @override
  ConsumerState<WarungKuApp> createState() => _WarungKuAppState();
}

class _WarungKuAppState extends ConsumerState<WarungKuApp>
    with WidgetsBindingObserver {
  RealtimeConnectionMonitor? _connectionMonitor;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize connection monitor and realtime subscriptions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start connection monitoring
      ref.read(connectionMonitorProvider).startMonitoring();

      // Initialize newOrdersProvider immediately so the [NEW_ORDERS] Supabase
      // Realtime channel is active from app startup (via ref.keepAlive).
      // This ensures banner notifications work on ALL screens, not just Dashboard.
      ref.read(newOrdersProvider);

      // Initialize ordersProvider immediately so the 30-second polling timer
      // and notification-detection logic are active from app startup.
      // This is the RELIABLE fallback for notifications when Supabase Realtime
      // events are missed. Uses ref.keepAlive() internally to stay alive.
      ref.read(ordersProvider);

      // Story 7-8: Request izin notifikasi SETELAH widget tree aktif.
      // Dipanggil di sini (bukan di main()) agar Android Activity sudah tersedia,
      // sehingga dialog izin notifikasi benar-benar muncul ke user.
      LocalNotificationService.requestPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionMonitor?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pause/resume connection monitoring based on app lifecycle
    if (state == AppLifecycleState.paused) {
      debugPrint(
        '[WARUNGKU_APP] App paused - connection monitoring continues in background',
      );
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[WARUNGKU_APP] App resumed - checking connection state');
      // Trigger a connection check when app resumes
      ref.read(connectionMonitorProvider).startMonitoring();
    }
  }

  void _showConnectionNotification(String message, Color color) {
    // Use a microtask to avoid build-phase issues
    Future.microtask(() {
      if (mounted) {
        // Find the scaffold messenger context
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  color == Colors.green ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to connection state changes for global notifications
    ref.listen<ConnectionState>(connectionStateProvider, (previous, next) {
      if (previous != next) {
        debugPrint(
          '[WARUNGKU_APP] Connection state changed: $previous → $next',
        );

        // Show snackbar notification for significant state changes
        if (next == ConnectionState.polling &&
            previous == ConnectionState.reconnecting) {
          _showConnectionNotification(
            'Mode polling aktif - Update real-time tidak tersedia',
            Colors.orange,
          );
        } else if (next == ConnectionState.connected &&
            (previous == ConnectionState.reconnecting ||
                previous == ConnectionState.polling)) {
          _showConnectionNotification(
            'Terhubung kembali - Update real-time aktif',
            Colors.green,
          );
        }
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WarungKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return NewOrderNotificationOverlayHost(child: child!);
      },
    );
  }
}
