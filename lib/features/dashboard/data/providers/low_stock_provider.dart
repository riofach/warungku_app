import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/data/models/item_model.dart';
import '../../../inventory/data/providers/providers.dart';

/// Provider untuk mengelola state low stock items
/// Menggunakan repository yang sudah ada untuk fetch data
final lowStockProvider = AsyncNotifierProvider<LowStockNotifier, List<Item>>(
  LowStockNotifier.new,
);

/// Notifier untuk low stock items dengan AsyncValue state management
class LowStockNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    // Gunakan repository yang sudah ada
    final repository = ref.read(itemRepositoryProvider);
    return repository.getLowStockItems();
  }

  /// Method untuk refresh data (untuk pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(itemRepositoryProvider).getLowStockItems(),
    );
  }
}
