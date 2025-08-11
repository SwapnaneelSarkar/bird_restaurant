// lib/ui_components/image_picker_with_crop.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import 'image_cropper_widget.dart';

class ImagePickerWithCropWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
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
        child: selectedImage != null
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
          title,
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
            aspectRatio: aspectRatio,
            child: Image.file(
              selectedImage!,
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
        Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: FontSize.s14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          maxSizeText,
          style: TextStyle(
            fontSize: FontSize.s12,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        if (enableCrop) ...[
          const SizedBox(height: 4),
          Text(
            'Image will be cropped to ${aspectRatio == 1.0 ? 'square' : '${aspectRatio.toStringAsFixed(1)}:1'} ratio',
            style: TextStyle(
              fontSize: FontSize.s10,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        
        if (enableCrop) {
          // Show cropping interface
          await _showCropper(context, imageFile.path);
        } else {
          onImageSelected(imageFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _showCropper(BuildContext context, String imagePath) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCropperWidget(
          imagePath: imagePath,
          aspectRatio: aspectRatio,
          onCropComplete: (File croppedFile) {
            Navigator.of(context).pop();
            onImageSelected(croppedFile);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
} 