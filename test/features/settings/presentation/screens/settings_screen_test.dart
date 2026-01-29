import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warungku_app/features/auth/data/providers/auth_provider.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';
import 'package:warungku_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:warungku_app/features/orders/data/repositories/order_repository.dart';

class MockOrderRepository extends Mock implements OrderRepository {}
class MockAdminUser extends Mock implements AdminUser {}

class MockAuthNotifier extends AuthNotifier {
  @override
  AppAuthState build() => AppAuthState.initial();
}

void main() {
  late MockOrderRepository mockOrderRepository;
  late MockAdminUser mockUser;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    mockUser = MockAdminUser();
    when(() => mockUser.email).thenReturn('test@admin.com');
    when(() => mockUser.isOwner).thenReturn(true);
  });

  testWidgets('SettingsScreen shows Simulation Button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          authNotifierProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          authNotifierProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

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
