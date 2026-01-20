import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// State for category list
enum CategoryListStatus {
  initial,
  loading,
  loaded,
  error,
}

class CategoryListState {
  final CategoryListStatus status;
  final List<Category> categories;
  final String? errorMessage;

  const CategoryListState({
    required this.status,
    required this.categories,
    this.errorMessage,
  });

  factory CategoryListState.initial() => const CategoryListState(
        status: CategoryListStatus.initial,
        categories: [],
      );

  factory CategoryListState.loading() => const CategoryListState(
        status: CategoryListStatus.loading,
        categories: [],
      );

  factory CategoryListState.loaded(List<Category> categories) => CategoryListState(
        status: CategoryListStatus.loaded,
        categories: categories,
      );

  factory CategoryListState.error(String message) => CategoryListState(
        status: CategoryListStatus.error,
        categories: [],
        errorMessage: message,
      );

  bool get isLoading => status == CategoryListStatus.loading;
  bool get hasError => status == CategoryListStatus.error;
  bool get isEmpty => status == CategoryListStatus.loaded && categories.isEmpty;
}

/// State for category mutations (add/update/delete)
enum CategoryActionStatus {
  initial,
  loading,
  success,
  error,
}

class CategoryActionState {
  final CategoryActionStatus status;
  final String? successMessage;
  final String? errorMessage;

  const CategoryActionState({
    required this.status,
    this.successMessage,
    this.errorMessage,
  });

  factory CategoryActionState.initial() => const CategoryActionState(
        status: CategoryActionStatus.initial,
      );

  factory CategoryActionState.loading() => const CategoryActionState(
        status: CategoryActionStatus.loading,
      );

  factory CategoryActionState.success(String message) => CategoryActionState(
        status: CategoryActionStatus.success,
        successMessage: message,
      );

  factory CategoryActionState.error(String message) => CategoryActionState(
        status: CategoryActionStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == CategoryActionStatus.loading;
  bool get hasError => status == CategoryActionStatus.error;
  bool get isSuccess => status == CategoryActionStatus.success;
}

/// Notifier for category list
class CategoryListNotifier extends Notifier<CategoryListState> {
  @override
  CategoryListState build() {
    return CategoryListState.initial();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    state = CategoryListState.loading();

    try {
      final repository = ref.read(categoryRepositoryProvider);
      final categories = await repository.getCategories();
      state = CategoryListState.loaded(categories);
    } catch (e) {
      state = CategoryListState.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Refresh category list
  Future<void> refresh() async {
    await loadCategories();
  }
}

/// Notifier for adding category
class AddCategoryNotifier extends Notifier<CategoryActionState> {
  @override
  CategoryActionState build() {
    return CategoryActionState.initial();
  }

  /// Add new category
  Future<bool> addCategory(String name) async {
    state = CategoryActionState.loading();

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.addCategory(name);
      state = CategoryActionState.success('Kategori berhasil ditambahkan');
      
      // Refresh category list
      ref.read(categoryListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = CategoryActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = CategoryActionState.initial();
  }
}

/// Notifier for updating category
class UpdateCategoryNotifier extends Notifier<CategoryActionState> {
  @override
  CategoryActionState build() {
    return CategoryActionState.initial();
  }

  /// Update category
  Future<bool> updateCategory(String id, String name) async {
    state = CategoryActionState.loading();

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.updateCategory(id, name);
      state = CategoryActionState.success('Kategori berhasil diperbarui');
      
      // Refresh category list
      ref.read(categoryListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = CategoryActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = CategoryActionState.initial();
  }
}

/// Notifier for deleting category
class DeleteCategoryNotifier extends Notifier<CategoryActionState> {
  @override
  CategoryActionState build() {
    return CategoryActionState.initial();
  }

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    state = CategoryActionState.loading();

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(id);
      state = CategoryActionState.success('Kategori berhasil dihapus');
      
      // Refresh category list
      ref.read(categoryListNotifierProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = CategoryActionState.error(
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = CategoryActionState.initial();
  }
}

/// Providers
final categoryListNotifierProvider = NotifierProvider<CategoryListNotifier, CategoryListState>(() {
  return CategoryListNotifier();
});

final addCategoryNotifierProvider = NotifierProvider<AddCategoryNotifier, CategoryActionState>(() {
  return AddCategoryNotifier();
});

final updateCategoryNotifierProvider = NotifierProvider<UpdateCategoryNotifier, CategoryActionState>(() {
  return UpdateCategoryNotifier();
});

final deleteCategoryNotifierProvider = NotifierProvider<DeleteCategoryNotifier, CategoryActionState>(() {
  return DeleteCategoryNotifier();
});
