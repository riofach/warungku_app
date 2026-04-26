import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/item_unit_draft.dart';

/// Konfigurasi satuan untuk item.
/// Menampilkan:
/// - Toggle "Dijual per satuan berbeda?"
/// - Jika ON: dropdown base_unit + list variant (label, qty, sell_price)
///
/// Callback [onChanged] dipanggil setiap ada perubahan state.
class UnitConfigSection extends StatefulWidget {
  final bool initialHasUnits;
  final String initialBaseUnit;
  final List<ItemUnitDraft> initialUnits;
  final bool showPriceFields;
  final void Function({
    required bool hasUnits,
    required String baseUnit,
    required List<ItemUnitDraft> units,
  })
  onChanged;

  const UnitConfigSection({
    super.key,
    this.initialHasUnits = false,
    this.initialBaseUnit = 'pcs',
    this.initialUnits = const [],
    this.showPriceFields = true,
    required this.onChanged,
  });

  @override
  State<UnitConfigSection> createState() => _UnitConfigSectionState();
}

class _UnitConfigSectionState extends State<UnitConfigSection> {
  late bool _hasUnits;
  late String _baseUnit;
  late List<ItemUnitDraft> _units;

  static const _baseUnitOptions = [
    {'value': 'pcs', 'label': 'Pcs (satuan)'},
    {'value': 'gram', 'label': 'Kg (berat, disimpan gram)'},
    {'value': 'ml', 'label': 'Liter (volume, disimpan ml)'},
  ];

  @override
  void initState() {
    super.initState();
    _hasUnits = widget.initialHasUnits;
    _baseUnit = widget.initialBaseUnit;
    _units = List.from(widget.initialUnits);
  }

  void _notify() {
    widget.onChanged(
      hasUnits: _hasUnits,
      baseUnit: _baseUnit,
      units: List.from(_units),
    );
  }

  void _toggleHasUnits(bool val) {
    setState(() {
      _hasUnits = val;
      if (val && _units.isEmpty) {
        if (_baseUnit == 'gram') {
          _units = [
            ItemUnitDraft(label: '1 Kg', quantityBase: 1000, sellPrice: 0),
            ItemUnitDraft(label: '½ Kg', quantityBase: 500, sellPrice: 0),
            ItemUnitDraft(label: '¼ Kg', quantityBase: 250, sellPrice: 0),
          ];
        } else {
          _units = [ItemUnitDraft.empty()];
        }
      }
    });
    _notify();
  }

  void _changeBaseUnit(String? val) {
    if (val == null) return;
    setState(() {
      _baseUnit = val;
      if (_hasUnits &&
          _baseUnit == 'gram' &&
          _units.every((u) => u.quantityBase == 0)) {
        _units = [
          ItemUnitDraft(label: '1 Kg', quantityBase: 1000, sellPrice: 0),
          ItemUnitDraft(label: '½ Kg', quantityBase: 500, sellPrice: 0),
          ItemUnitDraft(label: '¼ Kg', quantityBase: 250, sellPrice: 0),
        ];
      }
    });
    _notify();
  }

  void _addUnit() {
    setState(() => _units.add(ItemUnitDraft.empty()));
    _notify();
  }

  void _removeUnit(int index) {
    setState(() => _units.removeAt(index));
    _notify();
  }

  void _updateUnit(int index, ItemUnitDraft updated) {
    setState(() => _units[index] = updated);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _hasUnits,
          onChanged: _toggleHasUnits,
          title: const Text('Dijual per satuan berbeda?'),
          subtitle: Text(
            _hasUnits
                ? 'Aktif: item dijual dalam varian satuan (misal 1Kg, ½Kg)'
                : 'Nonaktif: item dijual per satuan tunggal',
            style: const TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        if (_hasUnits) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _baseUnit,
            decoration: const InputDecoration(
              labelText: 'Satuan Dasar',
              border: OutlineInputBorder(),
              helperText: 'Stok disimpan dalam satuan ini',
            ),
            items: _baseUnitOptions
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  ),
                )
                .toList(),
            onChanged: _changeBaseUnit,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text(
                'Varian Satuan Jual',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addUnit,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
              ),
            ],
          ),
          if (!widget.showPriceFields) ...[
            const SizedBox(height: 8),
            const Text(
              'Di langkah ini cukup isi label dan jumlah. Harga jual dan harga beli varian diatur setelah pembelian.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],

          ..._units.asMap().entries.map(
            (entry) => _UnitDraftTile(
              index: entry.key,
              draft: entry.value,
              baseUnit: _baseUnit,
              showPriceFields: widget.showPriceFields,
              onUpdate: (updated) => _updateUnit(entry.key, updated),
              onRemove: () => _removeUnit(entry.key),
            ),
          ),

          if (_units.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Belum ada varian. Tap "Tambah" untuk menambah.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }
}

class _UnitDraftTile extends StatefulWidget {
  final int index;
  final ItemUnitDraft draft;
  final String baseUnit;
  final bool showPriceFields;
  final ValueChanged<ItemUnitDraft> onUpdate;
  final VoidCallback onRemove;

  const _UnitDraftTile({
    required this.index,
    required this.draft,
    required this.baseUnit,
    required this.showPriceFields,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_UnitDraftTile> createState() => _UnitDraftTileState();
}

class _UnitDraftTileState extends State<_UnitDraftTile> {
  late TextEditingController _labelCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _buyPriceCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.draft.label);
    _qtyCtrl = TextEditingController(
      text: widget.draft.quantityBase > 0
          ? widget.draft.quantityBase.toString()
          : '',
    );
    _priceCtrl = TextEditingController(
      text: widget.draft.sellPrice > 0 ? widget.draft.sellPrice.toString() : '',
    );
    _buyPriceCtrl = TextEditingController(
      text: widget.draft.buyPrice > 0 ? widget.draft.buyPrice.toString() : '',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _buyPriceCtrl.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    widget.onUpdate(
      widget.draft.copyWith(
        label: _labelCtrl.text,
        quantityBase: int.tryParse(_qtyCtrl.text) ?? 0,
        sellPrice: widget.showPriceFields
            ? int.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0
            : widget.draft.sellPrice,
        buyPrice: widget.showPriceFields
            ? int.tryParse(_buyPriceCtrl.text.replaceAll('.', '')) ?? 0
            : widget.draft.buyPrice,
      ),
    );
  }

  String get _qtyHelper {
    switch (widget.baseUnit) {
      case 'gram':
        return 'gram (misal 1000 = 1Kg)';
      case 'ml':
        return 'ml (misal 1000 = 1L)';
      default:
        return 'jumlah pcs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Varian ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'misal: 1 Kg, ½ Kg, 1 pcs',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _emitUpdate(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Jumlah dalam satuan dasar',
                      helperText: _qtyHelper,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _emitUpdate(),
                  ),
                ),
              ],
            ),
            if (widget.showPriceFields) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _emitUpdate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _buyPriceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga Beli',
                  prefixText: 'Rp ',
                  helperText: 'Sudah diatur sistem',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _emitUpdate(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
