import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item_model.dart';
import '../../data/models/item_unit_draft.dart';
import '../../data/providers/items_provider.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import '../widgets/photo_picker_section.dart';
import '../widgets/unit_config_section.dart';

const purchaseFlowNewItemDefaultIsActive = false;

/// Wizard 3-step untuk Input Pembelian.
///
/// Step 1 — Pilih atau buat produk
/// Step 2 — Konfigurasi satuan (base_unit, has_units, variants)
/// Step 3 — Detail pembelian (foto, jumlah, harga, catatan)
class PurchaseFlowScreen extends ConsumerStatefulWidget {
  const PurchaseFlowScreen({super.key});

  @override
  ConsumerState<PurchaseFlowScreen> createState() => _PurchaseFlowScreenState();
}

class _PurchaseFlowScreenState extends ConsumerState<PurchaseFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1 state ──────────────────────────────────────────
  Item? _selectedItem;
  bool _isNewItem = false;
  final _nameCtrl = TextEditingController();
  String? _selectedCategoryId;
  final _step1FormKey = GlobalKey<FormState>();

  // ── Step 2 state ──────────────────────────────────────────
  bool _hasUnits = false;
  String _baseUnit = 'pcs';
  List<ItemUnitDraft> _unitDrafts = [];

  // ── Step 3 state ──────────────────────────────────────────
  File? _photoFile;
  String? _existingPhotoUrl;
  bool _photoRemoved = false;
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();

  int _suggestedBuyPrice = 0;
  List<Map<String, dynamic>> _suggestedPerUnit = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListNotifierProvider.notifier).loadItems();
      ref.read(categoryListNotifierProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 2) {
      _submitPurchase();
      return;
    }
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── Step 1 ───────────────────────────────────────────────

  bool _validateStep1() {
    if (_isNewItem) return _step1FormKey.currentState?.validate() ?? false;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return false;
    }
    return true;
  }

  void _onSelectItem(Item item) {
    setState(() {
      _selectedItem = item;
      _isNewItem = false;
      _hasUnits = item.hasUnits;
      _baseUnit = item.baseUnit;
      _unitDrafts = item.activeUnits
          .map((u) => ItemUnitDraft.fromUnit(u))
          .toList();
      _existingPhotoUrl = item.imageUrl;
    });
  }

  void _onStartNewItem() {
    setState(() {
      _selectedItem = null;
      _isNewItem = true;
      _hasUnits = false;
      _baseUnit = 'pcs';
      _unitDrafts = [];
      _existingPhotoUrl = null;
    });
  }

  // ── Step 3: suggestion ────────────────────────────────────

  void _calculateSuggestion() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final cost = int.tryParse(_costCtrl.text.replaceAll('.', '')) ?? 0;
    if (qty <= 0 || cost <= 0) {
      setState(() {
        _suggestedBuyPrice = 0;
        _suggestedPerUnit = [];
      });
      return;
    }

    final multiplier = _baseUnit == 'gram'
        ? 1000
        : (_baseUnit == 'ml' ? 1000 : 1);
    final baseQty = qty * multiplier;
    final costPerBase = cost / baseQty;

    setState(() {
      _suggestedBuyPrice = costPerBase.round();
      if (_hasUnits) {
        _suggestedPerUnit = _unitDrafts
            .map(
              (d) => {
                'label': d.label,
                'buy_price': (costPerBase * d.quantityBase).round(),
              },
            )
            .toList();
      }
    });
  }

  String get _displayUnit {
    switch (_baseUnit) {
      case 'gram':
        return 'Kg';
      case 'ml':
        return 'Liter';
      default:
        return 'pcs';
    }
  }

  int get _inputMultiplier {
    switch (_baseUnit) {
      case 'gram':
        return 1000;
      case 'ml':
        return 1000;
      default:
        return 1;
    }
  }

  // ── Submit ───────────────────────────────────────────────

  Future<void> _submitPurchase() async {
    if (!(_step3FormKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final repo = ItemRepository();
      final purchaseRepo = PurchaseRepository();

      String itemId;
      String? finalPhotoUrl = _existingPhotoUrl;

      if (_photoFile != null) {
        if (_existingPhotoUrl != null) {
          await repo.deleteImage(_existingPhotoUrl);
        }
        finalPhotoUrl = await repo.uploadImage(_photoFile!);
      } else if (_photoRemoved && _existingPhotoUrl != null) {
        await repo.deleteImage(_existingPhotoUrl);
        finalPhotoUrl = null;
      }

      if (_isNewItem) {
        itemId = await repo.createItem(
          name: _nameCtrl.text.trim(),
          categoryId: _selectedCategoryId,
          buyPrice: 0,
          sellPrice: 0,
          stock: 0,
          stockThreshold: 10,
          isActive: purchaseFlowNewItemDefaultIsActive,
          imageUrl: finalPhotoUrl,
          hasUnits: _hasUnits,
          baseUnit: _baseUnit,
        );
      } else {
        itemId = _selectedItem!.id;
        final needsUpdate =
            _hasUnits != _selectedItem!.hasUnits ||
            _baseUnit != _selectedItem!.baseUnit ||
            _photoFile != null ||
            _photoRemoved;
        if (needsUpdate) {
          await repo.updateItemUnitConfig(
            id: itemId,
            hasUnits: _hasUnits,
            baseUnit: _baseUnit,
            imageUrl: finalPhotoUrl,
            imageExplicitlyCleared: _photoRemoved,
          );
        }
      }

      if (_hasUnits) {
        for (final draft in _unitDrafts) {
          if (draft.isNew) {
            await purchaseRepo.createItemUnit(
              itemId: itemId,
              label: draft.label,
              quantityBase: draft.quantityBase,
              sellPrice: draft.sellPrice,
            );
          } else {
            await purchaseRepo.updateItemUnit(
              unitId: draft.id!,
              label: draft.label,
              quantityBase: draft.quantityBase,
              sellPrice: draft.sellPrice,
              buyPrice: draft.buyPrice,
              isActive: draft.isActive,
            );
          }
        }
      }

      final qty = int.parse(_qtyCtrl.text);
      final cost = int.parse(_costCtrl.text.replaceAll('.', ''));
      final baseQty = qty * _inputMultiplier;

      await purchaseRepo.createPurchase(
        itemId: itemId,
        quantityBase: baseQty,
        totalCost: cost,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      ref.invalidate(itemListNotifierProvider);

      if (mounted) {
        final itemName = _isNewItem
            ? _nameCtrl.text.trim()
            : _selectedItem!.name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembelian berhasil! Stok $itemName bertambah +$qty $_displayUnit',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Pilih Produk',
      'Konfigurasi Satuan',
      'Detail Pembelian',
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: BackButton(onPressed: _prevStep),
        title: Text(
          'Input Pembelian\n${stepTitles[_currentStep]}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[200],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2(), _buildStep3()],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentStep == 2 ? 'Simpan Pembelian' : 'Lanjut',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Pilih / Buat Produk ───────────────────────────

  Widget _buildStep1() {
    final itemState = ref.watch(itemListNotifierProvider);
    final items = itemState.items;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: _onStartNewItem,
          label: const Text('+ Produk Baru'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isNewItem
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              width: _isNewItem ? 2 : 1,
            ),
          ),
        ),

        if (_isNewItem) ...[
          const SizedBox(height: 12),
          Form(
            key: _step1FormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama produk wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                _CategoryDropdown(
                  selectedId: _selectedCategoryId,
                  onChanged: (id) => setState(() => _selectedCategoryId = id),
                ),
              ],
            ),
          ),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'atau pilih produk yang sudah ada',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),

        ...items.map(
          (item) => _ItemPickerTile(
            item: item,
            isSelected: _selectedItem?.id == item.id,
            onTap: () => _onSelectItem(item),
          ),
        ),

        if (items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada produk. Buat produk baru di atas.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  // ── Step 2: Konfigurasi Satuan ────────────────────────────

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_selectedItem != null)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: _selectedItem!.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _selectedItem!.imageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.inventory_2, color: Colors.grey),
              title: Text(
                _selectedItem!.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Stok: ${_selectedItem!.displayStock}'),
            ),
          )
        else
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.fiber_new, color: Colors.green),
              title: Text(
                _nameCtrl.text.trim().isEmpty
                    ? 'Produk Baru'
                    : _nameCtrl.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Produk baru'),
            ),
          ),

        UnitConfigSection(
          initialHasUnits: _hasUnits,
          initialBaseUnit: _baseUnit,
          initialUnits: _unitDrafts,
          showPriceFields: false,
          onChanged: ({required hasUnits, required baseUnit, required units}) {
            setState(() {
              _hasUnits = hasUnits;
              _baseUnit = baseUnit;
              _unitDrafts = units;
            });
          },
        ),
      ],
    );
  }

  // ── Step 3: Detail Pembelian ──────────────────────────────

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PhotoPickerSection(
          selectedImage: _photoFile,
          existingImageUrl: _photoRemoved ? null : _existingPhotoUrl,
          onImageSelected: (file) => setState(() {
            _photoFile = file;
            _photoRemoved = false;
          }),
          onImageRemoved: () => setState(() {
            _photoFile = null;
            _photoRemoved = true;
            _existingPhotoUrl = null;
          }),
        ),
        const SizedBox(height: 16),

        Form(
          key: _step3FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jumlah dibeli',
                  suffixText: _displayUnit,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if ((int.tryParse(v) ?? 0) <= 0) return 'Harus lebih dari 0';
                  return null;
                },
                onChanged: (_) => _calculateSuggestion(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Total harga beli',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if ((int.tryParse(v.replaceAll('.', '')) ?? 0) <= 0) {
                    return 'Harus lebih dari 0';
                  }
                  return null;
                },
                onChanged: (_) => _calculateSuggestion(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              if (_suggestedBuyPrice > 0) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Kalkulasi Harga Beli Otomatis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (!_hasUnits)
                  _SuggestionRow(
                    label: 'Harga Beli per $_displayUnit',
                    value: _suggestedBuyPrice,
                  )
                else ...[
                  for (final s in _suggestedPerUnit)
                    _SuggestionRow(
                      label: 'Harga Beli ${s['label']}',
                      value: s['buy_price'] as int,
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Harga jual varian bisa diatur nanti di Kelola Barang. Harga beli dihitung otomatis dari pembelian ini.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────

class _ItemPickerTile extends StatelessWidget {
  final Item item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ItemPickerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
        title: Text(item.name),
        subtitle: Text(
          'Stok: ${item.displayStock}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catState = ref.watch(categoryListNotifierProvider);
    final categories = catState.categories;

    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: const InputDecoration(
        labelText: 'Kategori (opsional)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tanpa Kategori')),
        ...categories.map(
          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final String label;
  final int value;

  const _SuggestionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            'Rp ${_fmt(value)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join('');
  }
}
