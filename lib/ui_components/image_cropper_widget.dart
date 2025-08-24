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

  // Image display state for accurate cropping
  Size _displayedImageSize = Size.zero;
  Offset _displayedImageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recalculate crop area when dependencies change (e.g., screen size, orientation)
    if (_image != null && _screenSize != MediaQuery.of(context).size) {
      _initializeCropArea();
    }
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
      
      // Get safe area insets for better positioning
      final EdgeInsets safeArea = MediaQuery.of(context).padding;
      final double availableWidth = _screenSize.width - safeArea.left - safeArea.right;
      final double availableHeight = _screenSize.height - safeArea.top - safeArea.bottom;
      
      // Calculate crop area size based on aspect ratio
      final double maxWidth = availableWidth - 40;
      final double maxHeight = availableHeight * 0.6;
      
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
        safeArea.left + (availableWidth - cropWidth) / 2,
        safeArea.top + (availableHeight - cropHeight) / 2 - 50,
      );
      
      // Calculate how the image will be displayed with BoxFit.cover
      _calculateImageDisplay();
    });
  }

  void _calculateImageDisplay() {
    if (_image == null) return;
    
    final double screenAspectRatio = _screenSize.width / _screenSize.height;
    final double imageAspectRatio = _imageSize.width / _imageSize.height;
    
    double displayedImageWidth, displayedImageHeight;
    
    if (imageAspectRatio > screenAspectRatio) {
      // Image is wider than screen - fit to height, crop width
      displayedImageHeight = _screenSize.height;
      displayedImageWidth = displayedImageHeight * imageAspectRatio;
      _displayedImageOffset = Offset(
        (_screenSize.width - displayedImageWidth) / 2,
        0,
      );
    } else {
      // Image is taller than screen - fit to width, crop height
      displayedImageWidth = _screenSize.width;
      displayedImageHeight = displayedImageWidth / imageAspectRatio;
      _displayedImageOffset = Offset(
        0,
        (_screenSize.height - displayedImageHeight) / 2,
      );
    }
    
    _displayedImageSize = Size(displayedImageWidth, displayedImageHeight);
    
    // Ensure displayed image size is not zero
    if (_displayedImageSize.width == 0 || _displayedImageSize.height == 0) {
      _displayedImageSize = _imageSize;
      _displayedImageOffset = Offset.zero;
    }
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
          // Background image with proper positioning
          Positioned(
            left: _displayedImageOffset.dx,
            top: _displayedImageOffset.dy,
            width: _displayedImageSize.width,
            height: _displayedImageSize.height,
            child: Transform.scale(
              scale: _scale,
              child: Transform.translate(
                offset: _imageOffset,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: _displayedImageSize.width,
                  height: _displayedImageSize.height,
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
      
      // Constrain the image position to keep crop area visible
      _constrainImagePosition();
    });
  }

  void _constrainImagePosition() {
    // Calculate the transformed image bounds
    final double transformedImageWidth = _displayedImageSize.width * _scale;
    final double transformedImageHeight = _displayedImageSize.height * _scale;
    
    // Calculate the minimum offset needed to keep crop area visible
    final double minOffsetX = _cropOffset.dx - transformedImageWidth + _cropSize.width;
    final double maxOffsetX = _cropOffset.dx;
    final double minOffsetY = _cropOffset.dy - transformedImageHeight + _cropSize.height;
    final double maxOffsetY = _cropOffset.dy;
    
    // Constrain the image offset
    _imageOffset = Offset(
      _imageOffset.dx.clamp(minOffsetX, maxOffsetX),
      _imageOffset.dy.clamp(minOffsetY, maxOffsetY),
    );
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

      // Calculate the actual crop parameters with proper coordinate transformation
      
      // Get the transformed image dimensions and position
      final double transformedImageWidth = _displayedImageSize.width * _scale;
      final double transformedImageHeight = _displayedImageSize.height * _scale;
      final double transformedImageOffsetX = _displayedImageOffset.dx + _imageOffset.dx;
      final double transformedImageOffsetY = _displayedImageOffset.dy + _imageOffset.dy;
      
      // Calculate the crop area in screen coordinates
      final double cropScreenX = _cropOffset.dx;
      final double cropScreenY = _cropOffset.dy;
      final double cropScreenWidth = _cropSize.width;
      final double cropScreenHeight = _cropSize.height;
      
      // Convert screen crop coordinates to image coordinates
      // First, convert screen coordinates to the transformed image coordinates
      final double cropInTransformedImageX = cropScreenX - transformedImageOffsetX;
      final double cropInTransformedImageY = cropScreenY - transformedImageOffsetY;
      
      // Then convert to original image coordinates
      final double cropImageX = cropInTransformedImageX * (_imageSize.width / transformedImageWidth);
      final double cropImageY = cropInTransformedImageY * (_imageSize.height / transformedImageHeight);
      final double cropImageWidth = cropScreenWidth * (_imageSize.width / transformedImageWidth);
      final double cropImageHeight = cropScreenHeight * (_imageSize.height / transformedImageHeight);
      
      // Account for device pixel ratio for more accurate cropping
      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double adjustedCropImageX = cropImageX / devicePixelRatio;
      final double adjustedCropImageY = cropImageY / devicePixelRatio;
      final double adjustedCropImageWidth = cropImageWidth / devicePixelRatio;
      final double adjustedCropImageHeight = cropImageHeight / devicePixelRatio;
      
      // Ensure crop area is within image bounds
      final double clampedCropX = adjustedCropImageX.clamp(0.0, _imageSize.width - adjustedCropImageWidth);
      final double clampedCropY = adjustedCropImageY.clamp(0.0, _imageSize.height - adjustedCropImageHeight);
      final double clampedCropWidth = adjustedCropImageWidth.clamp(0.0, _imageSize.width - clampedCropX);
      final double clampedCropHeight = adjustedCropImageHeight.clamp(0.0, _imageSize.height - clampedCropY);
      
      // Additional safety checks
      if (clampedCropWidth <= 0 || clampedCropHeight <= 0) {
        throw Exception('Invalid crop dimensions: ${clampedCropWidth} x ${clampedCropHeight}');
      }
      
      if (clampedCropX < 0 || clampedCropY < 0 || 
          clampedCropX + clampedCropWidth > _imageSize.width ||
          clampedCropY + clampedCropHeight > _imageSize.height) {
        throw Exception('Crop area outside image bounds');
      }

      debugPrint('=== CROPPING DEBUG INFO ===');
      debugPrint('Original image size: ${_imageSize.width} x ${_imageSize.height}');
      debugPrint('Screen size: ${_screenSize.width} x ${_screenSize.height}');
      debugPrint('Device pixel ratio: $devicePixelRatio');
      debugPrint('Displayed image size: ${_displayedImageSize.width} x ${_displayedImageSize.height}');
      debugPrint('Displayed image offset: ${_displayedImageOffset.dx}, ${_displayedImageOffset.dy}');
      debugPrint('Transformed image: ${transformedImageWidth} x ${transformedImageHeight}');
      debugPrint('Transformed offset: ${transformedImageOffsetX}, ${transformedImageOffsetY}');
      debugPrint('User scale: $_scale');
      debugPrint('User offset: ${_imageOffset.dx}, ${_imageOffset.dy}');
      debugPrint('Crop screen area: ${cropScreenX}, ${cropScreenY}, ${cropScreenWidth} x ${cropScreenHeight}');
      debugPrint('Crop in transformed image: ${cropInTransformedImageX}, ${cropInTransformedImageY}');
      debugPrint('Crop in original image: ${cropImageX}, ${cropImageY}, ${cropImageWidth} x ${cropImageHeight}');
      debugPrint('Adjusted crop (with DPR): ${adjustedCropImageX}, ${adjustedCropImageY}, ${adjustedCropImageWidth} x ${adjustedCropImageHeight}');
      debugPrint('Final clamped crop: ${clampedCropX}, ${clampedCropY}, ${clampedCropWidth} x ${clampedCropHeight}');
      debugPrint('==========================');

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