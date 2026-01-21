import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/item_model.dart';
import '../../data/providers/providers.dart';
import '../widgets/photo_picker_section.dart';

/// Item Form Screen for adding new items or editing existing items
/// Implements AC: 1 (Navigation), 2 (Form Fields), 8 (Cancel/Discard Flow)
/// Story 3.5: Added edit mode support with optional item parameter
class ItemFormScreen extends ConsumerStatefulWidget {
  /// Optional item for edit mode. If null, form is in add mode.
  final Item? item;

  const ItemFormScreen({super.key, this.item});

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

  // Edit mode specific state
  String? _existingImageUrl;
  bool _imageRemoved = false;

  // Delete operation state (Story 3.6 - AC6)
  bool _isDeleting = false;
  
  // Stock Opname state - tracks current stock for button display (Story 3.7 - H4 fix)
  int? _currentDisplayStock;

  /// Whether the form is in edit mode
  bool get isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    
    // Reset form state to clear any previous errors (H3 fix from code review)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemFormNotifierProvider.notifier).reset();
    });
    
    // Pre-fill form if in edit mode
    if (isEditMode) {
      _prefillFormWithItemData(widget.item!);
    }
    
    _setupDirtyTracking();
    
    // Load categories for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListNotifierProvider.notifier).loadCategories();
    });
  }

  /// Pre-fill form fields with existing item data (AC2)
  void _prefillFormWithItemData(Item item) {
    _nameController.text = item.name;
    _buyPriceController.text = _formatNumberForDisplay(item.buyPrice);
    _sellPriceController.text = _formatNumberForDisplay(item.sellPrice);
    _stockController.text = item.stock.toString();
    _thresholdController.text = item.stockThreshold.toString();
    _selectedCategoryId = item.categoryId;
    _isActive = item.isActive;
    _existingImageUrl = item.imageUrl;
    _currentDisplayStock = item.stock; // Initialize display stock (H4 fix)
  }

  /// Format number with thousand separator for display (e.g., 3500 -> "3.500")
  String _formatNumberForDisplay(int number) {
    if (number == 0) return '';
    final chars = number.toString().split('').reversed.toList();
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add('.');
      }
      result.add(chars[i]);
    }
    return result.reversed.join();
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
  /// AC9: Different message for edit mode vs add mode
  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final dialogTitle = isEditMode 
        ? 'Batalkan perubahan?' 
        : 'Batalkan penambahan barang?';
    final dialogContent = isEditMode
        ? 'Perubahan yang belum disimpan akan hilang.'
        : 'Perubahan yang belum disimpan akan hilang.';

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
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
      _imageRemoved = false; // Reset removed flag when new image selected
      _isDirty = true;
    });
  }

  /// Handle image removal (AC7)
  void _onImageRemoved() {
    setState(() {
      _selectedImage = null;
      _imageRemoved = true;
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

  /// Show delete confirmation dialog (Story 3.6 - AC2)
  /// Returns true if user confirms deletion, false otherwise
  /// Uses StatefulBuilder to properly handle loading state inside dialog (H3 fix)
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // AC6: Never dismissible - user must choose action
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: Text(
          "Barang '${widget.item!.name}' akan dihapus. Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Handle Stock Opname button pressed (Story 3.7 - AC1)
  void _onStockOpnamePressed() async {
    final result = await _showStockOpnameDialog();
    if (result == true && mounted) {
      // Refresh form with updated stock - update the stock controller and display stock
      final updatedItem = await ref
          .read(itemRepositoryProvider)
          .getItemById(widget.item!.id);
      if (updatedItem != null && mounted) {
        setState(() {
          _stockController.text = updatedItem.stock.toString();
          _currentDisplayStock = updatedItem.stock; // H4 fix: Update button display
        });
      }
    }
  }

  /// Show Stock Opname dialog for manual stock update (Story 3.7 - AC2, AC3, AC4, AC5, AC6, AC7)
  Future<bool?> _showStockOpnameDialog() {
    // Use _currentDisplayStock if available, fallback to widget.item!.stock
    final currentStock = _currentDisplayStock ?? widget.item!.stock;
    final controller = TextEditingController();
    int? newStock;
    String? errorText;
    bool isSubmitting = false;
    bool hasInteracted = false; // Track if user has started typing

    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // Controlled by PopScope.canPop during submission
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final difference =
              newStock != null ? newStock! - currentStock : null;

          // Determine difference color and text (AC3)
          Color differenceColor = AppColors.textSecondary;
          String differenceText = '-';
          if (difference != null) {
            if (difference > 0) {
              differenceColor = AppColors.success;
              differenceText = '+$difference';
            } else if (difference < 0) {
              differenceColor = AppColors.error;
              differenceText = '$difference';
            } else {
              differenceText = '0';
            }
          }

          // AC4: Determine if submit should be disabled
          final isSubmitDisabled =
              isSubmitting || newStock == null || errorText != null;

          return PopScope(
            // AC7: Prevent dismiss during submission
            canPop: !isSubmitting,
            child: AlertDialog(
              title: const Text('Stock Opname'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name (AC2)
                  Text(
                    widget.item!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Current Stock - readonly (AC2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stok Saat Ini:'),
                      Text(
                        '$currentStock',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Actual Stock Input (AC2, AC4)
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting, // AC7: Disable during processing
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Stok Fisik Sebenarnya',
                      errorText: hasInteracted ? errorText : null, // Only show error after user interaction
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        hasInteracted = true; // User started typing
                        // AC3, AC4: Validate and calculate difference
                        if (value.isEmpty) {
                          newStock = null;
                          errorText = 'Masukkan jumlah stok'; // AC4: Empty input error
                        } else {
                          final parsed = int.tryParse(value);
                          if (parsed == null) {
                            newStock = null;
                            errorText = 'Masukkan angka yang valid';
                          } else if (parsed < 0) {
                            newStock = null;
                            errorText = 'Stok tidak boleh negatif';
                          } else if (parsed > 999999) {
                            newStock = null;
                            errorText = 'Stok maksimal 999999';
                          } else {
                            newStock = parsed;
                            errorText = null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Difference - calculated (AC2, AC3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Selisih:'),
                      Text(
                        differenceText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: differenceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Batal button (AC2, AC7)
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                // Simpan button (AC2, AC4, AC5, AC7)
                ElevatedButton(
                  onPressed: isSubmitDisabled
                      ? null
                      : () async {
                          // AC7: Set submitting state
                          setDialogState(() => isSubmitting = true);

                          // Capture scaffold messenger before async gap to avoid
                          // use_build_context_synchronously warning
                          final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                          final navigator = Navigator.of(context);

                          // AC5: Call provider to update stock
                          final success = await ref
                              .read(itemFormNotifierProvider.notifier)
                              .updateStock(widget.item!.id, newStock!);

                          // Check mounted before accessing context
                          if (!mounted) return;

                          if (success) {
                            // AC5: Close dialog and show success snackbar
                            navigator.pop(true);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Stok berhasil diperbarui'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            // AC6: Keep dialog open on error
                            setDialogState(() => isSubmitting = false);
                            // Error message from state
                            final errorMessage =
                                ref.read(itemFormNotifierProvider).errorMessage;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(errorMessage ??
                                    'Terjadi kesalahan. Silakan coba lagi.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Handle delete button pressed (Story 3.6 - AC1)
  void _onDeletePressed() async {
    // AC6: Prevent interaction while processing
    if (_isDeleting) return;
    
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      _performDelete();
    }
  }

  /// Perform the actual delete operation (Story 3.6 - AC3, AC5, AC6)
  /// M1 fix: Added comprehensive mounted checks before all context access
  void _performDelete() async {
    if (!mounted) return;
    
    setState(() => _isDeleting = true);
    
    final success = await ref
        .read(itemFormNotifierProvider.notifier)
        .deleteItem(widget.item!.id);
    
    // M1 fix: Check mounted before setState
    if (!mounted) return;
    
    setState(() => _isDeleting = false);
    
    if (success) {
      // M1 fix: Check mounted before ScaffoldMessenger access
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barang berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
      if (!mounted) return;
      // Use context.go() instead of pop() to ensure correct navigation
      // This fixes the issue where pop() navigates to wrong screen (/settings instead of /items)
      // because /items and /items/edit are standalone routes outside ShellRoute
      context.go(AppRoutes.items);
    } else {
      // M1 fix: Check mounted before accessing context for error snackbar
      if (!mounted) return;
      final errorMessage = ref.read(itemFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Gagal menghapus barang'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Submit form - create new item or update existing (AC5)
  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final buyPrice = _parsePriceFromFormatted(_buyPriceController.text);
    final sellPrice = _parsePriceFromFormatted(_sellPriceController.text);
    final stock = int.tryParse(_stockController.text) ?? 0;
    final threshold = int.tryParse(_thresholdController.text) ?? 10;

    if (isEditMode) {
      // Update existing item
      ref.read(itemFormNotifierProvider.notifier).updateItem(
            itemId: widget.item!.id,
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId,
            buyPrice: buyPrice,
            sellPrice: sellPrice,
            stock: stock,
            stockThreshold: threshold,
            isActive: _isActive,
            imageFile: _selectedImage,
            imageRemoved: _imageRemoved,
          );
    } else {
      // Create new item
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
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(itemFormNotifierProvider);
    final categoriesState = ref.watch(categoryListNotifierProvider);

    // Validate that selected category exists in loaded categories list
    // This prevents dropdown error when category is set before categories are loaded
    final validCategoryId = (_selectedCategoryId != null &&
            categoriesState.categories.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId
        : null;

    // Success message based on mode (AC5, AC10)
    final successMessage = isEditMode 
        ? 'Barang berhasil diperbarui' 
        : 'Barang berhasil ditambahkan';

    // Listen for form state changes
    ref.listen<ItemFormState>(itemFormNotifierProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
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
          // AC1, AC10: Different title based on mode
          title: Text(isEditMode ? 'Edit Barang' : 'Tambah Barang'),
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
                // Photo Picker Section (AC2, AC3)
                PhotoPickerSection(
                  selectedImage: _selectedImage,
                  existingImageUrl: _imageRemoved ? null : _existingImageUrl,
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

                // Kategori Dropdown (AC2)
                // Note: Using 'value' instead of 'initialValue' because we need reactive updates
                // when category is changed. This is the intended Flutter behavior for controlled dropdowns.
                // Using validCategoryId to prevent error when category not yet in loaded list.
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  value: validCategoryId,
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

                // Stok & Batas Minimum (Row)
                Row(
                  children: [
                    // Stok
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: InputDecoration(
                          labelText: isEditMode ? 'Stok' : 'Stok Awal',
                          hintText: '0',
                          border: const OutlineInputBorder(),
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

                // Stock Opname Button - Only visible in edit mode (Story 3.7 - AC1)
                if (isEditMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: formState.isLoading || _isDeleting
                          ? null
                          : _onStockOpnamePressed,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Stock Opname'),
                          Text(
                            'Stok saat ini: ${_currentDisplayStock ?? widget.item!.stock}', // H4 fix: Use tracked stock
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ],

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
                    onPressed: formState.isLoading || _isDeleting ? null : _onSubmit,
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

                // Delete Button - Only visible in edit mode (Story 3.6 - AC1)
                if (isEditMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: formState.isLoading || _isDeleting ? null : _onDeletePressed,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.error,
                                ),
                              ),
                            )
                          : const Text('Hapus Barang'),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
