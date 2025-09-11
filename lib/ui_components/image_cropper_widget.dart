// lib/ui_components/image_cropper_widget.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
// import '../presentation/resources/colors.dart';

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
  bool _isDialogOpen = false;
  
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
  
  // Store the actual image widget bounds for accurate coordinate mapping (unused)
  // Rect _imageWidgetBounds = Rect.zero;
  
  // Flag to prevent multiple simultaneous crop operations
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    // Ensure any open dialog is closed to avoid Navigator errors
    if (_isDialogOpen && mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _isDialogOpen = false;
    }
    super.dispose();
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
      
      // Guard against invalid sizes
      if (!cropWidth.isFinite || !cropHeight.isFinite || cropWidth <= 0 || cropHeight <= 0) {
        cropWidth = _screenSize.width * 0.8;
        cropHeight = cropWidth / (widget.aspectRatio == 0 ? 1.0 : widget.aspectRatio);
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
    
    // Calculate the actual display size of the image widget
    // This is the key fix - we need to account for the actual widget bounds
    if (_screenSize.width <= 0 || _screenSize.height <= 0) {
      _screenSize = MediaQuery.of(context).size;
    }
    final double screenAspectRatio = _screenSize.width <= 0 || _screenSize.height <= 0
        ? 1.0
        : _screenSize.width / _screenSize.height;
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
    
    if (!displayedImageWidth.isFinite || !displayedImageHeight.isFinite ||
        displayedImageWidth <= 0 || displayedImageHeight <= 0) {
      displayedImageWidth = _imageSize.width;
      displayedImageHeight = _imageSize.height;
    }
    _displayedImageSize = Size(displayedImageWidth, displayedImageHeight);
    
    // Ensure displayed image size is not zero
    if (_displayedImageSize.width == 0 || _displayedImageSize.height == 0) {
      _displayedImageSize = _imageSize;
      _displayedImageOffset = Offset.zero;
    }
    
    // If needed later: bounds of image widget for mapping coordinates
    // _imageWidgetBounds = Rect.fromLTWH(
    //   _displayedImageOffset.dx,
    //   _displayedImageOffset.dy,
    //   _displayedImageSize.width,
    //   _displayedImageSize.height,
    // );
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
            onPressed: _isCropping ? null : _cropImage,
            child: _isCropping 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
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
            Icon(Icons.error_outline, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white),
            ),
          ],
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
            left: _displayedImageOffset.dx.isFinite ? _displayedImageOffset.dx : 0,
            top: _displayedImageOffset.dy.isFinite ? _displayedImageOffset.dy : 0,
            width: _displayedImageSize.width.isFinite && _displayedImageSize.width > 0 ? _displayedImageSize.width : _imageSize.width,
            height: _displayedImageSize.height.isFinite && _displayedImageSize.height > 0 ? _displayedImageSize.height : _imageSize.height,
            child: Transform.scale(
              scale: _scale,
              child: Transform.translate(
                offset: _imageOffset,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: _displayedImageSize.width.isFinite && _displayedImageSize.width > 0 ? _displayedImageSize.width : _imageSize.width,
                  height: _displayedImageSize.height.isFinite && _displayedImageSize.height > 0 ? _displayedImageSize.height : _imageSize.height,
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
            left: _cropOffset.dx.isFinite ? _cropOffset.dx : 0,
            top: _cropOffset.dy.isFinite ? _cropOffset.dy : 0,
            child: Container(
              width: _cropSize.width.isFinite && _cropSize.width > 0 ? _cropSize.width : 200,
              height: _cropSize.height.isFinite && _cropSize.height > 0 ? _cropSize.height : 200,
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
              child: Text(
                'Pinch to zoom and drag to move the image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
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
    // Prevent multiple simultaneous crop operations
    if (_isCropping) {
      return;
    }
    
    setState(() {
      _isCropping = true;
    });

    try {
      // Check if widget is still mounted before showing dialog
      if (!mounted) return;
      
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
      _isDialogOpen = true;

      // FIXED COORDINATE TRANSFORMATION LOGIC
      
      // Step 1: Get the current transformed image bounds
      final double transformedImageWidth = _displayedImageSize.width * _scale;
      final double transformedImageHeight = _displayedImageSize.height * _scale;
      
      // Step 2: Calculate the actual position of the transformed image on screen
      final double transformedImageLeft = _displayedImageOffset.dx + _imageOffset.dx;
      final double transformedImageTop = _displayedImageOffset.dy + _imageOffset.dy;
      
      // Step 3: Calculate the crop area in screen coordinates
      final double cropScreenLeft = _cropOffset.dx;
      final double cropScreenTop = _cropOffset.dy;
      final double cropScreenRight = cropScreenLeft + _cropSize.width;
      final double cropScreenBottom = cropScreenTop + _cropSize.height;
      
      // Step 4: Calculate the intersection of crop area with the transformed image
      final double intersectionLeft = cropScreenLeft.clamp(transformedImageLeft, transformedImageLeft + transformedImageWidth);
      final double intersectionTop = cropScreenTop.clamp(transformedImageTop, transformedImageTop + transformedImageHeight);
      final double intersectionRight = cropScreenRight.clamp(transformedImageLeft, transformedImageLeft + transformedImageWidth);
      final double intersectionBottom = cropScreenBottom.clamp(transformedImageTop, transformedImageTop + transformedImageHeight);
      
      // Step 5: Convert intersection coordinates to image coordinates
      final double cropInImageLeft = (intersectionLeft - transformedImageLeft) * (_imageSize.width / transformedImageWidth);
      final double cropInImageTop = (intersectionTop - transformedImageTop) * (_imageSize.height / transformedImageHeight);
      final double cropInImageRight = (intersectionRight - transformedImageLeft) * (_imageSize.width / transformedImageWidth);
      final double cropInImageBottom = (intersectionBottom - transformedImageTop) * (_imageSize.height / transformedImageHeight);
      
      // Step 6: Calculate final crop dimensions
      final double cropImageX = cropInImageLeft.clamp(0.0, _imageSize.width);
      final double cropImageY = cropInImageTop.clamp(0.0, _imageSize.height);
      final double cropImageWidth = (cropInImageRight - cropInImageLeft).clamp(0.0, _imageSize.width - cropImageX);
      final double cropImageHeight = (cropInImageBottom - cropInImageTop).clamp(0.0, _imageSize.height - cropImageY);
      
      // Additional validation for crop dimensions
      debugPrint('🔍 Crop validation:');
      debugPrint('  - cropImageX: $cropImageX (0 to ${_imageSize.width})');
      debugPrint('  - cropImageY: $cropImageY (0 to ${_imageSize.height})');
      debugPrint('  - cropImageWidth: $cropImageWidth (0 to ${_imageSize.width - cropImageX})');
      debugPrint('  - cropImageHeight: $cropImageHeight (0 to ${_imageSize.height - cropImageY})');
      
      // Additional safety checks
      if (cropImageWidth <= 0 || cropImageHeight <= 0) {
        throw Exception('Invalid crop dimensions: ${cropImageWidth} x ${cropImageHeight}');
      }
      
      if (cropImageX < 0 || cropImageY < 0 || 
          cropImageX + cropImageWidth > _imageSize.width ||
          cropImageY + cropImageHeight > _imageSize.height) {
        throw Exception('Crop area outside image bounds');
      }

      debugPrint('=== FIXED CROPPING DEBUG INFO ===');
      debugPrint('Original image size: ${_imageSize.width} x ${_imageSize.height}');
      debugPrint('Screen size: ${_screenSize.width} x ${_screenSize.height}');
      debugPrint('Displayed image size: ${_displayedImageSize.width} x ${_displayedImageSize.height}');
      debugPrint('Displayed image offset: ${_displayedImageOffset.dx}, ${_displayedImageOffset.dy}');
      debugPrint('Transformed image: ${transformedImageWidth} x ${transformedImageHeight}');
      debugPrint('Transformed image position: $transformedImageLeft, $transformedImageTop');
      debugPrint('User scale: $_scale');
      debugPrint('User offset: ${_imageOffset.dx}, ${_imageOffset.dy}');
      debugPrint('Crop screen area: $cropScreenLeft, $cropScreenTop, ${_cropSize.width} x ${_cropSize.height}');
      debugPrint('Intersection: $intersectionLeft, $intersectionTop, $intersectionRight, $intersectionBottom');
      debugPrint('Crop in image: $cropImageX, $cropImageY, $cropImageWidth x $cropImageHeight');
      debugPrint('===============================');

      // Create a cropped image using the ui.Image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the cropped portion of the image
      final Rect srcRect = Rect.fromLTWH(
        cropImageX,
        cropImageY,
        cropImageWidth,
        cropImageHeight,
      );
      final Rect dstRect = Rect.fromLTWH(0, 0, cropImageWidth, cropImageHeight);
      
      canvas.drawImageRect(_image!, srcRect, dstRect, Paint());
      
      final ui.Picture picture = recorder.endRecording();
      final ui.Image croppedImage = await picture.toImage(
        cropImageWidth.round(),
        cropImageHeight.round(),
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

      // Close loading dialog if still open
      if (mounted && _isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _isDialogOpen = false;
      }

      if (compressedBytes != null) {
        // Create a temporary file with the cropped image in proper temp directory
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String tempPath = '${tempDir.path}/$fileName';
        final File croppedFile = File(tempPath);
        await croppedFile.writeAsBytes(compressedBytes);
        
        // Show success message if widget is still mounted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image cropped successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        debugPrint('✅ Cropped image saved to: $tempPath');
        debugPrint('✅ Cropped file exists: ${await croppedFile.exists()}');
        debugPrint('✅ Cropped file size: ${await croppedFile.length()} bytes');
        
        if (mounted) {
          widget.onCropComplete(croppedFile);
        }
      } else {
        // Fallback to original image
        if (mounted) {
          widget.onCropComplete(File(widget.imagePath));
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && _isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _isDialogOpen = false;
      }
      
      debugPrint('Error cropping image: $e');
      
      // Show error message if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to crop image. Using original.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Fallback to original image
      if (mounted) {
        widget.onCropComplete(File(widget.imagePath));
      }
    } finally {
      // Reset the cropping flag
      if (mounted) {
        setState(() {
          _isCropping = false;
        });
      }
    }
  }
} 