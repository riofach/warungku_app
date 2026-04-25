import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item_model.dart';
import '../../data/models/item_unit_model.dart';
import '../../../pos/data/providers/cart_provider.dart';

class UnitPickerBottomSheet extends ConsumerWidget {
  final Item item;

  const UnitPickerBottomSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUnits = item.activeUnits;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih Satuan',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Unit list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: activeUnits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final unit = activeUnits[index];
              final available = unit.availableFrom(item.stock);
              final isAvailable = available > 0;

              return _UnitTile(
                unit: unit,
                available: available,
                isAvailable: isAvailable,
                onTap: isAvailable
                    ? () {
                        ref.read(cartNotifierProvider.notifier).addItem(
                              item,
                              selectedUnit: unit,
                            );
                        Navigator.pop(context);
                      }
                    : null,
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final ItemUnit unit;
  final int available;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _UnitTile({
    required this.unit,
    required this.available,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isAvailable
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isAvailable ? null : Colors.grey[50],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isAvailable ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAvailable ? 'Sisa $available' : 'Habis',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.grey : Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${_formatRupiah(unit.sellPrice)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }
}

/// Show unit picker bottom sheet for a has_units item
void showUnitPicker(BuildContext context, Item item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UnitPickerBottomSheet(item: item),
  );
}
