import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';
import 'package:warungku_app/features/auth/data/models/user_role.dart';
import 'package:warungku_app/features/auth/data/providers/auth_provider.dart';
import 'package:warungku_app/features/settings/presentation/widgets/account_header.dart';

void main() {
  testWidgets('AccountHeader renders user email and role badge', (tester) async {
    final testUser = AdminUser(
      id: '123',
      email: 'test@example.com',
      name: 'Owner Warung',
      role: UserRole.owner,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountHeader()),
        ),
      ),
    );
    await tester.pump(); // let stream emit

    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Owner Warung'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget); // role badge
  });

  testWidgets('AccountHeader renders Kasir badge for kasir', (tester) async {
    final kasir = AdminUser(
      id: '456',
      email: 'kasir@warung.com',
      name: 'Kasir Satu',
      role: UserRole.kasir,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(kasir)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountHeader()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kasir'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);
  });
}
