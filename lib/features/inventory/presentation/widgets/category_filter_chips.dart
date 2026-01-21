import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/providers/categories_provider.dart';
import '../../data/providers/items_provider.dart';

/// Category filter chips widget for filtering items by category
/// Shows horizontal scrolling chips with "Semua" as first option
class CategoryFilterChips extends ConsumerStatefulWidget {
  /// Callback when category selection changes
  final ValueChanged<String?>? onCategoryChanged;

  const CategoryFilterChips({
    super.key,
    this.onCategoryChanged,
  });

  @override
  ConsumerState<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends ConsumerState<CategoryFilterChips> {
  @override
  void initState() {
    super.initState();
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(categoryListNotifierProvider);
      if (state.status == CategoryListStatus.initial) {
        ref.read(categoryListNotifierProvider.notifier).loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryListNotifierProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);

    // Loading state
    if (categoryState.isLoading) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Error state - log and show minimal
    if (categoryState.hasError) {
      developer.log(
        'CategoryFilterChips: Failed to load categories - ${categoryState.errorMessage}',
        name: 'CategoryFilterChips',
        level: 900, // Warning level
      );
      return const SizedBox.shrink();
    }

    // Build chips list with "Semua" as first option
    final categories = categoryState.categories;

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // "Semua" chip (All categories)
            _buildChip(
              context,
              label: 'Semua',
              isSelected: selectedCategoryId == null,
              onSelected: () {
                ref.read(selectedCategoryFilterProvider.notifier).state = null;
                widget.onCategoryChanged?.call(null);
              },
            ),
            const SizedBox(width: AppSpacing.xs),

            // Category chips
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _buildChip(
                  context,
                  label: category.name,
                  isSelected: selectedCategoryId == category.id,
                  onSelected: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        category.id;
                    widget.onCategoryChanged?.call(category.id);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      showCheckmark: false,
    );
  }
}

/// Simpler category chip list for use in forms
class CategoryChipSelector extends ConsumerWidget {
  /// Currently selected category ID
  final String? selectedId;

  /// Callback when selection changes
  final ValueChanged<String?> onChanged;

  /// Whether to include "None" option
  final bool allowNone;

  const CategoryChipSelector({
    super.key,
    this.selectedId,
    required this.onChanged,
    this.allowNone = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryListNotifierProvider);

    if (categoryState.isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (categoryState.hasError || categoryState.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (allowNone)
          ChoiceChip(
            label: const Text('Tanpa Kategori'),
            selected: selectedId == null,
            onSelected: (_) => onChanged(null),
          ),
        ...categoryState.categories.map((category) {
          return ChoiceChip(
            label: Text(category.name),
            selected: selectedId == category.id,
            onSelected: (_) => onChanged(category.id),
          );
        }),
      ],
    );
  }
}
