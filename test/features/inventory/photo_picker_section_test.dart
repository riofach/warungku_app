import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/presentation/widgets/photo_picker_section.dart';

void main() {
  group('PhotoPickerSection', () {
    testWidgets('should render placeholder when no image selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPickerSection(
              selectedImage: null,
              onImageSelected: (_) {},
              onImageRemoved: () {},
            ),
          ),
        ),
      );

      // Should show placeholder icon
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.text('Tap untuk menambah foto'), findsOneWidget);
      expect(find.text('Maksimal 5MB (JPEG, PNG)'), findsOneWidget);
    });

    testWidgets('should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPickerSection(
              selectedImage: null,
              onImageSelected: (_) {},
              onImageRemoved: () {},
            ),
          ),
        ),
      );

      // Should be wrapped in GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should show bottom sheet on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPickerSection(
              selectedImage: null,
              onImageSelected: (_) {},
              onImageRemoved: () {},
            ),
          ),
        ),
      );

      // Tap the photo picker
      await tester.tap(find.byType(PhotoPickerSection));
      await tester.pumpAndSettle();

      // Should show bottom sheet with options
      expect(find.text('Pilih Foto'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('should not show "Hapus Foto" when no image selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPickerSection(
              selectedImage: null,
              onImageSelected: (_) {},
              onImageRemoved: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PhotoPickerSection));
      await tester.pumpAndSettle();

      // Should NOT show "Hapus Foto" option
      expect(find.text('Hapus Foto'), findsNothing);
    });

    testWidgets('should close bottom sheet on "Batal" tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPickerSection(
              selectedImage: null,
              onImageSelected: (_) {},
              onImageRemoved: () {},
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.byType(PhotoPickerSection));
      await tester.pumpAndSettle();

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed
      expect(find.text('Pilih Foto'), findsNothing);
    });

    testWidgets('should have correct max file size constant', (WidgetTester tester) async {
      // Max file size should be 5MB
      expect(PhotoPickerSection.maxFileSizeBytes, 5 * 1024 * 1024);
    });
  });
}
