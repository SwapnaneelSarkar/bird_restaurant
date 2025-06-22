// lib/services/notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // Initialize local notifications for background messages
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  // For background messages, use custom sound from raw resources
  // This will work even when the app is in the background
  const androidDetails = AndroidNotificationDetails(
    'bird_partner_channel',
    'Bird Partner Notifications',
    channelDescription: 'Notifications for Bird Partner app',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification_ringtone'),
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'notification_ringtone.ogg',
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    message.hashCode,
    message.notification?.title ?? 'Bird Partner',
    message.notification?.body ?? 'You have a new notification',
    notificationDetails,
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _fcmToken;
  bool _isInitialized = false;
  bool _isPlayingRingtone = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔔 NotificationService already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Set up foreground message handlers
      _setupForegroundHandlers();

      // Generate and get FCM token
      await _generateFCMToken();

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    debugPrint('🔔 Local notifications initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

    // Request local notification permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Set up foreground message handlers
  void _setupForegroundHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground message received: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Show local notification when app is in foreground
      _showLocalNotification(message);
    });

    // Handle notification tap when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification tapped (app opened from background): ${message.messageId}');
      _handleNotificationData(message.data);
    });

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  /// Generate and cache FCM token
  Future<String?> _generateFCMToken() async {
    try {
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token generated: $_fcmToken');

        
        // Listen to token refresh
        _messaging.onTokenRefresh.listen((String newToken) {
          debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
          _fcmToken = newToken;
          // Re-register with server when token refreshes
          _registerTokenWithServer(newToken);
        });
        
        return _fcmToken;
      } else {
        debugPrint('❌ Failed to generate FCM token');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error generating FCM token: $e');
      return null;
    }
  }

  /// Check if app was opened from a terminated state via notification
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from terminated state via notification: ${initialMessage.messageId}');
        _handleNotificationData(initialMessage.data);
      }
    } catch (e) {
      debugPrint('❌ Error checking initial message: $e');
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Use system notification sound (brief)
      // Custom ringtone will be handled by AudioPlayer for extended playback
      final notificationDetails = _createNotificationDetails();

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Bird Partner',
        message.notification?.body ?? 'You have a new notification',
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      // Play custom ringtone for incoming notifications (extended playback)
      await _playCustomRingtone();
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Handle notification data and navigate accordingly
  void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('🔔 Handling notification data: $data');
    
    // Add your navigation logic here based on notification data
    // For example:
    // - Navigate to specific screens
    // - Update app state
    // - Show dialogs
    
    final type = data['type'];
    final orderId = data['order_id'];
    final messageId = data['message_id'];
    
    switch (type) {
      case 'new_order':
        debugPrint('📦 New order notification: $orderId');
        // Navigate to orders screen
        break;
      case 'new_message':
        debugPrint('💬 New message notification: $messageId');
        // Navigate to chat screen
        break;
      case 'order_update':
        debugPrint('🔄 Order update notification: $orderId');
        // Navigate to specific order details
        break;
      default:
        debugPrint('🔔 Unknown notification type: $type');
        // Default action
        break;
    }
  }

  /// Register FCM token with server
  Future<bool> registerTokenWithServer() async {
    if (_fcmToken == null) {
      debugPrint('❌ No FCM token available to register');
      return false;
    }

    return await _registerTokenWithServer(_fcmToken!);
  }

  /// Internal method to register token with server
  Future<bool> _registerTokenWithServer(String token) async {
    try {
      // Get user ID
      final userId = await TokenService.getUserId();
      if (userId == null) {
        debugPrint('❌ No user ID available for token registration');
        return false;
      }

      // Get auth token
      final authToken = await TokenService.getToken();
      if (authToken == null) {
        debugPrint('❌ No auth token available for API call');
        return false;
      }

      debugPrint('🔔 Registering FCM token with server...');
      debugPrint('Partner ID: $userId');
      debugPrint('FCM Token: $token');


      final url = Uri.parse('${ApiConstants.baseUrl}/user/register-device-token');
      
      final body = jsonEncode({
        "partnerId": userId.toString(),
        "token": token,
      });

      debugPrint('Request URL: $url');
      debugPrint('Request Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final status = responseData['status'];
        final message = responseData['message'];

        if (status == true) {
          debugPrint('✅ FCM token registered successfully: $message');
          return true;
        } else {
          debugPrint('❌ FCM token registration failed: $message');
          return false;
        }
      } else {
        debugPrint('❌ FCM token registration failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Get current FCM token (generate if not available)
  Future<String?> getCurrentToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }

    return await _generateFCMToken();
  }

  /// Force refresh FCM token
  Future<String?> refreshToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      return await _generateFCMToken();
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      // Stop any playing audio
      await _stopCustomRingtone();
      await _audioPlayer.dispose();
      
      // Cancel any ongoing operations
      _isInitialized = false;
      debugPrint('🔔 NotificationService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing NotificationService: $e');
    }
  }

  /// Play custom ringtone for incoming notifications
  Future<void> _playCustomRingtone({int durationSeconds = 15}) async {
    if (_isPlayingRingtone) {
      debugPrint('🔔 Ringtone already playing, skipping...');
      return;
    }

    try {
      _isPlayingRingtone = true;
      debugPrint('🔔 Playing custom ringtone for $durationSeconds seconds...');

      // Try to set audio source to the custom ringtone file
      try {
        await _audioPlayer.setSource(AssetSource('audio/notification_ringtone.ogg'));
        debugPrint('✅ Custom audio file loaded successfully');
      } catch (audioError) {
        debugPrint('⚠️ Custom audio file not available or invalid: $audioError');
        debugPrint('🔔 Using system notification sound only (no extended ringtone)');
        _isPlayingRingtone = false;
        return; // Exit early, system notification sound will still play
      }
      
      // Set volume and loop settings
      await _audioPlayer.setVolume(1.0);
      debugPrint('🔊 Volume set to maximum (1.0)');
      
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      debugPrint('🔄 Loop mode enabled');
      
      // Play the ringtone
      await _audioPlayer.resume();
      debugPrint('▶️ Audio playback started');
      
      // Add state listener to monitor playback
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('🎵 Audio player state changed: $state');
      });
      
      _audioPlayer.onPlayerComplete.listen((event) {
        debugPrint('✅ Audio playback completed');
      });
      
      // Stop after specified duration
      Future.delayed(Duration(seconds: durationSeconds), () {
        debugPrint('⏰ Duration reached, stopping ringtone...');
        _stopCustomRingtone();
      });

      debugPrint('✅ Custom ringtone started playing');
    } catch (e) {
      debugPrint('❌ Error playing custom ringtone: $e');
      debugPrint('🔔 Falling back to system notification sound only');
      _isPlayingRingtone = false;
    }
  }

  /// Play custom ringtone with custom duration (public method)
  Future<void> playCustomRingtone({int durationSeconds = 15}) async {
    await _playCustomRingtone(durationSeconds: durationSeconds);
  }

  /// Stop custom ringtone
  Future<void> _stopCustomRingtone() async {
    if (!_isPlayingRingtone) {
      return;
    }

    try {
      await _audioPlayer.stop();
      _isPlayingRingtone = false;
      debugPrint('🔔 Custom ringtone stopped');
    } catch (e) {
      debugPrint('❌ Error stopping custom ringtone: $e');
      _isPlayingRingtone = false;
    }
  }

  /// Check if ringtone is currently playing
  bool get isPlayingRingtone => _isPlayingRingtone;

  /// Manually stop ringtone (public method)
  Future<void> stopRingtone() async {
    await _stopCustomRingtone();
  }

  /// Test notification method (public)
  Future<void> testNotification() async {
    try {
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Notification',
          body: 'This is a test notification with custom ringtone',
        ),
        data: {'type': 'test'},
      );
      
      await _showLocalNotification(testMessage);
    } catch (e) {
      debugPrint('❌ Error testing notification: $e');
    }
  }

  /// Test audio playback with different settings (public)
  Future<void> testAudioPlayback() async {
    try {
      debugPrint('🧪 Testing audio playback...');
      
      // Test with maximum volume
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setSource(AssetSource('audio/notification_ringtone.ogg'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      debugPrint('🔊 Testing with maximum volume (1.0)');
      await _audioPlayer.resume();
      
      // Stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        await _audioPlayer.stop();
        debugPrint('🛑 Test audio stopped');
      });
      
    } catch (e) {
      debugPrint('❌ Error testing audio playback: $e');
    }
  }

  /// Create notification details with optional custom sound
  NotificationDetails _createNotificationDetails({bool useCustomSound = false}) {
    // Use custom sound from raw resources for both foreground and background
    // AudioPlayer will handle extended playback for foreground notifications
    const androidDetails = AndroidNotificationDetails(
      'bird_partner_channel',
      'Bird Partner Notifications',
      channelDescription: 'Notifications for Bird Partner app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_ringtone.ogg',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }
}