import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../router/app_router.dart';

/// Main scaffold with role-aware bottom navigation.
///
/// - Owner: 5 tabs (Dashboard, Kasir, Pesanan, Laporan, Menu).
/// - Kasir (and any unresolved role): 3 tabs (Dashboard, Kasir, Menu).
///   Default-deny — owner-only tabs are hidden until role resolves to owner.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);
    final destinations = isOwner ? _ownerDestinations : _kasirDestinations;
    final routes = isOwner ? _ownerRoutes : _kasirRoutes;

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
      icon: Icon(Icons.menu_outlined),
      selectedIcon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  static const List<String> _kasirRoutes = [
    AppRoutes.dashboard,
    AppRoutes.pos,
    AppRoutes.settings,
  ];
}
