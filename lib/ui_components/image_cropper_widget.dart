// lib/ui_components/image_cropper_widget.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/rendering.dart';
import '../presentation/resources/colors.dart';

class ImageCropperWidget extends StatefulWidget {
  final String imagePath;
  final double aspectRatio;
  final Function(File) onCropComplete;
  final VoidCallback onCancel;

  const ImageCropperWidget({
    Key? key,
    required this.imagePath,
    required this.aspectRatio,
    required this.onCropComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  ui.Image? _image;
  Size _imageSize = Size.zero;
  Size _screenSize = Size.zero;
  
  // Crop area state
  Offset _cropOffset = Offset.zero;
  Size _cropSize = Size.zero;
  
  // Image transformation state
  double _scale = 1.0;
  Offset _imageOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final File imageFile = File(widget.imagePath);
      if (!await imageFile.exists()) {
        setState(() {
          _errorMessage = 'Image file not found';
          _isLoading = false;
        });
        return;
      }

      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      setState(() {
        _image = image;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _isLoading = false;
      });

      // Initialize crop area after image is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCropArea();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading image: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeCropArea() {
    if (_image == null) return;

    setState(() {
      _screenSize = MediaQuery.of(context).size;
      
      // Calculate crop area size based on aspect ratio
      final double maxWidth = _screenSize.width - 40;
      final double maxHeight = _screenSize.height * 0.6;
      
      double cropWidth, cropHeight;
      
      if (widget.aspectRatio > 1) {
        // Landscape
        cropWidth = maxWidth;
        cropHeight = cropWidth / widget.aspectRatio;
        if (cropHeight > maxHeight) {
          cropHeight = maxHeight;
          cropWidth = cropHeight * widget.aspectRatio;
        }
      } else {
        // Portrait or square
        cropHeight = maxHeight;
        cropWidth = cropHeight * widget.aspectRatio;
        if (cropWidth > maxWidth) {
          cropWidth = maxWidth;
          cropHeight = cropWidth / widget.aspectRatio;
        }
      }
      
      _cropSize = Size(cropWidth, cropHeight);
      _cropOffset = Offset(
        (_screenSize.width - cropWidth) / 2,
        (_screenSize.height - cropHeight) / 2 - 50,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: Text(
          'Crop Image',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _cropImage,
            child: Text(
              'Done',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading image...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onCropComplete(File(widget.imagePath));
              },
              child: Text('Use Original Image'),
            ),
          ],
        ),
      );
    }

    if (_image == null) {
      return Center(
        child: Text(
          'Failed to load image',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Transform.scale(
              scale: _scale,
              child: Transform.translate(
                offset: _imageOffset,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: _screenSize.width,
                  height: _screenSize.height,
                ),
              ),
            ),
          ),
          
          // Top overlay (above crop area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _cropOffset.dy,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Bottom overlay (below crop area)
          Positioned(
            top: _cropOffset.dy + _cropSize.height,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Left overlay (left of crop area)
          Positioned(
            top: _cropOffset.dy,
            left: 0,
            width: _cropOffset.dx,
            height: _cropSize.height,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Right overlay (right of crop area)
          Positioned(
            top: _cropOffset.dy,
            left: _cropOffset.dx + _cropSize.width,
            right: 0,
            height: _cropSize.height,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Crop area border
          Positioned(
            left: _cropOffset.dx,
            top: _cropOffset.dy,
            child: Container(
              width: _cropSize.width,
              height: _cropSize.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.transparent,
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Drag to move image • Pinch to zoom',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crop area: ${widget.aspectRatio == 1.0 ? 'Square' : '${widget.aspectRatio.toStringAsFixed(1)}:1'}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _startScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Update scale
      _scale = (_startScale * details.scale).clamp(0.5, 3.0);
      
      // Update position
      final Offset delta = details.focalPoint - _startFocalPoint;
      _imageOffset += delta;
      _startFocalPoint = details.focalPoint;
    });
  }

  Future<void> _cropImage() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Processing image...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      // Calculate the actual crop parameters based on current transformation
      // The image is displayed with BoxFit.cover, so we need to calculate the actual displayed image dimensions
      
      // Calculate the displayed image size (what's actually visible on screen)
      final double screenAspectRatio = _screenSize.width / _screenSize.height;
      final double imageAspectRatio = _imageSize.width / _imageSize.height;
      
      double displayedImageWidth, displayedImageHeight;
      double imageOffsetX, imageOffsetY;
      
      if (imageAspectRatio > screenAspectRatio) {
        // Image is wider than screen - fit to height
        displayedImageHeight = _screenSize.height;
        displayedImageWidth = displayedImageHeight * imageAspectRatio;
        imageOffsetX = (_screenSize.width - displayedImageWidth) / 2;
        imageOffsetY = 0;
      } else {
        // Image is taller than screen - fit to width
        displayedImageWidth = _screenSize.width;
        displayedImageHeight = displayedImageWidth / imageAspectRatio;
        imageOffsetX = 0;
        imageOffsetY = (_screenSize.height - displayedImageHeight) / 2;
      }
      
      // Apply the user's transformations (scale and offset)
      final double transformedImageWidth = displayedImageWidth * _scale;
      final double transformedImageHeight = displayedImageHeight * _scale;
      final double transformedImageOffsetX = imageOffsetX + _imageOffset.dx;
      final double transformedImageOffsetY = imageOffsetY + _imageOffset.dy;
      
      // Calculate the crop area in screen coordinates
      final double cropScreenX = _cropOffset.dx;
      final double cropScreenY = _cropOffset.dy;
      final double cropScreenWidth = _cropSize.width;
      final double cropScreenHeight = _cropSize.height;
      
      // Convert screen crop coordinates to image coordinates
      final double cropImageX = (cropScreenX - transformedImageOffsetX) * (_imageSize.width / transformedImageWidth);
      final double cropImageY = (cropScreenY - transformedImageOffsetY) * (_imageSize.height / transformedImageHeight);
      final double cropImageWidth = cropScreenWidth * (_imageSize.width / transformedImageWidth);
      final double cropImageHeight = cropScreenHeight * (_imageSize.height / transformedImageHeight);
      
      // Ensure crop area is within image bounds
      final double clampedCropX = cropImageX.clamp(0.0, _imageSize.width - cropImageWidth);
      final double clampedCropY = cropImageY.clamp(0.0, _imageSize.height - cropImageHeight);
      final double clampedCropWidth = cropImageWidth.clamp(0.0, _imageSize.width - clampedCropX);
      final double clampedCropHeight = cropImageHeight.clamp(0.0, _imageSize.height - clampedCropY);

      debugPrint('Image size: ${_imageSize.width} x ${_imageSize.height}');
      debugPrint('Screen size: ${_screenSize.width} x ${_screenSize.height}');
      debugPrint('Displayed image: ${displayedImageWidth} x ${displayedImageHeight}');
      debugPrint('Transformed image: ${transformedImageWidth} x ${transformedImageHeight}');
      debugPrint('Transformed offset: ${transformedImageOffsetX}, ${transformedImageOffsetY}');
      debugPrint('Crop screen: ${cropScreenX}, ${cropScreenY}, ${cropScreenWidth} x ${cropScreenHeight}');
      debugPrint('Crop image: ${cropImageX}, ${cropImageY}, ${cropImageWidth} x ${cropImageHeight}');
      debugPrint('Clamped crop: ${clampedCropX}, ${clampedCropY}, ${clampedCropWidth} x ${clampedCropHeight}');

      // Create a cropped image using the ui.Image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the cropped portion of the image
      final Rect srcRect = Rect.fromLTWH(
        clampedCropX,
        clampedCropY,
        clampedCropWidth,
        clampedCropHeight,
      );
      final Rect dstRect = Rect.fromLTWH(0, 0, clampedCropWidth, clampedCropHeight);
      
      canvas.drawImageRect(_image!, srcRect, dstRect, Paint());
      
      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(
        clampedCropWidth.round(),
        clampedCropHeight.round(),
      );
      
      // Convert the cropped image to bytes
      final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert cropped image to bytes');
      }
      
      final Uint8List croppedBytes = byteData.buffer.asUint8List();
      
      // Compress the cropped image
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
        croppedBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 90,
        rotate: 0,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (compressedBytes != null) {
        // Create a temporary file with the cropped image
        final String tempPath = '${widget.imagePath}_cropped.jpg';
        final File croppedFile = File(tempPath);
        await croppedFile.writeAsBytes(compressedBytes);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image cropped successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        widget.onCropComplete(croppedFile);
      } else {
        // Fallback to original image
        widget.onCropComplete(File(widget.imagePath));
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      debugPrint('Error cropping image: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image. Using original.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Fallback to original image
      widget.onCropComplete(File(widget.imagePath));
    }
  }
} 