import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../data/models/housing_block_model.dart';
import '../../data/providers/housing_blocks_provider.dart';
import '../widgets/add_housing_block_dialog.dart';
import '../widgets/edit_housing_block_dialog.dart';
import '../widgets/delete_housing_block_dialog.dart';

/// Housing Blocks management screen
/// FR12: Admin dapat mengelola daftar blok perumahan untuk delivery
class HousingBlocksScreen extends ConsumerStatefulWidget {
  const HousingBlocksScreen({super.key});

  @override
  ConsumerState<HousingBlocksScreen> createState() => _HousingBlocksScreenState();
}

class _HousingBlocksScreenState extends ConsumerState<HousingBlocksScreen> {
  @override
  void initState() {
    super.initState();
    // Load housing blocks on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(housingBlockListNotifierProvider.notifier).loadBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(housingBlockListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blok Perumahan'),
      ),
      body: _buildBody(blockState),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddBlock,
        tooltip: 'Tambah Blok',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(HousingBlockListState state) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Memuat blok perumahan...');
    }

    if (state.hasError) {
      return AppErrorWidget(
        message: 'Gagal memuat blok perumahan',
        details: state.errorMessage,
        onRetry: () {
          ref.read(housingBlockListNotifierProvider.notifier).refresh();
        },
      );
    }

    if (state.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_city_outlined,
        title: 'Belum ada blok perumahan',
        subtitle: 'Tap + untuk menambah.',
        actionLabel: 'Tambah Blok',
        onAction: _handleAddBlock,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(housingBlockListNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: state.blocks.length,
        itemBuilder: (context, index) {
          final block = state.blocks[index];
          return _HousingBlockCard(
            block: block,
            onTap: () => _handleEditBlock(block),
            onDelete: () => _handleDeleteBlock(block),
          );
        },
      ),
    );
  }

  Future<void> _handleAddBlock() async {
    final success = await AddHousingBlockDialog.show(context);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blok berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleEditBlock(HousingBlock block) async {
    final success = await EditHousingBlockDialog.show(context, block);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blok berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleDeleteBlock(HousingBlock block) async {
    final success = await DeleteHousingBlockDialog.show(context, block);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blok berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Housing Block card widget
class _HousingBlockCard extends StatelessWidget {
  final HousingBlock block;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HousingBlockCard({
    required this.block,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.location_city,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          block.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              tooltip: 'Edit',
              onPressed: onTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: 'Hapus',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onDelete, // AC6: Long-press to delete
      ),
    );
  }
}
