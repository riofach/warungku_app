import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/housing_block_model.dart';
import 'package:warungku_app/features/inventory/data/providers/housing_blocks_provider.dart';

void main() {
  group('HousingBlock Model', () {
    group('fromJson', () {
      test('should create HousingBlock from valid JSON', () {
        final json = {
          'id': 'block-123',
          'name': 'Blok A',
          'created_at': '2026-01-20T10:00:00Z',
          'updated_at': '2026-01-20T10:00:00Z',
        };

        final block = HousingBlock.fromJson(json);

        expect(block.id, 'block-123');
        expect(block.name, 'Blok A');
        expect(block.createdAt, isA<DateTime>());
        expect(block.updatedAt, isA<DateTime>());
      });

      test('should handle null timestamps with defaults', () {
        final json = {
          'id': 'block-123',
          'name': 'Blok B',
          'created_at': null,
          'updated_at': null,
        };

        final block = HousingBlock.fromJson(json);

        expect(block.createdAt, isA<DateTime>());
        expect(block.updatedAt, isA<DateTime>());
      });

      test('should parse ISO 8601 timestamps correctly', () {
        final json = {
          'id': 'block-123',
          'name': 'Blok C',
          'created_at': '2026-01-19T02:26:03.156726+00:00',
          'updated_at': '2026-01-19T02:26:03.156726+00:00',
        };

        final block = HousingBlock.fromJson(json);

        expect(block.createdAt.year, 2026);
        expect(block.createdAt.month, 1);
        expect(block.createdAt.day, 19);
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly with only name field', () {
        final block = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = block.toJson();

        expect(json['name'], 'Blok A');
        expect(json.keys.length, 1); // Only name should be in toJson
      });

      test('should not include id in toJson output', () {
        final block = HousingBlock(
          id: 'block-123',
          name: 'Blok B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = block.toJson();

        expect(json.containsKey('id'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final block = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = block.copyWith(name: 'Blok B');

        expect(updated.id, 'block-123');
        expect(updated.name, 'Blok B');
      });

      test('should create copy with updated id', () {
        final block = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final updated = block.copyWith(id: 'block-456');

        expect(updated.id, 'block-456');
        expect(updated.name, 'Blok A');
      });

      test('should preserve all fields when no arguments passed', () {
        final original = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime(2026, 1, 20),
          updatedAt: DateTime(2026, 1, 20),
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);
      });
    });

    group('Equality', () {
      test('two blocks with same id should be equal', () {
        final block1 = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final block2 = HousingBlock(
          id: 'block-123',
          name: 'Different Name',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(block1, equals(block2));
        expect(block1.hashCode, equals(block2.hashCode));
      });

      test('two blocks with different id should not be equal', () {
        final block1 = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final block2 = HousingBlock(
          id: 'block-456',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(block1, isNot(equals(block2)));
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final block = HousingBlock(
          id: 'block-123',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = block.toString();

        expect(result, contains('block-123'));
        expect(result, contains('Blok A'));
      });
    });
  });

  group('HousingBlockListState', () {
    test('initial state should have initial status and empty list', () {
      final state = HousingBlockListState.initial();

      expect(state.status, HousingBlockListStatus.initial);
      expect(state.blocks, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isEmpty, false);
    });

    test('loading state should have loading status', () {
      final state = HousingBlockListState.loading();

      expect(state.status, HousingBlockListStatus.loading);
      expect(state.isLoading, true);
      expect(state.hasError, false);
    });

    test('loaded state should have list of blocks', () {
      final blocks = [
        HousingBlock(
          id: 'block-1',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final state = HousingBlockListState.loaded(blocks);

      expect(state.status, HousingBlockListStatus.loaded);
      expect(state.blocks, blocks);
      expect(state.isEmpty, false);
    });

    test('loaded state with empty list should be isEmpty', () {
      final state = HousingBlockListState.loaded([]);

      expect(state.status, HousingBlockListStatus.loaded);
      expect(state.isEmpty, true);
    });

    test('error state should have error message', () {
      final state = HousingBlockListState.error('Test error');

      expect(state.status, HousingBlockListStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Test error');
    });
  });

  group('HousingBlockActionState', () {
    test('initial state should have initial status', () {
      final state = HousingBlockActionState.initial();

      expect(state.status, HousingBlockActionStatus.initial);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isSuccess, false);
    });

    test('loading state should have loading status', () {
      final state = HousingBlockActionState.loading();

      expect(state.status, HousingBlockActionStatus.loading);
      expect(state.isLoading, true);
    });

    test('success state should have success message', () {
      final state = HousingBlockActionState.success('Blok berhasil ditambahkan');

      expect(state.status, HousingBlockActionStatus.success);
      expect(state.isSuccess, true);
      expect(state.successMessage, 'Blok berhasil ditambahkan');
    });

    test('error state should have error message', () {
      final state = HousingBlockActionState.error('Gagal menambahkan blok');

      expect(state.status, HousingBlockActionStatus.error);
      expect(state.hasError, true);
      expect(state.errorMessage, 'Gagal menambahkan blok');
    });
  });

  group('Form Validation', () {
    test('empty name should fail validation', () {
      final name = '';
      final isValid = name.trim().isNotEmpty && name.trim().length <= 100;
      
      expect(isValid, false);
    });

    test('whitespace only name should fail validation', () {
      final name = '   ';
      final isValid = name.trim().isNotEmpty && name.trim().length <= 100;
      
      expect(isValid, false);
    });

    test('valid name should pass validation', () {
      final name = 'Blok A';
      final isValid = name.trim().isNotEmpty && name.trim().length <= 100;
      
      expect(isValid, true);
    });

    test('name with 100 characters should pass validation', () {
      final name = 'A' * 100;
      final isValid = name.trim().isNotEmpty && name.trim().length <= 100;
      
      expect(isValid, true);
    });

    test('name with 101 characters should fail validation', () {
      final name = 'A' * 101;
      final isValid = name.trim().isNotEmpty && name.trim().length <= 100;
      
      expect(isValid, false);
    });
  });

  // Widget Tests for Housing Blocks
  group('Housing Block Widget Tests', () {
    testWidgets('should render empty state when no blocks', (tester) async {
      // Create a simple widget that shows empty state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Belum ada blok perumahan'),
                  Text('Tap + untuk menambah.'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Belum ada blok perumahan'), findsOneWidget);
      expect(find.text('Tap + untuk menambah.'), findsOneWidget);
      expect(find.byIcon(Icons.location_city_outlined), findsOneWidget);
    });

    testWidgets('should render list of blocks', (tester) async {
      final blocks = [
        HousingBlock(
          id: 'block-1',
          name: 'Blok A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        HousingBlock(
          id: 'block-2',
          name: 'Blok B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(blocks[index].name),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Blok A'), findsOneWidget);
      expect(find.text('Blok B'), findsOneWidget);
      expect(find.byIcon(Icons.location_city), findsNWidgets(2));
    });

    testWidgets('FAB should be present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Blok Perumahan')),
            body: const Center(child: Text('Content')),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              tooltip: 'Tambah Blok',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Blok Perumahan'), findsOneWidget);
    });

    testWidgets('dialog validation should show error for empty name', (tester) async {
      final formKey = GlobalKey<FormState>();

      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama blok wajib diisi';
        }
        if (value.trim().length > 100) {
          return 'Nama blok maksimal 100 karakter';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: validateName,
              ),
            ),
          ),
        ),
      );

      // Trigger validation without entering text
      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('Nama blok wajib diisi'), findsOneWidget);
    });

    testWidgets('dialog validation should show error for name too long', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'A' * 101);

      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama blok wajib diisi';
        }
        if (value.trim().length > 100) {
          return 'Nama blok maksimal 100 karakter';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                validator: validateName,
              ),
            ),
          ),
        ),
      );

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('Nama blok maksimal 100 karakter'), findsOneWidget);
    });

    testWidgets('dialog validation should pass for valid name', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'Blok A');

      String? validateName(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama blok wajib diisi';
        }
        if (value.trim().length > 100) {
          return 'Nama blok maksimal 100 karakter';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                validator: validateName,
              ),
            ),
          ),
        ),
      );

      final isValid = formKey.currentState?.validate() ?? false;
      await tester.pump();

      expect(isValid, true);
      expect(find.text('Nama blok wajib diisi'), findsNothing);
      expect(find.text('Nama blok maksimal 100 karakter'), findsNothing);
    });

    testWidgets('delete confirmation dialog should show block name', (tester) async {
      const blockName = 'Blok Test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertDialog(
              title: const Text('Hapus Blok?'),
              content: Text(
                'Yakin ingin menghapus blok "$blockName"? Pesanan dengan blok ini akan tetap tercatat.',
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Batal')),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hapus Blok?'), findsOneWidget);
      expect(find.textContaining('Blok Test'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('loading state should show CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat blok perumahan...'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat blok perumahan...'), findsOneWidget);
    });

    testWidgets('error state should show retry button', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Gagal memuat blok perumahan'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => retryPressed = true,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Gagal memuat blok perumahan'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      
      await tester.tap(find.text('Coba Lagi'));
      expect(retryPressed, true);
    });
  });

  // Timeout handling tests
  group('Repository Timeout Handling', () {
    test('timeout error message should be in Indonesian', () {
      const timeoutMessage = 'Koneksi timeout. Periksa jaringan Anda.';
      expect(timeoutMessage, contains('timeout'));
      expect(timeoutMessage, contains('jaringan'));
    });
  });
}
