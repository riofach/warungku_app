import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/item_model.dart';

/// Repository for item/product management
/// Handles CRUD and query operations for inventory items
class ItemRepository {
  /// Timeout duration for database operations
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all active items from database with category join
  /// Supports optional search query and category filter
  ///
  /// [searchQuery] - Optional search term for filtering by name (case-insensitive)
  /// [categoryId] - Optional category ID for filtering
  ///
  /// Returns list sorted by name ascending
  Future<List<Item>> getItems({
    String? searchQuery,
    String? categoryId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('items')
          .select('*, categories(name)')
          .eq('is_active', true);

      // Apply category filter if provided
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      // Apply search filter if provided (case-insensitive)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Order by name ascending
      final response = await query
          .order('name', ascending: true)
          .timeout(_timeout);

      return (response as List)
          .map((json) => Item.fromJson(json))
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat data barang: $e');
    }
  }

  /// Get items filtered by category only
  /// Convenience method for category-based filtering
  Future<List<Item>> getItemsByCategory(String categoryId) async {
    return getItems(categoryId: categoryId);
  }

  /// Search items by name with optional category filter
  /// Uses case-insensitive partial matching
  Future<List<Item>> searchItems(String query, {String? categoryId}) async {
    return getItems(searchQuery: query, categoryId: categoryId);
  }

  /// Get a single item by ID
  /// Returns null if not found
  Future<Item?> getItemById(String id) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('*, categories(name)')
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);

      if (response == null) return null;
      return Item.fromJson(response);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat detail barang: $e');
    }
  }

  /// Get count of items by category
  /// Used for category statistics
  Future<int> getItemCountByCategory(String categoryId) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('id')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .timeout(_timeout);

      return (response as List).length;
    } on TimeoutException {
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get items with low stock (at or below threshold)
  /// Used for stock alerts
  Future<List<Item>> getLowStockItems() async {
    try {
      // Note: Supabase doesn't support column-to-column comparison directly
      // We fetch all and filter in memory
      final response = await SupabaseService.client
          .from('items')
          .select('*, categories(name)')
          .eq('is_active', true)
          .order('stock', ascending: true)
          .timeout(_timeout);

      final allItems = (response as List)
          .map((json) => Item.fromJson(json))
          .toList();

      // Filter items where stock <= stock_threshold
      return allItems
          .where((item) => item.stock <= item.stockThreshold)
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat data stok menipis: $e');
    }
  }

  /// Get items that are out of stock (stock = 0)
  Future<List<Item>> getOutOfStockItems() async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select('*, categories(name)')
          .eq('is_active', true)
          .eq('stock', 0)
          .order('name', ascending: true)
          .timeout(_timeout);

      return (response as List)
          .map((json) => Item.fromJson(json))
          .toList();
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memuat data stok habis: $e');
    }
  }

  /// Upload image to Supabase Storage
  /// Compresses image to max 800px width, quality 80% before upload
  /// Returns the public URL of the uploaded image
  ///
  /// File path format: items/{uuid}_{timestamp}.{extension}
  Future<String> uploadImage(File imageFile) async {
    try {
      // Compress image before upload (AC6 requirement)
      final compressedFile = await _compressImage(imageFile);
      final fileToUpload = compressedFile ?? imageFile;

      // Generate unique filename
      const uuid = Uuid();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${uuid.v4()}_$timestamp.jpg'; // Always save as jpg after compression
      final filePath = 'items/$fileName';

      // Read file as bytes for upload
      final fileBytes = await fileToUpload.readAsBytes();

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from('product-images')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          )
          .timeout(_timeout);

      // Get public URL
      final publicUrl = SupabaseService.client.storage
          .from('product-images')
          .getPublicUrl(filePath);

      // Clean up compressed temp file if created
      if (compressedFile != null && compressedFile.existsSync()) {
        try {
          await compressedFile.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }

      return publicUrl;
    } on TimeoutException {
      throw Exception('Koneksi timeout saat upload foto.');
    } catch (e) {
      throw Exception('Gagal mengupload foto: $e');
    }
  }

  /// Compress image to max 800px width, quality 80% (AC6 requirement)
  /// Returns compressed file or null if compression fails
  Future<File?> _compressImage(File file) async {
    try {
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) return null;

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      // If compression fails, return null to use original file
      return null;
    }
  }

  /// Create a new item in the database
  /// Returns the ID of the created item
  Future<String> createItem({
    required String name,
    String? categoryId,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    required int stockThreshold,
    required bool isActive,
    String? imageUrl,
  }) async {
    try {
      final data = {
        'name': name,
        'category_id': categoryId,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'stock_threshold': stockThreshold,
        'is_active': isActive,
        'image_url': imageUrl,
      };

      final response = await SupabaseService.client
          .from('items')
          .insert(data)
          .select('id')
          .single()
          .timeout(_timeout);

      return response['id'] as String;
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      // Check for duplicate name error
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505')) {
        throw Exception('Barang dengan nama ini sudah ada');
      }
      throw Exception('Gagal menyimpan barang: $e');
    }
  }
}
