import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/providers/providers.dart';
import '../widgets/photo_picker_section.dart';

/// Item Form Screen for adding new items
/// Implements AC: 1 (Navigation), 2 (Form Fields), 8 (Cancel/Discard Flow)
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '10');

  // Form state
  String? _selectedCategoryId;
  bool _isActive = true;
  File? _selectedImage;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _setupDirtyTracking();
    // Load categories for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListNotifierProvider.notifier).loadCategories();
    });
  }

  void _setupDirtyTracking() {
    _nameController.addListener(_markDirty);
    _buyPriceController.addListener(_markDirty);
    _sellPriceController.addListener(_markDirty);
    _stockController.addListener(_markDirty);
    _thresholdController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  /// Show confirmation dialog when user tries to leave with unsaved changes
  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan penambahan barang?'),
        content: const Text('Perubahan yang belum disimpan akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap di sini'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  /// Handle image selection from photo picker
  void _onImageSelected(File? file) {
    setState(() {
      _selectedImage = file;
      _isDirty = true;
    });
  }

  /// Handle image removal
  void _onImageRemoved() {
    setState(() {
      _selectedImage = null;
      _isDirty = true;
    });
  }

  /// Handle category selection change
  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _isDirty = true;
    });
  }

  /// Handle active status toggle
  void _onActiveChanged(bool value) {
    setState(() {
      _isActive = value;
      _isDirty = true;
    });
  }

  /// Parse price from formatted string (e.g., "3.500" -> 3500)
  int _parsePriceFromFormatted(String formattedPrice) {
    final digitsOnly = formattedPrice.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  /// Submit form and create new item
  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final buyPrice = _parsePriceFromFormatted(_buyPriceController.text);
    final sellPrice = _parsePriceFromFormatted(_sellPriceController.text);
    final stock = int.tryParse(_stockController.text) ?? 0;
    final threshold = int.tryParse(_thresholdController.text) ?? 10;

    // Call provider to save item
    ref.read(itemFormNotifierProvider.notifier).saveItem(
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          stock: stock,
          stockThreshold: threshold,
          isActive: _isActive,
          imageFile: _selectedImage,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(itemFormNotifierProvider);
    final categoriesState = ref.watch(categoryListNotifierProvider);

    // Listen for form state changes
    ref.listen<ItemFormState>(itemFormNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Terjadi kesalahan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Barang'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isDirty) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo Picker Section
                PhotoPickerSection(
                  selectedImage: _selectedImage,
                  onImageSelected: _onImageSelected,
                  onImageRemoved: _onImageRemoved,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Nama Barang
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang *',
                    hintText: 'Masukkan nama barang',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 255,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama barang wajib diisi';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Kategori Dropdown
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Pilih kategori (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('(Tanpa Kategori)'),
                    ),
                    ...categoriesState.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: _onCategoryChanged,
                ),

                const SizedBox(height: AppSpacing.md),

                // Harga Beli & Harga Jual (Row)
                Row(
                  children: [
                    // Harga Beli
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli *',
                          hintText: '0',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RupiahInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga beli wajib diisi';
                          }
                          final price = _parsePriceFromFormatted(value);
                          if (price < 0) {
                            return 'Harga beli tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Harga Jual
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual *',
                          hintText: '0',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RupiahInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga jual wajib diisi';
                          }
                          final price = _parsePriceFromFormatted(value);
                          if (price <= 0) {
                            return 'Harga jual harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Stok Awal & Batas Minimum (Row)
                Row(
                  children: [
                    // Stok Awal
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final stock = int.tryParse(value);
                            if (stock == null || stock < 0) {
                              return 'Stok tidak boleh negatif';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Batas Stok Minimum
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Batas Minimum',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final threshold = int.tryParse(value);
                            if (threshold == null || threshold < 0) {
                              return 'Batas tidak valid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Status Aktif Toggle
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  subtitle: Text(
                    _isActive
                        ? 'Barang akan ditampilkan untuk dijual'
                        : 'Barang tidak akan ditampilkan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: _isActive,
                  onChanged: _onActiveChanged,
                  activeThumbColor: AppColors.success,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    onPressed: formState.isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: formState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
