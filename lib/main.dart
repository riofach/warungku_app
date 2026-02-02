import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/orders/presentation/widgets/new_order_notification_overlay_host.dart'; // Tambahkan ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: WarungKuApp(),
    ),
  );
}

class WarungKuApp extends ConsumerWidget {
  const WarungKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
