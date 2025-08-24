import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../lib/ui_components/image_cropper_widget.dart';
import '../lib/presentation/resources/colors.dart';

class ImageCropperExample extends StatefulWidget {
  @override
  _ImageCropperExampleState createState() => _ImageCropperExampleState();
}

class _ImageCropperExampleState extends State<ImageCropperExample> {
  File? _selectedImage;
  String _selectedAspectRatio = '1:1';
  
  final Map<String, double> _aspectRatios = {
    '1:1 (Square)': 1.0,
    '4:3 (Standard)': 4.0 / 3.0,
    '16:9 (Widescreen)': 16.0 / 9.0,
    '3:4 (Portrait)': 3.0 / 4.0,
    '2:3 (Tall Portrait)': 2.0 / 3.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Cropper Example'),
        backgroundColor: ColorManager.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aspect ratio selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Aspect Ratio:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedAspectRatio,
                      isExpanded: true,
                      items: _aspectRatios.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(key),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAspectRatio = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Image picker button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('Pick Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Selected image preview
            if (_selectedImage != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cropped Image Preview:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: _aspectRatios[_selectedAspectRatio]!,
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aspect Ratio: $_selectedAspectRatio',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            Spacer(),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Select your desired aspect ratio\n'
                      '2. Tap "Pick Image" to select an image\n'
                      '3. Use the cropping interface to adjust the image\n'
                      '4. Drag to move the image and pinch to zoom\n'
                      '5. Tap "Done" to complete the crop',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if (image != null) {
      // Navigate to crop screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperWidget(
            imagePath: image.path,
            aspectRatio: _aspectRatios[_selectedAspectRatio]!,
            onCropComplete: (File croppedFile) {
              setState(() {
                _selectedImage = croppedFile;
              });
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image cropped successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }
}

// Example usage in main app
class ImageCropperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Cropper Example',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ImageCropperExample(),
    );
  }
} 