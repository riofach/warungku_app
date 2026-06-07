import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/user_role.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../router/app_router.dart';

/// Main scaffold with role-aware bottom navigation.
///
/// - Owner: 5 tabs (Dashboard, Kasir, Pesanan, Laporan, Menu).
/// - Kasir: 4 tabs (Dashboard, Kasir, Pesanan, Menu) — kasir handles online
///   orders alongside POS.
/// - Unresolved role (loading): 3 tabs (Dashboard, Kasir, Menu) as a
///   default-deny holding state; once role resolves, tabs settle to the
///   role-specific layout.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final destinations = switch (role) {
      UserRole.owner => _ownerDestinations,
      UserRole.kasir => _kasirDestinations,
      null => _loadingDestinations,
    };
    final routes = switch (role) {
      UserRole.owner => _ownerRoutes,
      UserRole.kasir => _kasirRoutes,
      null => _loadingRoutes,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context, routes),
        onDestinationSelected: (index) => context.go(routes[index]),
        destinations: destinations,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, List<String> routes) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) return i;
    }
    return 0;
  }

  static const List<NavigationDestination> _ownerDestinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: 'Kasir',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Pesanan',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Laporan',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_outlined),
      selectedIcon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  static const List<String> _ownerRoutes = [
    AppRoutes.dashboard,
    AppRoutes.pos,
    AppRoutes.orders,
    AppRoutes.reports,
    AppRoutes.settings,
  ];

  static const List<NavigationDestination> _kasirDestinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: 'Kasir',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Pesanan',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_outlined),
      selectedIcon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  static const List<String> _kasirRoutes = [
    AppRoutes.dashboard,
    AppRoutes.pos,
    AppRoutes.orders,
    AppRoutes.settings,
  ];

  /// Loading state — role hasn't resolved yet. Show only the safe subset:
  /// Dashboard + Kasir + Menu. Once role lands the bar swaps to the
  /// role-specific layout.
  static const List<NavigationDestination> _loadingDestinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: 'Kasir',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_outlined),
      selectedIcon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  static const List<String> _loadingRoutes = [
    AppRoutes.dashboard,
    AppRoutes.pos,
    AppRoutes.settings,
  ];
}
