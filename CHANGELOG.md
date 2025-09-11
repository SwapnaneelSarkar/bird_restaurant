# Changelog

All notable changes to the Bird Partner app will be documented in this file.

## [3.0.13] - 2024-12-19

### 🚀 Major Update: Android 15 Compatibility
- **Build Number**: Updated to version code 20 for Play Store release
- **Version**: 3.0.13+20 (pubspec) / 3.0.13 (versionName) / 20 (versionCode)

### 🔧 Technical Improvements
- **Android 15 (API 35) Support**: 
  - Upgraded target SDK from 34 to 35
  - Full compatibility with latest Android security and performance features
  - Future-proofed for upcoming Android versions
- **Play Core Compatibility**: 
  - Resolved Android 14/15 Play Core compatibility issues
  - Fixed broadcast receiver compatibility problems
  - Maintained all Flutter functionality including deferred components

### 📱 Platform Support
- **Android**: 
  - Minimum SDK: 23 (Android 6.0)
  - Target SDK: 35 (Android 15) ← **NEW**
  - Compile SDK: 35 (Android 15)
- **iOS**: Improved compatibility with latest iOS versions
- **Cross-platform**: Enhanced stability and performance

### 🛡️ Security & Performance
- **Latest Security**: Access to Android 15 security patches and optimizations
- **Enhanced Privacy**: Improved app sandboxing and privacy controls
- **Better Performance**: Optimized memory management and battery optimization
- **Latest APIs**: Access to newest Android features and optimizations

### 📚 Documentation
- Created comprehensive Android 15 upgrade guide
- Updated Play Core compatibility documentation
- Added detailed technical implementation notes

## [3.0.10] - 2024-12-19

### 🔄 Version Update for Play Store
- **Build Number**: Updated to version code 16 for Play Store release
- **Version**: 3.0.10+15 (pubspec) / 3.0.10 (versionName) / 16 (versionCode)

## [3.0.10] - 2024-12-19

### 🐛 Fixed
- **Image Cropping Issues**: Fixed critical bug where the wrong portion of images was being selected during cropping
  - Corrected coordinate transformation logic for accurate image cropping
  - Added proper device pixel ratio handling for different screen densities
  - Improved screen responsiveness across different device sizes
  - Added position constraints to prevent users from moving images outside crop area
  - Enhanced error handling and fallback behavior
  - Added comprehensive debug logging for troubleshooting

### 🔧 Technical Improvements
- **Enhanced Image Cropper Widget**:
  - Added `_calculateImageDisplay()` method for accurate display calculations
  - Implemented `_constrainImagePosition()` to keep crop area visible
  - Added safe area insets consideration for better positioning
  - Added `didChangeDependencies()` to handle orientation changes
  - Improved bounds checking and validation

### 📱 Platform Support
- **Android**: Updated to target SDK 35, minimum SDK 23
- **iOS**: Improved compatibility with latest iOS versions
- **Cross-platform**: Better handling of different screen sizes and aspect ratios

### 🧪 Testing
- Added comprehensive test suite for image cropping functionality
- Unit tests for coordinate transformation calculations
- Tests for different aspect ratios and screen sizes
- Device pixel ratio handling validation

### 📚 Documentation
- Created detailed documentation for image cropping fixes
- Added usage examples and best practices
- Included troubleshooting guide for common issues

## [3.0.9] - Previous Version

### Features
- Restaurant management functionality
- Order processing and status updates
- Real-time chat with customers
- Push notifications
- Image upload and management
- Location services integration

### Bug Fixes
- Various UI/UX improvements
- Performance optimizations
- Security enhancements

---

## Version Numbering

- **Version Format**: `major.minor.patch+build`
- **Version Name**: User-facing version (e.g., "3.0.10")
- **Version Code**: Internal build number for app stores (e.g., 15)

### Version History
- 3.0.13+20: Current release with Android 15 compatibility and Play Core fixes (Play Store build 20) ← **NEW**
- 3.0.10+15: Previous release with image cropping fixes (Play Store build 16)
- 3.0.10+14: Previous release with image cropping fixes
- 3.0.9+13: Previous release
- Earlier versions: Restaurant management app development

## Release Notes for Users

### What's New in Version 3.0.13
- **Android 15 Support**: Full compatibility with the latest Android version
- **Enhanced Security**: Latest security patches and privacy improvements
- **Better Performance**: Optimized for the latest Android devices
- **Improved Stability**: Resolved compatibility issues for modern Android versions

### What's New in Version 3.0.10
- **Fixed Image Cropping**: The image cropping feature now works correctly on all devices
- **Better Performance**: Improved app responsiveness and stability
- **Enhanced Compatibility**: Better support for different screen sizes and devices

### Known Issues
- None reported in this version

### Support
For support or to report issues, please contact the development team. 