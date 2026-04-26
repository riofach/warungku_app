import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/inventory/data/models/item_unit_draft.dart';
import 'package:warungku_app/features/inventory/presentation/widgets/unit_config_section.dart';

void main() {
  Widget buildTestWidget({required bool showPriceFields}) {
    return MaterialApp(
      home: Scaffold(
        body: UnitConfigSection(
          initialHasUnits: true,
          initialBaseUnit: 'gram',
          initialUnits: [
            ItemUnitDraft(
              label: '1 Kg',
              quantityBase: 1000,
              sellPrice: 15000,
              buyPrice: 12000,
            ),
          ],
          showPriceFields: showPriceFields,
          onChanged:
              ({
                required bool hasUnits,
                required String baseUnit,
                required List<ItemUnitDraft> units,
              }) {},
        ),
      ),
    );
  }

  group('UnitConfigSection', () {
    testWidgets('shows variant price fields by default for item form', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(showPriceFields: true));

      expect(find.widgetWithText(TextFormField, 'Harga Jual'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Harga Beli'), findsOneWidget);
      expect(
        find.text(
          'Di langkah ini cukup isi label dan jumlah. Harga jual dan harga beli varian diatur setelah pembelian.',
        ),
        findsNothing,
      );
    });

    testWidgets('hides variant price fields for purchase flow', (tester) async {
      await tester.pumpWidget(buildTestWidget(showPriceFields: false));

      expect(find.widgetWithText(TextFormField, 'Harga Jual'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Harga Beli'), findsNothing);
      expect(
        find.text(
          'Di langkah ini cukup isi label dan jumlah. Harga jual dan harga beli varian diatur setelah pembelian.',
        ),
        findsOneWidget,
      );
    });
  });
}
