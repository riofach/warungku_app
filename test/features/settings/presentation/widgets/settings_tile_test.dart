import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/settings/presentation/widgets/settings_tile.dart';

void main() {
  testWidgets('SettingsTile renders title and subtitle', (WidgetTester tester) async {
    // Arrange
    const title = 'Test Title';
    const subtitle = 'Test Subtitle';
    const icon = Icons.settings;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsTile(
            title: title,
            subtitle: subtitle,
            icon: icon,
            onTap: () {},
          ),
        ),
      ),
    );

    // Assert
    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
    expect(find.byIcon(icon), findsOneWidget);
  });
}
