import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  Future<bool> signOut() async => true;
}

void main() {
  late MockOrderRepository mockOrderRepository;
  late MockAdminUser mockUser;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    mockUser = MockAdminUser();
    when(() => mockUser.email).thenReturn('test@admin.com');
    when(() => mockUser.name).thenReturn('Test Admin');
    when(() => mockUser.isOwner).thenReturn(true); // Default to owner
    when(() => mockUser.role).thenReturn('owner');
  });

  Widget createTestWidget(Widget child, {bool isOwner = true}) {
    // Update mock user based on role
    when(() => mockUser.isOwner).thenReturn(isOwner);
    when(() => mockUser.role).thenReturn(isOwner ? 'owner' : 'admin');

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        authNotifierProvider.overrideWith(() => MockAuthNotifier()),
      ],
      child: MaterialApp(
        home: child,
      ),
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
}
