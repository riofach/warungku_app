import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/core/router/app_router.dart';
import 'package:warungku_app/features/auth/data/providers/auth_provider.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';
import 'package:warungku_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';
import 'package:warungku_app/features/settings/presentation/widgets/account_header.dart';
import 'package:warungku_app/features/settings/presentation/widgets/settings_tile.dart';

class MockOrderRepository extends Mock implements OrderRepository {}
class MockAdminUser extends Mock implements AdminUser {}

class MockAuthNotifier extends AuthNotifier {
  @override
  AppAuthState build() => AppAuthState.authenticated();

  @override
  Future<bool> signOut() async {
    // Record that signOut was called
    return super.signOut();
  }
}

// Create a mock class to track signOut calls since we can't easily spy on the notifier method directly
class AuthListener extends Mock {
  void onSignOut();
}

void main() {
  late MockOrderRepository mockOrderRepository;
  late MockAdminUser mockUser;
  late AuthListener mockAuthListener;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    mockUser = MockAdminUser();
    mockAuthListener = AuthListener();
    when(() => mockUser.email).thenReturn('test@admin.com');
    when(() => mockUser.name).thenReturn('Test Admin');
    when(() => mockUser.isOwner).thenReturn(true); // Default to owner
    when(() => mockUser.role).thenReturn('owner');
  });

  Widget createTestWidget(Widget child, {bool isOwner = true, GoRouter? router}) {
    // Update mock user based on role
    when(() => mockUser.isOwner).thenReturn(isOwner);
    when(() => mockUser.role).thenReturn(isOwner ? 'owner' : 'admin');

    return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        authNotifierProvider.overrideWith(() {
          final notifier = MockAuthNotifier();
          // We can't easily spy on the notifier here, so we'll rely on the side effects or return value if needed
          // But for this test, we'll verify the interaction differently or assume it works if UI updates
          // Actually, let's just mock the signOut method in the MockAuthNotifier if needed
          return notifier;
        }),
      ],
      child: router != null 
          ? MaterialApp.router(routerConfig: router)
          : MaterialApp(home: child),
    );
  }

  testWidgets('SettingsScreen renders all sections', (tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));

    expect(find.byType(AccountHeader), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Kelola Data'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
    
    // Scroll to bottom to find Pengaturan and Admin
    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Pengaturan'),
      500,
      scrollable: scrollable,
    );
    expect(find.text('Pengaturan'), findsOneWidget);
    
    // Check for specific tiles
    await tester.drag(scrollable, const Offset(0, 500)); // Scroll up
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SettingsTile, 'Barang'), findsOneWidget);
    expect(find.widgetWithText(SettingsTile, 'Laporan Penjualan'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows Admin section for owner', (tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen(), isOwner: true));

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Admin'),
      500,
      scrollable: scrollable,
    );

    expect(find.text('Admin'), findsOneWidget);
    expect(find.widgetWithText(SettingsTile, 'Kelola Admin'), findsOneWidget);
  });

  testWidgets('SettingsScreen hides Admin section for non-owner', (tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen(), isOwner: false));

    expect(find.text('Admin'), findsNothing);
    expect(find.widgetWithText(SettingsTile, 'Kelola Admin'), findsNothing);
  });

  testWidgets('SettingsScreen shows Simulation Button', (tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));

    final scrollable = find.byType(Scrollable);
    expect(scrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Simulasi Pesanan Baru'),
      500,
      scrollable: scrollable,
    );

    expect(find.text('Development Tools'), findsOneWidget);
    expect(find.text('Simulasi Pesanan Baru'), findsOneWidget);
  });

  testWidgets('Clicking Simulation Button calls createDummyOrder', (tester) async {
    when(() => mockOrderRepository.createDummyOrder()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
    });

    await tester.pumpWidget(createTestWidget(const SettingsScreen()));

    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Simulasi Pesanan Baru'),
      500,
      scrollable: scrollable,
    );
    
    await tester.tap(find.text('Simulasi Pesanan Baru'));
    await tester.pump(); // Start animation
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pump(const Duration(milliseconds: 250)); // Finish future
    await tester.pumpAndSettle();

    verify(() => mockOrderRepository.createDummyOrder()).called(1);
    expect(find.text('Simulated Order Created!'), findsOneWidget);
  });

  // AC1: Navigation Tests
  testWidgets('Tapping "Barang" navigates to ItemsScreen', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
        GoRoute(path: AppRoutes.items, builder: (_, __) => const Scaffold(body: Text('Items Screen'))),
      ],
    );

    await tester.pumpWidget(createTestWidget(const SettingsScreen(), router: router));

    await tester.tap(find.text('Barang'));
    await tester.pumpAndSettle();

    expect(find.text('Items Screen'), findsOneWidget);
  });

  testWidgets('Tapping "Laporan Penjualan" navigates to ReportsScreen', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
        GoRoute(path: AppRoutes.reports, builder: (_, __) => const Scaffold(body: Text('Reports Screen'))),
      ],
    );

    await tester.pumpWidget(createTestWidget(const SettingsScreen(), router: router));

    await tester.tap(find.text('Laporan Penjualan'));
    await tester.pumpAndSettle();

    expect(find.text('Reports Screen'), findsOneWidget);
  });

  // AC3: Logout Tests
  testWidgets('Logout flow works correctly', (tester) async {
    // Create a specialized mock for this test
    final signOutTracker = MockFunction();
    when(() => signOutTracker.call()).thenAnswer((_) async => true);

    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const Scaffold(body: Text('Login Screen'))),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(mockUser)),
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          authNotifierProvider.overrideWith(() => MockAuthNotifierWithTracker(signOutTracker)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Scroll to bottom to find Logout
    final scrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Keluar'),
      500,
      scrollable: scrollable,
    );

    // Tap Logout button
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog
    // "Keluar" appears 3 times: 
    // 1. The original "Keluar" button on the screen
    // 2. The title of the dialog "Keluar"
    // 3. The confirmation button "Keluar"
    expect(find.text('Keluar'), findsNWidgets(3)); 
    expect(find.text('Yakin ingin keluar?'), findsOneWidget);

    // Tap Confirm (Keluar) - finding the button in the dialog
    // The dialog actions are at the bottom. We can find by text 'Keluar' which is in the TextButton
    final confirmButton = find.widgetWithText(TextButton, 'Keluar');
    await tester.tap(confirmButton);

    await tester.pumpAndSettle();

    // Verify signOut called
    verify(() => signOutTracker.call()).called(1);

    // Verify navigation to Login
    expect(find.text('Login Screen'), findsOneWidget);
  });
}

class MockFunction extends Mock {
  Future<bool> call();
}

class MockAuthNotifierWithTracker extends AuthNotifier {
  final MockFunction tracker;
  MockAuthNotifierWithTracker(this.tracker);

  @override
  AppAuthState build() => AppAuthState.authenticated();

  @override
  Future<bool> signOut() async {
    return tracker.call();
  }
}
