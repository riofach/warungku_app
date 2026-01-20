import '../../../../core/services/supabase_service.dart';
import '../models/housing_block_model.dart';

/// Repository for housing block management
/// Handles CRUD operations for housing blocks (delivery locations)
class HousingBlockRepository {
  /// Default timeout for database operations (30 seconds)
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all housing blocks from database
  /// Returns list sorted by name ascending
  Future<List<HousingBlock>> getHousingBlocks() async {
    try {
      final response = await SupabaseService.client
          .from('housing_blocks')
          .select('id, name, created_at, updated_at')
          .order('name', ascending: true)
          .timeout(_timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      });

      return (response as List)
          .map((json) => HousingBlock.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      }
      throw Exception('Gagal memuat blok perumahan: $e');
    }
  }

  /// Add new housing block to database
  /// Returns the created housing block
  Future<HousingBlock> addHousingBlock(String name) async {
    try {
      final response = await SupabaseService.client
          .from('housing_blocks')
          .insert({'name': name})
          .select('id, name, created_at, updated_at')
          .single()
          .timeout(_timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      });

      return HousingBlock.fromJson(response);
    } catch (e) {
      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('timeout')) {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      }
      if (errorMessage.contains('duplicate') || 
          errorMessage.contains('unique')) {
        throw Exception('Blok dengan nama tersebut sudah ada');
      }
      
      throw Exception('Gagal menambahkan blok: $e');
    }
  }

  /// Update housing block name
  /// Returns the updated housing block
  Future<HousingBlock> updateHousingBlock(String id, String name) async {
    try {
      final response = await SupabaseService.client
          .from('housing_blocks')
          .update({
            'name': name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('id, name, created_at, updated_at')
          .single()
          .timeout(_timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      });

      return HousingBlock.fromJson(response);
    } catch (e) {
      // Handle specific errors
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('timeout')) {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      }
      if (errorMessage.contains('duplicate') || 
          errorMessage.contains('unique')) {
        throw Exception('Blok dengan nama tersebut sudah ada');
      }
      
      throw Exception('Gagal memperbarui blok: $e');
    }
  }

  /// Delete housing block from database
  /// Orders with this block will keep their existing housing_block_id reference
  Future<void> deleteHousingBlock(String id) async {
    try {
      await SupabaseService.client
          .from('housing_blocks')
          .delete()
          .eq('id', id)
          .timeout(_timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      });
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('Koneksi timeout. Periksa jaringan Anda.');
      }
      throw Exception('Gagal menghapus blok: $e');
    }
  }
}
