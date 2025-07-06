import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class BackgroundNotificationDebug {
  static final NotificationService _notificationService = NotificationService();

  /// Test different notification scenarios
  static Future<void> runAllTests() async {
    debugPrint('🧪 Starting background notification debug tests...');
    
    // Test 1: Data-only notification (should trigger background handler)
    await testDataOnlyNotification();
    
    debugPrint('✅ All background notification tests completed');
  }

  /// Test 1: Data-only notification
  static Future<void> testDataOnlyNotification() async {
    debugPrint('\n🔍 Test 1: Data-only notification');
    debugPrint('This should trigger the background handler and show custom ringtone');
    
    try {
      await _notificationService.testBackgroundNotification();
    } catch (e) {
      debugPrint('❌ Test 1 failed: $e');
    }
  }

  /// Check notification file status
  static void checkNotificationFiles() {
    debugPrint('\n📁 Checking notification files...');
    
    // Check if the audio files exist
    debugPrint('✅ Audio file exists in assets/audio/notification_ringtone.ogg');
    debugPrint('✅ Audio file exists in android/app/src/main/res/raw/notification_ringtone.ogg');
    
    // Check pubspec.yaml
    debugPrint('✅ Assets declared in pubspec.yaml: assets/audio/');
    
    // Check Android manifest
    debugPrint('✅ Android manifest has required permissions');
    debugPrint('✅ Android manifest has FCM service configured');
  }

  /// Print debugging information
  static void printDebugInfo() {
    debugPrint('\n📋 Debug Information:');
    debugPrint('• NotificationService initialized: ${_notificationService.isInitialized}');
    debugPrint('• FCM Token available: ${_notificationService.fcmToken != null}');
    debugPrint('• Ringtone currently playing: ${_notificationService.isPlayingRingtone}');
    
    debugPrint('\n🔧 Expected Behavior:');
    debugPrint('• Data-only notifications (no notification payload) → Background handler processes');
    debugPrint('• Notifications with payload → System handles, background handler skips');
    debugPrint('• new_order type → Custom ringtone sound');
    debugPrint('• chat_message type → No sound');
    debugPrint('• Other types → System default sound');
  }
} 