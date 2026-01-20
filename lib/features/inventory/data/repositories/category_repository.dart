import '../../../../core/services/supabase_service.dart';
import '../models/category_model.dart';

/// Repository for category management
/// Handles CRUD operations for product categories
class CategoryRepository {
  /// Get all categories from database with item count
  /// Returns list sorted by name ascending
  Future<List<Category>> getCategories() async {
    try {
      final response = await SupabaseService.client
          .from('categories')
          .select('id, name, created_at, updated_at, items(count)')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  /// Add new category to database
  /// Returns the created category
  Future<Category> addCategory(String name) async {
    try {
      final response = await SupabaseService.client
          .from('categories')
          .insert({'name': name})
          .select('id, name, created_at, updated_at, items(count)')
          .single();

      return Category.fromJson(response);
    } catch (e) {
      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('duplicate') || 
          errorMessage.contains('unique')) {
        throw Exception('Kategori dengan nama tersebut sudah ada');
      }
      
      throw Exception('Gagal menambahkan kategori: $e');
    }
  }

  /// Update category name
  /// Returns the updated category
  Future<Category> updateCategory(String id, String name) async {
    try {
      final response = await SupabaseService.client
          .from('categories')
          .update({
            'name': name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('id, name, created_at, updated_at, items(count)')
          .single();

      return Category.fromJson(response);
    } catch (e) {
      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('duplicate') || 
          errorMessage.contains('unique')) {
        throw Exception('Kategori dengan nama tersebut sudah ada');
      }
      
      throw Exception('Gagal memperbarui kategori: $e');
    }
  }

  /// Delete category from database
  /// Items in this category will have their category_id set to NULL
  /// (due to ON DELETE SET NULL FK constraint)
  Future<void> deleteCategory(String id) async {
    try {
      await SupabaseService.client
          .from('categories')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  /// Get item count for a specific category
  /// Used to show warning when deleting category with items
  Future<int> getItemCount(String categoryId) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('id')
          .eq('category_id', categoryId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
