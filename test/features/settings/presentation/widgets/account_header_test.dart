import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/settings/presentation/widgets/account_header.dart';
import 'package:warungku_app/features/auth/data/providers/auth_provider.dart';
import 'package:warungku_app/features/auth/data/models/admin_user.dart';

void main() {
  testWidgets('AccountHeader renders user email', (WidgetTester tester) async {
    // Arrange
    final testUser = AdminUser(
      id: '123',
      email: 'test@example.com',
      role: 'admin',
      createdAt: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(AsyncValue.data(testUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AccountHeader(),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Profil Admin'), findsOneWidget);
  });
}
