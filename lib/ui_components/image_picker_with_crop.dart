// lib/ui_components/image_picker_with_crop.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import 'image_cropper_widget.dart';

class ImagePickerWithCropWidget extends StatefulWidget {
  final File? selectedImage;
  final Function(File) onImageSelected;
  final String title;
  final String subtitle;
  final String maxSizeText;
  final double aspectRatio;
  final bool enableCrop;

  const ImagePickerWithCropWidget({
    Key? key,
    this.selectedImage,
    required this.onImageSelected,
    required this.title,
    required this.subtitle,
    required this.maxSizeText,
    this.aspectRatio = 1.0, // Default square aspect ratio
    this.enableCrop = true,
  }) : super(key: key);

  @override
  State<ImagePickerWithCropWidget> createState() => _ImagePickerWithCropWidgetState();
}

class _ImagePickerWithCropWidgetState extends State<ImagePickerWithCropWidget> {
  // Flag to prevent multiple simultaneous image picking operations
  bool _isPickingImage = false;
  bool _isNavigatorPopping = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isPickingImage ? null : () => _pickImage(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: widget.selectedImage != null
            ? _buildSelectedImagePreview()
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: ColorManager.black,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Image.file(
              widget.selectedImage!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change image',
          style: TextStyle(
            fontSize: FontSize.s12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _isPickingImage 
          ? SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            )
          : Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
        const SizedBox(height: 12),
        Text(
          _isPickingImage ? 'Processing...' : widget.subtitle,
          style: TextStyle(
            fontSize: FontSize.s14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.maxSizeText,
          style: TextStyle(
            fontSize: FontSize.s12,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.enableCrop) ...[
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    // Prevent multiple simultaneous image picking operations
    if (_isPickingImage) {
      return;
    }
    
    setState(() {
      _isPickingImage = true;
    });
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (!mounted) return;

      if (pickedFile == null) {
        // User cancelled; nothing to do
        return;
      }

      // Validate file existence and non-empty size
      final File imageFile = File(pickedFile.path);
      final bool exists = await imageFile.exists();
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image file not found.')),
        );
        return;
      }
      try {
        final int fileLen = await imageFile.length();
        if (fileLen <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image file is empty.')),
          );
          return;
        }
      } catch (_) {
        // If length fails, still attempt to proceed safely
      }

      if (widget.enableCrop) {
        // Show cropping interface
        await _showCropper(context, imageFile.path);
      } else {
        widget.onImageSelected(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _showCropper(BuildContext context, String imagePath) async {
    if (!mounted) return;
    _isNavigatorPopping = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCropperWidget(
          imagePath: imagePath,
          aspectRatio: widget.aspectRatio,
          onCropComplete: (File croppedFile) {
            if (_isNavigatorPopping) return;
            _isNavigatorPopping = true;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            if (mounted) {
              widget.onImageSelected(croppedFile);
            }
          },
          onCancel: () {
            if (_isNavigatorPopping) return;
            _isNavigatorPopping = true;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
} 