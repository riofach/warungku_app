import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/housing_block_model.dart';
import '../../data/providers/housing_blocks_provider.dart';

/// Dialog for editing housing block
/// AC5: Edit housing block with validation
class EditHousingBlockDialog extends ConsumerStatefulWidget {
  final HousingBlock block;

  const EditHousingBlockDialog({
    super.key,
    required this.block,
  });

  /// Show the dialog and return true if housing block was updated
  static Future<bool> show(BuildContext context, HousingBlock block) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditHousingBlockDialog(block: block),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EditHousingBlockDialog> createState() => _EditHousingBlockDialogState();
}

class _EditHousingBlockDialogState extends ConsumerState<EditHousingBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.block.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(updateHousingBlockNotifierProvider);

    return AlertDialog(
      title: const Text('Edit Blok'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Blok',
                hintText: 'Masukkan nama blok',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: _validateName,
              enabled: !actionState.isLoading,
            ),

            // Error message
            if (actionState.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        actionState.errorMessage ?? 'Terjadi kesalahan',
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: actionState.isLoading
              ? null
              : () {
                  ref.read(updateHousingBlockNotifierProvider.notifier).reset();
                  Navigator.of(context).pop(false);
                },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: actionState.isLoading ? null : _handleSubmit,
          child: actionState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama blok wajib diisi';
    }
    if (value.trim().length > 100) {
      return 'Nama blok maksimal 100 karakter';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(updateHousingBlockNotifierProvider.notifier).updateBlock(
            widget.block.id,
            _nameController.text.trim(),
          );

      if (success && mounted) {
        ref.read(updateHousingBlockNotifierProvider.notifier).reset();
        Navigator.of(context).pop(true);
      }
    }
  }
}
