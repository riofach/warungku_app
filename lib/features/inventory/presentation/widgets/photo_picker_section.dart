import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Photo picker section for item form
/// Displays photo preview and provides camera/gallery selection
/// Implements AC: 3 (Photo Upload via Camera or Gallery)
/// Story 3.5: Added existingImageUrl for edit mode support (AC3, AC7)
class PhotoPickerSection extends StatelessWidget {
  /// Currently selected image file (new image from camera/gallery)
  final File? selectedImage;

  /// Existing image URL for edit mode (AC2: pre-load existing image)
  final String? existingImageUrl;

  /// Callback when image is selected
  final void Function(File? file) onImageSelected;

  /// Callback when image is removed
  final VoidCallback onImageRemoved;

  /// Maximum file size in bytes (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  const PhotoPickerSection({
    super.key,
    required this.selectedImage,
    this.existingImageUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  /// Check if there's any image to display (new or existing)
  bool get _hasAnyImage =>
      (selectedImage != null && selectedImage!.existsSync()) ||
      (existingImageUrl != null && existingImageUrl!.isNotEmpty);

  /// Show bottom sheet with photo source options (AC3)
  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'Pilih Foto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(),

              // Camera option
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera(context);
                },
              ),

              // Gallery option
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(context);
                },
              ),

              // Remove photo option (AC7: visible if photo exists)
              if (_hasAnyImage)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onImageRemoved();
                  },
                ),

              // Cancel option
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.textSecondary),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from camera
  Future<void> _pickFromCamera(BuildContext context) async {
    // Store messenger before async gap to avoid context issues
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (photo == null) return;

      final file = File(photo.path);
      
      // Verify file exists before proceeding
      if (!await file.exists()) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('File foto tidak ditemukan'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto maksimal 5MB'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      onImageSelected(file);
      
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery(BuildContext context) async {
    // Store messenger before async gap to avoid context issues
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      final file = File(image.path);
      
      // Verify file exists before proceeding
      if (!await file.exists()) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('File foto tidak ditemukan'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto maksimal 5MB'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      onImageSelected(file);
      
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal membuka galeri: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoOptions(context),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _buildPreview(),
      ),
    );
  }

  /// Build preview based on priority: selectedImage > existingImageUrl > placeholder
  /// AC2: Display network image if existingImageUrl provided
  Widget _buildPreview() {
    // Priority 1: New selected image from camera/gallery
    if (selectedImage != null && selectedImage!.existsSync()) {
      return _buildFileImagePreview();
    }
    
    // Priority 2: Existing image URL (for edit mode)
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return _buildNetworkImagePreview();
    }
    
    // Priority 3: Placeholder
    return _buildPlaceholder();
  }

  /// Build image preview for newly selected file
  Widget _buildFileImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            selectedImage!,
            fit: BoxFit.cover,
            cacheWidth: 800, // Limit decoded image size for memory efficiency
            cacheHeight: 800,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorState();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              );
            },
          ),
          _buildEditOverlay(),
        ],
      ),
    );
  }

  /// Build image preview for network URL (edit mode - AC2)
  Widget _buildNetworkImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            existingImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.surface,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorState();
            },
          ),
          _buildEditOverlay(),
        ],
      ),
    );
  }

  /// Build error state when image fails to load
  Widget _buildErrorState() {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gagal memuat preview',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap untuk memilih foto baru',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build overlay with edit hint
  Widget _buildEditOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Tap untuk mengubah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build placeholder when no photo selected
  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap untuk menambah foto',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Maksimal 5MB (JPEG, PNG)',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
