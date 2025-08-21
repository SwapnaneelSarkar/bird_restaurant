import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class BuildConfig {
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;
  
  /// Check if this is a debug build running on a physical device
  static bool get isDebugOnDevice => isDebug && Platform.isAndroid;
  
  /// Check if this is a release build (from Play Store or signed APK)
  static bool get isReleaseBuild => isRelease;
  
  /// Determine if we should force reCAPTCHA flow
  /// This helps avoid Play Integrity API issues in debug builds
  static bool get shouldForceRecaptcha {
    // Force reCAPTCHA for debug builds to avoid Play Integrity issues
    if (isDebugOnDevice) {
      return true;
    }
    
    // For release builds, let Firebase decide
    return false;
  }
  
  /// Determine if app verification should be disabled for testing
  static bool get shouldDisableAppVerification {
    // Only disable for test phone numbers in debug mode
    return isDebug;
  }
} 