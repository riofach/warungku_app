import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/housing_block_model.dart';
import '../repositories/housing_block_repository.dart';

/// Provider for HousingBlockRepository
final housingBlockRepositoryProvider = Provider<HousingBlockRepository>((ref) {
  return HousingBlockRepository();
});

/// State for housing block list
enum HousingBlockListStatus {
  initial,
  loading,
  loaded,
  error,
}

class HousingBlockListState {
  final HousingBlockListStatus status;
  final List<HousingBlock> blocks;
  final String? errorMessage;

  const HousingBlockListState({
    required this.status,
    required this.blocks,
    this.errorMessage,
  });

  factory HousingBlockListState.initial() => const HousingBlockListState(
        status: HousingBlockListStatus.initial,
        blocks: [],
      );

  factory HousingBlockListState.loading() => const HousingBlockListState(
        status: HousingBlockListStatus.loading,
        blocks: [],
      );

  factory HousingBlockListState.loaded(List<HousingBlock> blocks) => HousingBlockListState(
        status: HousingBlockListStatus.loaded,
        blocks: blocks,
      );

  factory HousingBlockListState.error(String message) => HousingBlockListState(
        status: HousingBlockListStatus.error,
        blocks: [],
        errorMessage: message,
      );

  bool get isLoading => status == HousingBlockListStatus.loading;
  bool get hasError => status == HousingBlockListStatus.error;
  bool get isEmpty => status == HousingBlockListStatus.loaded && blocks.isEmpty;
}

/// State for housing block mutations (add/update/delete)
enum HousingBlockActionStatus {
  initial,
  loading,
  success,
  error,
}

class HousingBlockActionState {
  final HousingBlockActionStatus status;
  final String? successMessage;
  final String? errorMessage;

  const HousingBlockActionState({
    required this.status,
    this.successMessage,
    this.errorMessage,
  });

  factory HousingBlockActionState.initial() => const HousingBlockActionState(
        status: HousingBlockActionStatus.initial,
      );

  factory HousingBlockActionState.loading() => const HousingBlockActionState(
        status: HousingBlockActionStatus.loading,
      );

  factory HousingBlockActionState.success(String message) => HousingBlockActionState(
        status: HousingBlockActionStatus.success,
        successMessage: message,
      );

  factory HousingBlockActionState.error(String message) => HousingBlockActionState(
        status: HousingBlockActionStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == HousingBlockActionStatus.loading;
  bool get hasError => status == HousingBlockActionStatus.error;
  bool get isSuccess => status == HousingBlockActionStatus.success;
}

/// Notifier for housing block list
class HousingBlockListNotifier extends Notifier<HousingBlockListState> {
  @override
  HousingBlockListState build() {
    return HousingBlockListState.initial();
  }

  /// Load all housing blocks
  Future<void> loadBlocks() async {
    state = HousingBlockListState.loading();

    try {
      final repository = ref.read(housingBlockRepositoryProvider);
      final blocks = await repository.getHousingBlocks();
      state = HousingBlockListState.loaded(blocks);
    } catch (e) {
      state = HousingBlockListState.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Refresh housing block list
  Future<void> refresh() async {
    await loadBlocks();
  }
}

/// Notifier for adding housing block
class AddHousingBlockNotifier extends Notifier<HousingBlockActionState> {
  @override
  HousingBlockActionState build() {
    return HousingBlockActionState.initial();
  }

  /// Add new housing block
  Future<bool> addBlock(String name) async {
    state = HousingBlockActionState.loading();

    try {
      final repository = ref.read(housingBlockRepositoryProvider);
      await repository.addHousingBlock(name);
      state = HousingBlockActionState.success('Blok berhasil ditambahkan');
      
      // Refresh housing block list
      ref.read(housingBlockListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = HousingBlockActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = HousingBlockActionState.initial();
  }
}

/// Notifier for updating housing block
class UpdateHousingBlockNotifier extends Notifier<HousingBlockActionState> {
  @override
  HousingBlockActionState build() {
    return HousingBlockActionState.initial();
  }

  /// Update housing block
  Future<bool> updateBlock(String id, String name) async {
    state = HousingBlockActionState.loading();

    try {
      final repository = ref.read(housingBlockRepositoryProvider);
      await repository.updateHousingBlock(id, name);
      state = HousingBlockActionState.success('Blok berhasil diperbarui');
      
      // Refresh housing block list
      ref.read(housingBlockListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = HousingBlockActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = HousingBlockActionState.initial();
  }
}

/// Notifier for deleting housing block
class DeleteHousingBlockNotifier extends Notifier<HousingBlockActionState> {
  @override
  HousingBlockActionState build() {
    return HousingBlockActionState.initial();
  }

  /// Delete housing block
  Future<bool> deleteBlock(String id) async {
    state = HousingBlockActionState.loading();

    try {
      final repository = ref.read(housingBlockRepositoryProvider);
      await repository.deleteHousingBlock(id);
      state = HousingBlockActionState.success('Blok berhasil dihapus');
      
      // Refresh housing block list
      ref.read(housingBlockListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = HousingBlockActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = HousingBlockActionState.initial();
  }
}

/// Providers
final housingBlockListNotifierProvider = NotifierProvider<HousingBlockListNotifier, HousingBlockListState>(() {
  return HousingBlockListNotifier();
});

final addHousingBlockNotifierProvider = NotifierProvider<AddHousingBlockNotifier, HousingBlockActionState>(() {
  return AddHousingBlockNotifier();
});

final updateHousingBlockNotifierProvider = NotifierProvider<UpdateHousingBlockNotifier, HousingBlockActionState>(() {
  return UpdateHousingBlockNotifier();
});

final deleteHousingBlockNotifierProvider = NotifierProvider<DeleteHousingBlockNotifier, HousingBlockActionState>(() {
  return DeleteHousingBlockNotifier();
});
