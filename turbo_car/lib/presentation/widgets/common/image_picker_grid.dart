/// Image Picker Grid
/// Grid widget for selecting and displaying multiple images
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerGrid extends StatelessWidget {
  final List<XFile> images;
  final List<String> existingImageUrls;
  final int maxImages;
  final int minImages;
  final void Function(XFile) onImageAdded;
  final void Function(int) onImageRemoved;
  final void Function(int)? onExistingImageRemoved;
  final bool enabled;

  const ImagePickerGrid({
    super.key,
    required this.images,
    this.existingImageUrls = const [],
    this.maxImages = 10,
    this.minImages = 1,
    required this.onImageAdded,
    required this.onImageRemoved,
    this.onExistingImageRemoved,
    this.enabled = true,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    onImageAdded(image);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    onImageAdded(image);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = existingImageUrls.length + images.length;
    final canAddMore = totalImages < maxImages && enabled;
    final hasAnyImages = totalImages > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (min $minImages, max $maxImages)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).appBarTheme.foregroundColor?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        if (!hasAnyImages && !canAddMore)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'No images selected',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).appBarTheme.foregroundColor?.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages + (canAddMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Add button at the end
                if (index == totalImages) {
                  return _buildAddButton(context);
                }
                // Existing images first
                if (index < existingImageUrls.length) {
                  return _buildExistingImageTile(context, index);
                }
                // Then new images
                final newIndex = index - existingImageUrls.length;
                return _buildImageTile(context, newIndex);
              },
            ),
          ),
        if (totalImages < minImages)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please add at least $minImages image${minImages > 1 ? 's' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImageTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showExistingImagePreview(context, index),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                existingImageUrls[index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 120,
                  color: Theme.of(context).cardColor,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 120,
                    height: 120,
                    color: Theme.of(context).cardColor,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            if (enabled && onExistingImageRemoved != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onExistingImageRemoved!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, index),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(images[index].path),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            if (enabled)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onImageRemoved(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full-size image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(images[index].path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            // Image counter
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${index + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExistingImagePreview(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full-size image from URL
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existingImageUrls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.broken_image, size: 64),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            // Image counter
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${index + 1} / ${existingImageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
