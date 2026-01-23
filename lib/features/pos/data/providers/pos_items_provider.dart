import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../inventory/data/models/item_model.dart';

/// State for POS items list
enum PosItemsStatus {
  initial,
  loading,
  loaded,
  error,
}

class PosItemsState {
  final PosItemsStatus status;
  final List<Item> items;
  final String? errorMessage;

  const PosItemsState({
    required this.status,
    required this.items,
    this.errorMessage,
  });

  factory PosItemsState.initial() => const PosItemsState(
        status: PosItemsStatus.initial,
        items: [],
      );

  factory PosItemsState.loading() => const PosItemsState(
        status: PosItemsStatus.loading,
        items: [],
      );

  factory PosItemsState.loaded(List<Item> items) => PosItemsState(
        status: PosItemsStatus.loaded,
        items: items,
      );

  factory PosItemsState.error(String message) => PosItemsState(
        status: PosItemsStatus.error,
        items: [],
        errorMessage: message,
      );

  bool get isLoading => status == PosItemsStatus.loading;
  bool get hasError => status == PosItemsStatus.error;
  bool get isEmpty => status == PosItemsStatus.loaded && items.isEmpty;
  bool get isLoaded => status == PosItemsStatus.loaded;
}

/// Notifier for POS items - loads all active items for POS screen
class PosItemsNotifier extends Notifier<PosItemsState> {
  @override
  PosItemsState build() {
    return PosItemsState.initial();
  }

  /// Load all active items from Supabase
  /// Query includes category join for display
  Future<void> loadItems() async {
    state = PosItemsState.loading();

    try {
      final supabase = Supabase.instance.client;

      // Query items with category join
      // Only load active items, sorted by name
      final response = await supabase
          .from('items')
          .select('*, categories(id, name)')
          .eq('is_active', true)
          .order('name', ascending: true);

      final items = (response as List)
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();

      state = PosItemsState.loaded(items);
    } catch (e) {
      state = PosItemsState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Refresh items list
  Future<void> refresh() async {
    await loadItems();
  }
}

/// Provider for POS items
final posItemsNotifierProvider =
    NotifierProvider<PosItemsNotifier, PosItemsState>(() {
  return PosItemsNotifier();
});
