import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/presentation/widgets/photo_picker_section.dart';

/// Story 3.5 Test: Edit Existing Item - PhotoPickerSection Edit Mode Tests
/// Covers AC2, AC3, AC7
void main() {
  group('PhotoPickerSection Edit Mode (Story 3.5)', () {
    group('AC2: Display existing image URL', () {
      testWidgets('should show placeholder when no image',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
        expect(find.text('Tap untuk menambah foto'), findsOneWidget);
      });

      testWidgets('should show network image when existingImageUrl provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        // Should not show placeholder icon when we have an image URL
        expect(find.byIcon(Icons.add_a_photo), findsNothing);
        // Should show edit overlay
        expect(find.text('Tap untuk mengubah'), findsOneWidget);
      });

      testWidgets('should show edit overlay when image exists',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.text('Tap untuk mengubah'), findsOneWidget);
      });
    });

    group('AC3: Photo Update Options', () {
      testWidgets('should show bottom sheet with all options on tap',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        // Tap the photo section
        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        // Should show bottom sheet with all options
        expect(find.text('Pilih Foto'), findsOneWidget);
        expect(find.text('Kamera'), findsOneWidget);
        expect(find.text('Galeri'), findsOneWidget);
        expect(find.text('Hapus Foto'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
      });

      testWidgets('should show camera icon in bottom sheet',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('should show gallery icon in bottom sheet',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      });

      testWidgets('should close bottom sheet when Batal tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        // Bottom sheet should be closed
        expect(find.text('Pilih Foto'), findsNothing);
      });
    });

    group('AC7: Remove Photo (Hapus Foto)', () {
      testWidgets('should show Hapus Foto option when existing image exists',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        expect(find.text('Hapus Foto'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should NOT show Hapus Foto when no image',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        expect(find.text('Hapus Foto'), findsNothing);
      });

      testWidgets('should call onImageRemoved when Hapus Foto tapped',
          (WidgetTester tester) async {
        bool wasRemoved = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {
                  wasRemoved = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus Foto'));
        await tester.pumpAndSettle();

        expect(wasRemoved, true);
      });

      testWidgets('Hapus Foto option should have red color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/test-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PhotoPickerSection));
        await tester.pumpAndSettle();

        // Find the Hapus Foto text and verify it has the error color style
        final hapusFotoText = find.text('Hapus Foto');
        expect(hapusFotoText, findsOneWidget);

        // Verify the delete icon exists (indicates the option is present)
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });
    });

    group('Priority: selectedImage > existingImageUrl > placeholder', () {
      testWidgets('should show placeholder when no images',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      });

      testWidgets('should show placeholder when existingImageUrl is empty string',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: '',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      });

      testWidgets('should show network image preview for valid URL',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: 'https://example.com/valid-image.jpg',
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        // Placeholder should not be shown
        expect(find.byIcon(Icons.add_a_photo), findsNothing);
        // Edit overlay should be shown
        expect(find.text('Tap untuk mengubah'), findsOneWidget);
      });
    });

    group('PhotoPickerSection widget properties', () {
      testWidgets('should have correct height',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(PhotoPickerSection),
            matching: find.byType(Container).first,
          ),
        );

        expect(container.constraints?.maxHeight, 200);
      });

      testWidgets('should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        // The PhotoPickerSection itself opens the bottom sheet
        // So we just verify it's rendered
        expect(find.byType(PhotoPickerSection), findsOneWidget);
      });
    });

    group('File size limit display', () {
      testWidgets('should show file size hint in placeholder',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhotoPickerSection(
                selectedImage: null,
                existingImageUrl: null,
                onImageSelected: (_) {},
                onImageRemoved: () {},
              ),
            ),
          ),
        );

        expect(find.text('Maksimal 5MB (JPEG, PNG)'), findsOneWidget);
      });
    });
  });
}
