import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
  static const String _legacyDeletedItemNamePrefix = '__deleted__::';

  bool _isLegacyDeletedItem(Item item) {
    return item.name.startsWith(_legacyDeletedItemNamePrefix);
  }

  Future<bool> _purgeItemRow(String itemId) async {
    await SupabaseService.client
        .from('item_units')
        .delete()
        .eq('item_id', itemId)
        .timeout(_timeout);

    final response = await SupabaseService.client
        .from('items')
        .delete()
        .eq('id', itemId)
        .select('id')
        .maybeSingle()
        .timeout(_timeout);

    return response != null;
  }

  /// Extracts file path from Supabase Storage public URL (Story 3.8 - AC5)
  ///
  /// Example URL: https://xxx.supabase.co/storage/v1/object/public/product-images/items/uuid_timestamp.jpg
  /// Returns: items/uuid_timestamp.jpg
  ///
  /// Returns null if URL is null, empty, malformed, or doesn't contain bucket name.
  static String? extractFilePathFromUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find index of bucket name "product-images"
      final bucketIndex = pathSegments.indexOf('product-images');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return null;
      }

      // Return everything after bucket name
      return pathSegments.sublist(bucketIndex + 1).join('/');
    } catch (e) {
      return null;
    }
  }

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
    bool includeInactive = false,
  }) async {
    try {
      var query = SupabaseService.client
          .from('items')
          .select('*, categories(name), item_units(*)');

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

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

      final items = (response as List)
          .map((json) => Item.fromJson(json))
          .toList();
      final legacyDeletedItems = items.where(_isLegacyDeletedItem).toList();

      for (final item in legacyDeletedItems) {
        try {
          await _purgeItemRow(item.id);
        } catch (_) {
          // Legacy cleanup is best-effort; keep normal list loading resilient.
        }
      }

      return items.where((item) => !_isLegacyDeletedItem(item)).toList();
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
          .select('*, categories(name), item_units(*)')
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);

      if (response == null) return null;
      final item = Item.fromJson(response);
      if (_isLegacyDeletedItem(item)) {
        try {
          await _purgeItemRow(item.id);
        } catch (_) {
          // Ignore cleanup failure here; the row stays hidden from callers.
        }
        return null;
      }
      return item;
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

      return (response as List).map((json) => Item.fromJson(json)).toList();
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
      final fileName =
          '${uuid.v4()}_$timestamp.jpg'; // Always save as jpg after compression
      final filePath = 'items/$fileName';

      // Read file as bytes for upload
      final fileBytes = await fileToUpload.readAsBytes();

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from('product-images')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
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
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      // If compression fails, return null to use original file
      return null;
    }
  }

  /// Deletes an image from Supabase Storage (Story 3.8 - Task 1.2, AC1, AC2, AC3, AC6)
  ///
  /// Returns true if deletion successful, false otherwise.
  /// This method is non-blocking - errors are logged but not thrown (AC6).
  ///
  /// [imageUrl] - Public URL of image to delete
  ///
  /// Behavior:
  /// - Returns true if imageUrl is null or empty (nothing to delete)
  /// - Extracts file path from URL and calls Supabase Storage remove()
  /// - Logs errors but doesn't throw (non-blocking for AC6)
  Future<bool> deleteImage(String? imageUrl) async {
    debugPrint('[DELETE IMAGE] Starting deletion. imageUrl: $imageUrl');

    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint(
        '[DELETE IMAGE] imageUrl is null or empty, nothing to delete. Returning true.',
      );
      return true;
    }

    final filePath = extractFilePathFromUrl(imageUrl);
    if (filePath == null) {
      debugPrint(
        '[DELETE IMAGE] Could not extract file path from URL: $imageUrl',
      );
      return false;
    }

    debugPrint('[DELETE IMAGE] Extracted file path: $filePath');

    try {
      await SupabaseService.client.storage.from('product-images').remove([
        filePath,
      ]);

      debugPrint('[DELETE IMAGE] Successfully deleted image: $filePath');
      return true;
    } catch (e) {
      // Log error but don't throw - this is non-blocking (AC6)
      debugPrint('[DELETE IMAGE] Failed to delete image $filePath: $e');
      return false;
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
    bool hasUnits = false,
    String baseUnit = 'pcs',
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
        'has_units': hasUnits,
        'base_unit': baseUnit,
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

  /// Update an existing item in the database (Story 3.5 - AC5, AC6; Story 3.8 - AC1, AC2, AC4, AC6)
  /// Handles image upload if new image provided
  /// Sets image_url to null if imageRemoved flag is true
  /// Deletes old image from storage when replacing or removing photo (Story 3.8 - AC1, AC2)
  /// Returns = updated Item object
  ///
  /// [id] - Item ID to update
  /// [imageFile] - New image to upload (optional)
  /// [imageRemoved] - Flag to clear existing image (AC7)
  /// [oldImageUrl] - Old image URL to delete from storage (Story 3.8 - AC1, AC2)
  Future<Item> updateItem({
    required String id,
    required String name,
    String? categoryId,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    required int stockThreshold,
    required bool isActive,
    File? imageFile,
    bool imageRemoved = false,
    String? oldImageUrl, // Story 3.8 - AC1, AC2
    bool hasUnits = false,
    String baseUnit = 'pcs',
  }) async {
    debugPrint(
      '[UPDATE ITEM] Starting updateItem. id=$id, oldImageUrl=$oldImageUrl, imageRemoved=$imageRemoved, imageFile=${imageFile != null}',
    );

    try {
      String? newImageUrl;

      // Handle image scenarios (AC6, AC7)
      if (imageRemoved) {
        // User explicitly removed image - delete old image if exists (Story 3.8 - AC2, AC4, AC6)
        if (oldImageUrl != null) {
          debugPrint(
            '[UPDATE ITEM] User removed photo - deleting old image: $oldImageUrl',
          );
          await deleteImage(oldImageUrl); // Non-blocking
        } else {
          debugPrint(
            '[UPDATE ITEM] User removed photo but oldImageUrl is null - nothing to delete',
          );
        }
        newImageUrl = null;
      } else if (imageFile != null) {
        // User selected new image - delete old image first (Story 3.8 - AC1, AC6)
        if (oldImageUrl != null) {
          debugPrint(
            '[UPDATE ITEM] User selected new photo - deleting old image: $oldImageUrl',
          );
          await deleteImage(oldImageUrl); // Non-blocking
        } else {
          debugPrint(
            '[UPDATE ITEM] User selected new photo but oldImageUrl is null - nothing to delete',
          );
        }
        // Upload new image
        newImageUrl = await uploadImage(imageFile);
        debugPrint('[UPDATE ITEM] New image uploaded: $newImageUrl');
      }
      // If neither, keep existing image (don't include in update)

      // Build update data
      final updateData = <String, dynamic>{
        'name': name,
        'category_id': categoryId,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'stock_threshold': stockThreshold,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
        'has_units': hasUnits,
        'base_unit': baseUnit,
      };

      // Only include image_url if we're changing it (AC6, AC7)
      if (imageRemoved || imageFile != null) {
        updateData['image_url'] = newImageUrl;
      }

      // Update item record using Supabase
      final response = await SupabaseService.client
          .from('items')
          .update(updateData)
          .eq('id', id)
          .select('*, categories(name)')
          .single()
          .timeout(_timeout);

      return Item.fromJson(response);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      // Check for duplicate name error
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique') ||
          e.toString().contains('23505')) {
        throw Exception('Barang dengan nama ini sudah ada');
      }
      // Check for not found error (PGRST116)
      if (e.toString().contains('PGRST116') ||
          e.toString().contains('not found') ||
          e.toString().contains('0 rows')) {
        throw Exception('Barang tidak ditemukan');
      }
      throw Exception('Gagal memperbarui barang: $e');
    }
  }

  /// Update only unit-config fields (has_units, base_unit) and optionally image.
  /// Used by PurchaseFlowScreen for existing items.
  Future<void> updateItemUnitConfig({
    required String id,
    required bool hasUnits,
    required String baseUnit,
    String? imageUrl,
    bool imageExplicitlyCleared = false,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'has_units': hasUnits,
        'base_unit': baseUnit,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (imageExplicitlyCleared || imageUrl != null) {
        updateData['image_url'] = imageUrl;
      }

      await SupabaseService.client
          .from('items')
          .update(updateData)
          .eq('id', id)
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      throw Exception('Gagal memperbarui konfigurasi barang: $e');
    }
  }

  /// Updates item stock to a new value (Stock Opname) (Story 3.7 - AC5, AC6)
  ///
  /// Returns the updated Item on success.
  /// Throws exception on error.
  ///
  /// [id] - Item ID to update
  /// [newStock] - New stock count value
  Future<Item> updateStock(String id, int newStock) async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .update({
            'stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('*, categories(name)')
          .maybeSingle()
          .timeout(_timeout);

      if (response == null) {
        throw Exception('Barang tidak ditemukan');
      }

      return Item.fromJson(response);
    } on TimeoutException {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Barang tidak ditemukan');
      }
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    } catch (e) {
      // Re-throw our own exceptions
      if (e.toString().contains('Barang tidak ditemukan')) {
        rethrow;
      }
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        throw Exception('Gagal memperbarui stok. Periksa koneksi internet.');
      }
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Permanently deletes an item row (and its unit variants) from the database.
  ///
  /// Returns true if deletion was successful.
  /// Throws exception on error.
  /// Story 3.8: Delete image from storage before deleting the item row (AC3)
  ///
  /// [id] - Item ID to delete
  /// [imageUrl] - Image URL to delete from storage (Story 3.8 - AC3)
  Future<bool> deleteItem(String id, {String? imageUrl}) async {
    debugPrint('[DELETE ITEM] Starting deleteItem. id=$id, imageUrl=$imageUrl');

    try {
      // Story 3.8: Delete image from storage first (non-blocking) (AC3, AC4, AC6)
      if (imageUrl != null) {
        debugPrint('[DELETE ITEM] Attempting to delete image: $imageUrl');
        await deleteImage(imageUrl);
      } else {
        debugPrint('[DELETE ITEM] No image to delete (imageUrl is null)');
      }

      final deleted = await _purgeItemRow(id);

      if (!deleted) {
        debugPrint('[DELETE ITEM] Item not found or already deleted');
        throw Exception('Barang tidak ditemukan');
      }

      debugPrint('[DELETE ITEM] Successfully deleted item row: $id');
      return true;
    } on TimeoutException {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Barang tidak ditemukan');
      }
      if (e.code == '23503' ||
          e.message.toLowerCase().contains('foreign key') ||
          e.message.toLowerCase().contains('violates')) {
        throw Exception(
          'Barang sudah dipakai di data transaksi/pembelian sehingga tidak bisa dihapus permanen.',
        );
      }
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    } catch (e) {
      // Re-throw our own exceptions
      if (e.toString().contains('Barang tidak ditemukan')) {
        rethrow;
      }
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        throw Exception('Gagal menghapus. Periksa koneksi internet.');
      }
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
