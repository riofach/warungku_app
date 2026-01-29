import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/inventory/presentation/screens/items_screen.dart';
import '../../features/inventory/presentation/screens/item_form_screen.dart';
import '../../features/inventory/presentation/screens/categories_screen.dart';
import '../../features/inventory/presentation/screens/housing_blocks_screen.dart';
import '../../features/inventory/data/models/item_model.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/admin_management/presentation/screens/admin_list_screen.dart';
import '../../features/transactions/presentation/screens/transaction_history_screen.dart';
import '../../features/pos/presentation/screens/transaction_success_screen.dart';
import '../../features/pos/data/models/transaction_model.dart';
import '../services/supabase_service.dart';
import '../widgets/main_scaffold.dart';

/// App routes
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String pos = '/pos';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/detail';
  static const String settings = '/settings';
  static const String items = '/items';
  static const String itemAdd = '/items/add';
  static const String itemEdit = '/items/edit'; // Story 3.5: Edit route base
  static const String categories = '/categories';
  static const String housingBlocks = '/housing-blocks';
  static const String reports = '/reports';
  static const String adminManagement = '/admin-management';
  static const String transactionHistory = '/transaction-history';
  static const String transactionSuccess = '/transaction-success';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: kDebugMode, // Only log in debug mode
    redirect: (context, state) {
      final isLoggedIn = SupabaseService.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Login route (no scaffold)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app with shell (bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),

      // Standalone routes (pushed on top)
      GoRoute(
        path: AppRoutes.items,
        builder: (context, state) => const ItemsScreen(),
      ),
      GoRoute(
        path: AppRoutes.itemAdd,
        builder: (context, state) => const ItemFormScreen(),
      ),
      // Story 3.5: Edit item route (AC1, AC5)
      // Path: /items/edit/:id
      // Item data passed via extra parameter
      // H4 fix: Handle null extra gracefully - redirect to items list if no data
      GoRoute(
        path: '${AppRoutes.itemEdit}/:id',
        redirect: (context, state) {
          // If extra is null (e.g., deep link), redirect to items list
          if (state.extra == null) {
            return AppRoutes.items;
          }
          return null;
        },
        builder: (context, state) {
          // Get item from extra parameter (guaranteed non-null by redirect)
          final item = state.extra as Item?;
          // Debug: Log item details
          debugPrint('[ROUTER] Building ItemFormScreen. itemId=${state.uri.pathSegments.last}, item=$item');
          if (item != null) {
            debugPrint('[ROUTER] item.imageUrl: ${item.imageUrl}, item.name: ${item.name}');
          } else {
            debugPrint('[ROUTER] item is null - this should not happen after redirect');
          }
          return ItemFormScreen(item: item);
        },
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.housingBlocks,
        builder: (context, state) => const HousingBlocksScreen(),
      ),
      // AppRoutes.reports moved to ShellRoute
      GoRoute(
        path: AppRoutes.adminManagement,
        builder: (context, state) => const AdminListScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionHistory,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionSuccess,
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return TransactionSuccessScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
    ],
  );
});
