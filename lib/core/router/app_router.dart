import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/models/user_role.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/operating_hours_screen.dart';
import '../../features/settings/presentation/screens/delivery_settings_screen.dart';
import '../../features/inventory/presentation/screens/items_screen.dart';
import '../../features/inventory/presentation/screens/item_form_screen.dart';
import '../../features/inventory/presentation/screens/categories_screen.dart';
import '../../features/inventory/data/models/item_model.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/admin_management/presentation/screens/admin_list_screen.dart';
import '../../features/transactions/presentation/screens/transaction_history_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/data/models/transaction_model.dart' as trx_model;
import '../../features/pos/presentation/screens/transaction_success_screen.dart';
import '../../features/inventory/presentation/screens/purchase_flow_screen.dart';
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
  static const String settingsOperatingHours = '/settings/operating-hours';
  static const String settingsDelivery = '/settings/delivery';
  static const String settingsGeneral = '/settings/general';
  static const String items = '/items';
  static const String itemEdit = '/items/edit';
  static const String categories = '/categories';
  static const String reports = '/reports';
  static const String adminManagement = '/admin-management';
  static const String transactionHistory = '/transaction-history';
  static const String transactionDetail = '/transactions/detail';
  static const String transactionSuccess = '/transaction-success';
  static const String purchaseFlow = '/purchase';
}

/// Routes a kasir is allowed to navigate to. Anything else triggers a
/// redirect to [AppRoutes.pos]. Allowlist (not denylist) so new owner-only
/// routes are blocked by default when they're added.
const _kasirAllowedRoutes = <String>{
  AppRoutes.login,
  AppRoutes.dashboard,
  AppRoutes.pos,
  AppRoutes.settings,
  AppRoutes.transactionSuccess,
};

/// Global key for root navigator
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider.
///
/// Redirect resolves in this order:
///   1. No session → /login (except when already on /login)
///   2. On /login + session + role resolved → route to default landing
///      (owner → /dashboard, kasir → /pos)
///   3. On /login + session + role unknown → stay on /login (loading)
///   4. Kasir trying to access a route not in [_kasirAllowedRoutes] → /pos
///   5. Role unknown + not on /login → /login (defensive default-deny)
final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod into GoRouter: whenever auth state or resolved role
  // changes, bump the ValueNotifier so GoRouter re-runs the redirect callback.
  final refresh = ValueNotifier<int>(0);
  ref.listen(supabaseAuthStateProvider, (_, __) => refresh.value++);
  ref.listen(userRoleProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = SupabaseService.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final role = ref.read(userRoleProvider);

      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isLoggingIn) {
        if (role == UserRole.owner) return AppRoutes.dashboard;
        if (role == UserRole.kasir) return AppRoutes.pos;
        // Role still loading — stay on /login until currentUserProvider
        // resolves. UI shows a small spinner there.
        return null;
      }

      if (role == UserRole.kasir &&
          !_kasirAllowedRoutes.contains(state.matchedLocation)) {
        return AppRoutes.pos;
      }

      // Defensive: authenticated session but role hasn't resolved AND we're
      // outside the login route. Hold at /login until role resolves so
      // owner-only routes aren't briefly mounted.
      if (role == null && isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

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
            path: AppRoutes.settingsOperatingHours,
            builder: (context, state) => const OperatingHoursScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsDelivery,
            builder: (context, state) => const DeliverySettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.items,
        builder: (context, state) => const ItemsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.itemEdit}/:id',
        redirect: (context, state) {
          if (state.extra == null) {
            return AppRoutes.items;
          }
          return null;
        },
        builder: (context, state) {
          final item = state.extra as Item?;
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
        path: AppRoutes.adminManagement,
        builder: (context, state) => const AdminListScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionHistory,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.transactionDetail}/:id',
        redirect: (context, state) {
          if (state.extra == null) return AppRoutes.reports;
          return null;
        },
        builder: (context, state) {
          final transaction = state.extra as trx_model.Transaction;
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: AppRoutes.transactionSuccess,
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return TransactionSuccessScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: AppRoutes.purchaseFlow,
        builder: (context, state) => const PurchaseFlowScreen(),
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
