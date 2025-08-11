// lib/services/notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'token_service.dart';

import '../presentation/resources/router/router.dart';

import '../main.dart'; // Import to access the global navigator key

// Top-level function to handle background notification actions
@pragma('vm:entry-point')
void _handleBackgroundNotificationResponse(NotificationResponse response) async {
  debugPrint('🔔 Background notification response received: ${response.actionId}');
  debugPrint('🔔 Background notification payload: ${response.payload}');
  debugPrint('🔔 Background notification response type: ${response.notificationResponseType}');
  debugPrint('🔔 Background notification action ID: ${response.actionId}');
  debugPrint('🔔 Background notification notification ID: ${response.notificationResponseType}');

  try {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      debugPrint('🔔 Background notification decoded data: $data');
      
      if (response.actionId != null) {
        debugPrint('🔔 Background notification action ID: ${response.actionId}');
        debugPrint('🔔 Processing action: ${response.actionId}');
        await _handleBackgroundNotificationAction(response.actionId!, data);
      } else {
        debugPrint('🔔 Background notification body tap detected');
        // Handle notification body tap in background
        await _handleBackgroundNotificationBodyTap(data);
      }
    } else {
      debugPrint('❌ Background notification response has no payload');
    }
  } catch (e) {
    debugPrint('❌ Error handling background notification response: $e');
    debugPrint('❌ Error stack trace: ${StackTrace.current}');
  }
}

// Top-level function to handle background notification actions
@pragma('vm:entry-point')
Future<void> _handleBackgroundNotificationAction(String actionId, Map<String, dynamic> data) async {
  debugPrint('🔔 Processing background action: $actionId');
  debugPrint('🔔 Background action data: $data');
  debugPrint('🔔 Background action order_id: ${data['order_id']}');
  debugPrint('🔔 Background action related_id: ${data['related_id']}');
  
  final orderId = data['order_id'] ?? data['related_id'];
  debugPrint('🔔 Background action final order ID: $orderId');
  
  if (orderId == null || orderId.isEmpty) {
    debugPrint('❌ No order ID found in background notification data');
    debugPrint('❌ Available data keys: ${data.keys.toList()}');
    return;
  }

  try {
    // Initialize necessary services for background operation
    await _initializeBackgroundServices();
    
    String newStatus;
    String actionName;
    
    switch (actionId) {
      case 'accept_order':
        newStatus = 'CONFIRMED';
        actionName = 'accepted';
        break;
      case 'reject_order':
        newStatus = 'CANCELLED';
        actionName = 'rejected';
        break;
      default:
        debugPrint('❌ Unknown background action ID: $actionId');
        return;
    }

    debugPrint('🔔 Processing background $actionName action for order: $orderId');
    
    // Call the API directly using HTTP instead of service classes
    final success = await _updateOrderStatusDirectly(orderId, newStatus);

    if (success) {
      debugPrint('✅ Order $actionName successfully via background action');
      final statusMessage = actionId == 'accept_order' ? 'Order accepted and confirmed!' : 'Order rejected and cancelled!';
      await _showBackgroundFeedbackNotification(statusMessage, isSuccess: true);
      
      // Store the action result for when app opens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_action', jsonEncode({
        'orderId': orderId,
        'action': actionName,
        'isSuccess': true,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      debugPrint('🔔 Stored notification action result for app opening');
    } else {
      throw Exception('API returned false');
    }
  } catch (e) {
    debugPrint('❌ Error processing background action: $e');
    await _showBackgroundFeedbackNotification('Failed to process order action', isSuccess: false);
    
    // Store the failed action result
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_action', jsonEncode({
        'orderId': orderId,
        'action': actionId == 'accept_order' ? 'accepted' : 'rejected',
        'isSuccess': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      }));
      debugPrint('🔔 Stored failed notification action result for app opening');
    } catch (storeError) {
      debugPrint('❌ Failed to store action result: $storeError');
    }
  }
}

// Top-level function to initialize services for background operations
@pragma('vm:entry-point')
Future<void> _initializeBackgroundServices() async {
  // Initialize Firebase if not already done
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase might already be initialized
    debugPrint('Firebase initialization: $e');
  }
}

// Top-level function to handle background notification body tap
@pragma('vm:entry-point')
Future<void> _handleBackgroundNotificationBodyTap(Map<String, dynamic> data) async {
  debugPrint('🔔 Handling background notification body tap: $data');
  
  final type = data['type'];
  final orderId = data['order_id'] ?? data['related_id'];
  
  debugPrint('🔔 Background notification body tap - Type: $type, Order ID: $orderId');
  
  if (type == 'new_order' && orderId != null && orderId.isNotEmpty) {
    debugPrint('🔔 Background new order notification body tap - will open app to OrderAction page');
    // The app will be opened and the foreground handler will take care of navigation
  } else {
    debugPrint('🔔 Background notification body tap - unknown type or missing order ID');
    debugPrint('🔔 Available data keys: ${data.keys.toList()}');
  }
}

// Top-level function to update order status directly via HTTP
@pragma('vm:entry-point')
Future<bool> _updateOrderStatusDirectly(String orderId, String newStatus) async {
  try {
    // Get stored token from shared preferences using TokenService keys
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final partnerId = prefs.getString('user_id');
    
    if (token == null || partnerId == null) {
      debugPrint('❌ No auth token or partner ID found in shared preferences');
      debugPrint('❌ Token: ${token != null ? "Found" : "Missing"}');
      debugPrint('❌ Partner ID: ${partnerId != null ? "Found" : "Missing"}');
      return false;
    }

    // Make direct HTTP call to update order status
    final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/$orderId/status?partner_id=$partnerId');
    final requestBody = {
      'status': newStatus.toUpperCase(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    debugPrint('🔔 Background API URL: $url');
    debugPrint('🔔 Background API request body: $requestBody');
    debugPrint('🔔 Background API token: ${token.substring(0, 20)}...');
    debugPrint('🔔 Background API partner ID: $partnerId');
    
    // Add timeout to the request
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));

    debugPrint('🔔 Background API response: ${response.statusCode}');
    debugPrint('🔔 Background API response body: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        final success = responseData['status'] == 'SUCCESS';
        debugPrint('🔔 Background API success: $success');
        return success;
      } catch (parseError) {
        debugPrint('❌ Background API response parsing error: $parseError');
        // If we can't parse the response but got 200, assume success
        return true;
      }
    } else if (response.statusCode == 201) {
      debugPrint('🔔 Background API success (201): Created');
      return true;
    } else {
      debugPrint('❌ Background API error: ${response.statusCode}');
      debugPrint('❌ Background API error body: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('❌ Background API exception: $e');
    debugPrint('❌ Background API exception type: ${e.runtimeType}');
    return false;
  }
}

// Top-level function to show feedback notifications
@pragma('vm:entry-point')
Future<void> _showBackgroundFeedbackNotification(String message, {required bool isSuccess}) async {
  try {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    
    // Initialize local notifications for background
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await localNotifications.initialize(initSettings);

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      isSuccess ? 'Success' : 'Error',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bird_partner_feedback_channel',
          'Action Feedback',
          channelDescription: 'Feedback notifications for notification actions',
          importance: Importance.low,
          priority: Priority.low,
          showWhen: false,
          autoCancel: true,
          timeoutAfter: 3000,
          icon: '@mipmap/ic_launcher',
          color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error showing background feedback notification: $e');
  }
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
    // Always handle the notification ourselves to control the channel and sound
  // This ensures we use the correct channel for each notification type
  
  // Initialize local notifications for background messages
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    
    // Initialize the plugin for background messages
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await localNotifications.initialize(initSettings);
    
    // Create notification channels for Android
    const androidDefaultChannel = AndroidNotificationChannel(
      'bird_partner_channel',
      'Bird Partner Notifications',
      description: 'Default notifications for Bird Partner app',
      importance: Importance.high,
      playSound: true,
      // DO NOT set sound property here! This uses system default sound
    );

    const androidOrderChannel = AndroidNotificationChannel(
      'bird_partner_order_channel',
      'Bird Partner Order Notifications',
      description: 'Order notifications with custom ringtone',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
    );

    const androidChatChannel = AndroidNotificationChannel(
      'bird_partner_chat_channel',
      'Bird Partner Chat Notifications',
      description: 'Chat notifications for Bird Partner app',
      importance: Importance.high,
      playSound: false,
    );

    const androidFeedbackChannel = AndroidNotificationChannel(
      'bird_partner_feedback_channel',
      'Action Feedback',
      description: 'Feedback notifications for notification actions',
      importance: Importance.low,
      playSound: false,
    );
    
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidDefaultChannel);
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidOrderChannel);
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChatChannel);
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidFeedbackChannel);
    
    // Get notification type from data
    final notificationType = message.data['type'];
    debugPrint('🔔 Background notification type: $notificationType');
    
    NotificationDetails notificationDetails;
    if (notificationType == 'new_order') {
      // Create action buttons for new order notifications
      const acceptAction = AndroidNotificationAction(
        'accept_order',
        'Accept',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
        contextual: true,
        showsUserInterface: true,
        cancelNotification: false,
      );
      const rejectAction = AndroidNotificationAction(
        'reject_order', 
        'Reject',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
        contextual: true,
        showsUserInterface: true,
        cancelNotification: false,
      );

      // Use custom sound for new order notifications with action buttons
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_order_channel',
        'Bird Partner Order Notifications',
        channelDescription: 'Order notifications with custom ringtone',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_ringtone'),
        actions: [acceptAction, rejectAction],
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_ringtone.ogg',
      );
      notificationDetails = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    } else if (notificationType == 'chat_message') {
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_chat_channel',
        'Bird Partner Chat Notifications',
        channelDescription: 'Chat notifications for Bird Partner app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      notificationDetails = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    } else {
      // Use system default sound for other notifications
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_channel',
        'Bird Partner Notifications',
        channelDescription: 'Default notifications for Bird Partner app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      notificationDetails = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    }

    // Use data to create notification title and body
    final title = message.notification?.title ?? message.data['title'] ?? 'Bird Partner';
    final body = message.notification?.body ?? message.data['body'] ?? 'You have a new notification';

    debugPrint('🔔 Notification title: $title');
    debugPrint('🔔 Notification body: $body');
    debugPrint('🔔 Notification channel: '
      '${notificationType == 'new_order' ? 'bird_partner_order_channel' : (notificationType == 'chat_message' ? 'bird_partner_chat_channel' : 'bird_partner_channel')}');

    // Generate unique notification ID to prevent duplicates
    final notificationId = message.messageId != null 
        ? int.tryParse(message.messageId!) ?? message.hashCode
        : message.hashCode;

    final payload = jsonEncode(message.data);
    debugPrint('🔔 Background notification payload: $payload');
    
    await localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    debugPrint('✅ Background notification shown successfully');
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
  
  // Keep track of processed notifications to prevent duplicates
  final Set<String> _processedNotifications = <String>{};

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
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      const androidOrderChannel = AndroidNotificationChannel(
        'bird_partner_order_channel',
        'Bird Partner Order Notifications',
        description: 'Order notifications with custom ringtone',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_ringtone'),
      );
      
      const androidChatChannel = AndroidNotificationChannel(
        'bird_partner_chat_channel',
        'Bird Partner Chat Notifications',
        description: 'Chat notifications for Bird Partner app',
        importance: Importance.high,
        playSound: false,
      );
      
      const androidDefaultChannel = AndroidNotificationChannel(
        'bird_partner_default_channel',
        'Bird Partner Default Notifications',
        description: 'Default notifications for Bird Partner app',
        importance: Importance.high,
        playSound: true,
      );

      const androidFeedbackChannel = AndroidNotificationChannel(
        'bird_partner_feedback_channel',
        'Action Feedback',
        description: 'Feedback notifications for notification actions',
        importance: Importance.low,
        playSound: false,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidOrderChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChatChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidDefaultChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidFeedbackChannel);
    }

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

      // Check if we've already processed this notification
      final messageId = message.messageId ?? 
                       '${message.data['order_id'] ?? message.data['related_id'] ?? ''}_${message.data['type'] ?? ''}_${message.hashCode}';
      
      // Also check for duplicate based on order ID and type
      final orderId = message.data['order_id'] ?? message.data['related_id'];
      final type = message.data['type'];
      final duplicateKey = '${orderId}_${type}';
      
      if (_processedNotifications.contains(messageId) || _processedNotifications.contains(duplicateKey)) {
        debugPrint('🔔 Duplicate notification detected, skipping: $messageId');
        debugPrint('🔔 Duplicate key: $duplicateKey');
        return;
      }

      // Add to processed notifications
      _processedNotifications.add(messageId);
      _processedNotifications.add(duplicateKey);

      // Clean up old processed notifications (keep only last 100)
      if (_processedNotifications.length > 100) {
        final oldIds = _processedNotifications.take(_processedNotifications.length - 100);
        _processedNotifications.removeAll(oldIds);
      }

      // Show local notification when app is in foreground
      // Only show custom notification for new_order type, skip others to prevent duplicates
      if (message.data['type'] == 'new_order') {
        debugPrint('🔔 New order notification - showing custom notification with actions');
        _showLocalNotification(message);
      } else {
        debugPrint('🔔 Non-new_order notification - skipping to prevent duplicates');
        // Still handle the data for navigation purposes
        _handleNotificationData(message.data);
      }
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
      // Get notification type from data
      final notificationType = message.data['type'];
      debugPrint('🔔 Notification type: $notificationType');

      // Create notification details based on type
      final notificationDetails = _createNotificationDetails(notificationType: notificationType);

      // Use notification payload if available, otherwise use data
      final title = message.notification?.title ?? message.data['title'] ?? 'Bird Partner';
      final body = message.notification?.body ?? message.data['body'] ?? 'You have a new notification';

      // Generate unique notification ID to prevent duplicates
      final notificationId = message.messageId != null 
          ? int.tryParse(message.messageId!) ?? message.hashCode
          : message.hashCode;

      final payload = jsonEncode(message.data);
      debugPrint('🔔 Foreground notification payload: $payload');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // Play custom ringtone only for 'new_order' type notifications
      if (notificationType == 'new_order') {
        debugPrint('🔔 Playing custom ringtone for new order notification');
        await _playCustomRingtone();
      } else {
        debugPrint('🔔 Skipping custom ringtone for notification type: $notificationType');
      }
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) async {
    try {
      debugPrint('🔔 FOREGROUND Notification response received: ${response.actionId}');
      debugPrint('🔔 FOREGROUND Notification payload: ${response.payload}');
      debugPrint('🔔 FOREGROUND Notification response type: ${response.notificationResponseType}');

      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        debugPrint('🔔 FOREGROUND Decoded notification data: $data');
        
        // Handle action button responses
        if (response.actionId != null) {
          debugPrint('🔔 FOREGROUND Processing action button: ${response.actionId}');
          // Process action in foreground
          await _handleForegroundNotificationAction(response.actionId!, data);
        } else {
          debugPrint('🔔 FOREGROUND Processing notification body tap');
          // Handle regular notification tap
          _handleNotificationData(data);
        }
      } else {
        debugPrint('❌ FOREGROUND No payload found in notification response');
      }
    } catch (e) {
      debugPrint('❌ FOREGROUND Error handling notification tap: $e');
      debugPrint('❌ FOREGROUND Error stack trace: ${StackTrace.current}');
    }
  }

  /// Handle foreground notification actions
  Future<void> _handleForegroundNotificationAction(String actionId, Map<String, dynamic> data) async {
    try {
      debugPrint('🔔 FOREGROUND Processing action: $actionId');
      debugPrint('🔔 FOREGROUND Action data: $data');
      
      final orderId = data['order_id'] ?? data['related_id'];
      debugPrint('🔔 FOREGROUND Action order ID: $orderId');
      
      if (orderId == null || orderId.isEmpty) {
        debugPrint('❌ FOREGROUND No order ID found in action data');
        return;
      }
      
      String newStatus;
      String actionName;
      
      switch (actionId) {
        case 'accept_order':
          newStatus = 'CONFIRMED';
          actionName = 'accepted';
          break;
        case 'reject_order':
          newStatus = 'CANCELLED';
          actionName = 'rejected';
          break;
        default:
          debugPrint('❌ FOREGROUND Unknown action ID: $actionId');
          return;
      }
      
      debugPrint('🔔 FOREGROUND Processing $actionName action for order: $orderId');
      
      // Call the API directly
      final success = await _updateOrderStatusDirectly(orderId, newStatus);
      
      if (success) {
        debugPrint('✅ FOREGROUND Order $actionName successfully');
        
        // Store the action result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_notification_action', jsonEncode({
          'orderId': orderId,
          'action': actionName,
          'isSuccess': true,
          'timestamp': DateTime.now().toIso8601String(),
        }));
        
        // Navigate to result page
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          Routes.orderActionResult,
          (route) => false,
          arguments: {
            'orderId': orderId,
            'action': actionName,
            'isSuccess': true,
          },
        );
        
        debugPrint('✅ FOREGROUND Navigated to result page');
      } else {
        debugPrint('❌ FOREGROUND Failed to $actionName order');
        
        // Store failed action result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_notification_action', jsonEncode({
          'orderId': orderId,
          'action': actionName,
          'isSuccess': false,
          'error': 'API call failed',
          'timestamp': DateTime.now().toIso8601String(),
        }));
        
        // Navigate to result page with error
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          Routes.orderActionResult,
          (route) => false,
          arguments: {
            'orderId': orderId,
            'action': actionName,
            'isSuccess': false,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ FOREGROUND Error processing action: $e');
    }
  }

  /// Handle notification data and navigate accordingly
  void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('🔔 Handling notification data: $data');
    
    final type = data['type'];
    final orderId = data['order_id'] ?? data['related_id']; // Support both order_id and related_id
    final relatedId = data['related_id']; // For chat messages
    
    debugPrint('🔔 Notification details - Type: $type, Order ID: $orderId, Related ID: $relatedId');
    
    switch (type) {
      case 'new_order':
        debugPrint('📦 New order notification: $orderId');
        // Navigate to order action screen for accept/reject
        _navigateToOrderAction(orderId);
        break;
      case 'chat_message':
        debugPrint('💬 Chat message notification: Related ID: $relatedId');
        // Navigate to chat screen with the related_id (which is the order/room ID)
        if (relatedId != null && relatedId.isNotEmpty) {
          _navigateToChat(relatedId);
        } else {
          debugPrint('❌ No related_id found for chat message notification');
          _navigateToChatList();
        }
        break;
      case 'order_update':
        debugPrint('🔄 Order update notification: $orderId');
        // Navigate to specific order details
        _navigateToOrderDetails(orderId);
        break;
      default:
        debugPrint('🔔 Unknown notification type: $type');
        // Default action - navigate to home
        _navigateToHome();
        break;
    }
  }

  /// Navigate to chat screen with specific order ID
  void _navigateToChat(String orderId) {
    debugPrint('🔔 Navigating to chat screen with order ID: $orderId');
    try {
      // Use the global navigator key to navigate and clear the stack
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          Routes.chat,
          (route) => false, // Remove all previous routes
          arguments: orderId,
        );
        debugPrint('✅ Successfully navigated to chat screen (stack cleared)');
      } else {
        debugPrint('❌ No navigator state available for navigation');
        _navigateToChatList(); // Fallback to chat list
      }
    } catch (e) {
      debugPrint('❌ Error navigating to chat screen: $e');
      _navigateToChatList(); // Fallback to chat list
    }
  }

  /// Navigate to chat list screen
  void _navigateToChatList() {
    debugPrint('🔔 Navigating to chat list screen');
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          Routes.chatList,
          (route) => false, // Remove all previous routes
        );
        debugPrint('✅ Successfully navigated to chat list screen (stack cleared)');
      } else {
        debugPrint('❌ No navigator state available for navigation');
        _navigateToHome(); // Fallback to home
      }
    } catch (e) {
      debugPrint('❌ Error navigating to chat list screen: $e');
      _navigateToHome(); // Fallback to home
    }
  }

  /// Navigate to orders screen
  void _navigateToOrders() {
    debugPrint('🔔 Navigating to orders screen');
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          Routes.orders,
          (route) => false, // Remove all previous routes
        );
        debugPrint('✅ Successfully navigated to orders screen (stack cleared)');
      } else {
        debugPrint('❌ No navigator state available for navigation');
        _navigateToHome(); // Fallback to home
      }
    } catch (e) {
      debugPrint('❌ Error navigating to orders screen: $e');
      _navigateToHome(); // Fallback to home
    }
  }

  /// Navigate to order details screen
  void _navigateToOrderDetails(String? orderId) {
    debugPrint('🔔 Navigating to order details screen: $orderId');
    if (orderId == null || orderId.isEmpty) {
      debugPrint('❌ No order ID provided for order details navigation');
      _navigateToOrders(); // Fallback to orders list
      return;
    }
    
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          Routes.orders,
          (route) => false, // Remove all previous routes
          arguments: orderId,
        );
        debugPrint('✅ Successfully navigated to order details screen (stack cleared)');
      } else {
        debugPrint('❌ No navigator state available for navigation');
        _navigateToOrders(); // Fallback to orders list
      }
    } catch (e) {
      debugPrint('❌ Error navigating to order details screen: $e');
      _navigateToOrders(); // Fallback to orders list
    }
  }

  /// Navigate to home screen
  void _navigateToHome() {
    debugPrint('🔔 Navigating to home screen');
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          Routes.homePage,
          (route) => false, // Remove all previous routes
        );
        debugPrint('✅ Successfully navigated to home screen (stack cleared)');
      } else {
        debugPrint('❌ No navigator state available for navigation');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to home screen: $e');
    }
  }

  /// Navigate to order action screen for accept/reject
  void _navigateToOrderAction(String? orderId) {
    debugPrint('🔔 Navigating to order action screen: $orderId');
    debugPrint('🔔 Navigator key state: ${navigatorKey.currentState != null ? "Available" : "Not available"}');
    debugPrint('🔔 Route: ${Routes.orderAction}');
    
    if (orderId == null || orderId.isEmpty) {
      debugPrint('❌ No order ID provided for order action navigation');
      _navigateToOrders(); // Fallback to orders list
      return;
    }
    
    try {
      if (navigatorKey.currentState != null) {
        // Try multiple navigation approaches
        try {
          // First, try to push the route
          navigatorKey.currentState!.pushNamed(
            Routes.orderAction,
            arguments: orderId,
          );
          debugPrint('✅ Successfully navigated to order action screen using pushNamed');
        } catch (pushError) {
          debugPrint('❌ Push navigation failed: $pushError');
          
          // Fallback: try to push and remove until
          try {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              Routes.orderAction,
              (route) => route.isFirst,
              arguments: orderId,
            );
            debugPrint('✅ Successfully navigated to order action screen using pushNamedAndRemoveUntil');
          } catch (pushRemoveError) {
            debugPrint('❌ Push and remove navigation failed: $pushRemoveError');
            
            // Final fallback: navigate to orders
            _navigateToOrders();
          }
        }
      } else {
        debugPrint('❌ No navigator state available for navigation');
        _navigateToOrders(); // Fallback to orders list
      }
    } catch (e) {
      debugPrint('❌ Error navigating to order action screen: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
      _navigateToOrders(); // Fallback to orders list
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
      
      // Clear processed notifications
      _processedNotifications.clear();
      
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
        messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _showLocalNotification(testMessage);
    } catch (e) {
      debugPrint('❌ Error testing notification: $e');
    }
  }

  /// Test new order notification (should play custom ringtone)
  Future<void> testNewOrderNotification() async {
    try {
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'New Order Received',
          body: 'You have received a new order #12345',
        ),
        data: {'type': 'new_order', 'order_id': 'test_order_12345'},
        messageId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _showLocalNotification(testMessage);
    } catch (e) {
      debugPrint('❌ Error testing new order notification: $e');
    }
  }

  /// Test actionable new order notification with Accept/Reject buttons
  Future<void> testActionableNewOrderNotification() async {
    try {
      debugPrint('🧪 Testing actionable new order notification...');
      debugPrint('🔔 This notification should have Accept and Reject buttons');
      debugPrint('🔔 Buttons work without opening the app');
      debugPrint('🔔 Tapping notification body opens Order Action page');
      
      // First, validate that auth data is available
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      debugPrint('🔍 Auth validation:');
      debugPrint('   • Token: ${token != null ? "✅ Available" : "❌ Missing"}');
      debugPrint('   • Partner ID: ${partnerId != null ? "✅ Available ($partnerId)" : "❌ Missing"}');
      
      if (token == null || partnerId == null) {
        debugPrint('⚠️  WARNING: Missing auth data! Background actions may fail.');
        debugPrint('⚠️  Please ensure user is logged in before testing.');
      }
      
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'New Order Received',
          body: 'Order #TEST001 - ₹299.00\nCustomer: Test Customer\nTap for details or use action buttons',
        ),
        data: {
          'type': 'new_order', 
          'order_id': 'TEST001',
          'title': 'New Order Received',
          'body': 'Order #TEST001 - ₹299.00\nCustomer: Test Customer\nTap for details or use action buttons'
        },
        messageId: 'test_actionable_order_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _showLocalNotification(testMessage);
      debugPrint('✅ Actionable notification sent!');
      debugPrint('📱 Check notification tray for Accept/Reject buttons');
      debugPrint('🧪 Test scenarios:');
      debugPrint('   • Accept button → Should call API and show success feedback');
      debugPrint('   • Reject button → Should call API and show success feedback');
      debugPrint('   • Notification tap → Should open Order Action page');
      debugPrint('🔧 Implementation details:');
      debugPrint('   • Background handler: ✅ Implemented');
      debugPrint('   • Direct API calls: ✅ Implemented');
      debugPrint('   • Feedback notifications: ✅ Implemented');
      debugPrint('   • All app states supported: ✅ Foreground/Background/Terminated');
    } catch (e) {
      debugPrint('❌ Error testing actionable new order notification: $e');
    }
  }

  /// Test navigation to order action page
  Future<void> testOrderActionNavigation() async {
    try {
      debugPrint('🧪 Testing order action navigation...');
      
      // Test navigation directly
      _navigateToOrderAction('TEST_ORDER_123');
      
      debugPrint('✅ Navigation test completed!');
      debugPrint('📱 Check if Order Action page opened');
    } catch (e) {
      debugPrint('❌ Error testing order action navigation: $e');
    }
  }

  /// Test API status update
  Future<void> testApiStatusUpdate() async {
    try {
      debugPrint('🧪 Testing API status update...');
      
      // Test API call directly
      final success = await _updateOrderStatusDirectly('TEST_ORDER_123', 'PREPARING');
      
      debugPrint('🔔 API test result: $success');
      debugPrint('✅ API test completed!');
    } catch (e) {
      debugPrint('❌ Error testing API status update: $e');
    }
  }

  /// Test notification service comprehensively
  Future<void> testNotificationService() async {
    try {
      debugPrint('🧪 Starting comprehensive notification service test...');
      
      // Test 1: Check auth data
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      debugPrint('🔍 Auth Data Test:');
      debugPrint('   • Token: ${token != null ? "✅ Available (${token.substring(0, 20)}...)" : "❌ Missing"}');
      debugPrint('   • Partner ID: ${partnerId != null ? "✅ Available ($partnerId)" : "❌ Missing"}');
      
      // Test 2: Test navigation
      debugPrint('🔍 Navigation Test:');
      debugPrint('   • Navigator Key: ${navigatorKey.currentState != null ? "✅ Available" : "❌ Not Available"}');
      
      // Test 3: Test API call
      debugPrint('🔍 API Test:');
      final apiSuccess = await _updateOrderStatusDirectly('TEST_ORDER_123', 'PREPARING');
      debugPrint('   • API Call: ${apiSuccess ? "✅ Success" : "❌ Failed"}');
      
      // Test 4: Send test notification
      debugPrint('🔍 Notification Test:');
      await testActionableNewOrderNotification();
      
      // Test 5: Test notification channels
      debugPrint('🔍 Channel Test:');
      debugPrint('   • Order Channel: bird_partner_order_channel');
      debugPrint('   • Chat Channel: bird_partner_chat_channel');
      debugPrint('   • Default Channel: bird_partner_default_channel');
      debugPrint('   • Feedback Channel: bird_partner_feedback_channel');
      
      debugPrint('✅ Comprehensive test completed!');
    } catch (e) {
      debugPrint('❌ Error in comprehensive test: $e');
    }
  }

  /// Clear processed notifications cache
  void clearProcessedNotifications() {
    _processedNotifications.clear();
    debugPrint('🧹 Cleared processed notifications cache');
  }

  /// Get processed notifications count
  int getProcessedNotificationsCount() {
    return _processedNotifications.length;
  }

  /// Quick test method for debugging
  Future<void> quickTest() async {
    try {
      debugPrint('🚀 QUICK TEST STARTING...');
      
      // Test 1: Send a test notification with real data structure
      debugPrint('📱 Sending test notification...');
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'New Order Received!',
          body: 'You have a new order (#TEST001) from a customer.',
        ),
        data: {
          'recipient_type': 'partner',
          'related_id': 'TEST001',
          'notification_id': 'test_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'new_order'
        },
        messageId: 'quick_test_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _showLocalNotification(testMessage);
      debugPrint('✅ Test notification sent!');
      
      // Test 2: Test navigation
      debugPrint('🧭 Testing navigation...');
      _navigateToOrderAction('TEST001');
      
      // Test 3: Test API
      debugPrint('🌐 Testing API...');
      final apiResult = await _updateOrderStatusDirectly('TEST001', 'PREPARING');
      debugPrint('API Result: $apiResult');
      
      debugPrint('🎉 QUICK TEST COMPLETED!');
    } catch (e) {
      debugPrint('❌ Quick test error: $e');
    }
  }

  /// Test with actual notification data from logs
  Future<void> testRealNotification() async {
    try {
      debugPrint('🧪 Testing with real notification data...');
      
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'New Order Received!',
          body: 'You have a new order (#2508000052) from a customer.',
        ),
        data: {
          'recipient_type': 'partner',
          'related_id': '2508000052',
          'notification_id': 'af2314b41c3345bc9f125cb697dda66d',
          'type': 'new_order'
        },
        messageId: '0:1754870130365336%2069b7352069b735',
      );
      
      await _showLocalNotification(testMessage);
      debugPrint('✅ Real notification test sent!');
      debugPrint('📱 Check notification tray for Accept/Reject buttons');
      debugPrint('🔔 Test notification body tap to open OrderAction page');
    } catch (e) {
      debugPrint('❌ Error testing real notification: $e');
    }
  }

  /// Test order acceptance functionality
  Future<void> testOrderAcceptance() async {
    try {
      debugPrint('🧪 Testing order acceptance functionality...');
      
      // Test API call directly - use CONFIRMED instead of PREPARING
      final success = await _updateOrderStatusDirectly('2508000053', 'CONFIRMED');
      
      debugPrint('🔔 Order acceptance test result: $success');
      debugPrint('✅ Order acceptance test completed!');
    } catch (e) {
      debugPrint('❌ Error testing order acceptance: $e');
    }
  }

  /// Test notification actions with app launch
  Future<void> testNotificationActions() async {
    try {
      debugPrint('🧪 Testing notification actions with app launch...');
      
      // Create a test notification with actions
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Order Action',
          body: 'Testing notification action buttons',
        ),
        data: {
          'recipient_type': 'partner',
          'related_id': 'TEST_ORDER_001',
          'notification_id': 'test_notification_001',
          'type': 'new_order'
        },
        messageId: 'test_message_001',
      );
      
      // Show the notification
      await _showLocalNotification(testMessage);
      
      debugPrint('✅ Test notification with actions sent!');
      debugPrint('📱 Check notification tray for Accept/Reject buttons');
      debugPrint('🔔 Tap the buttons to test app launch behavior');
    } catch (e) {
      debugPrint('❌ Error testing notification actions: $e');
    }
  }

  /// Test duplicate notification prevention
  Future<void> testDuplicatePrevention() async {
    try {
      debugPrint('🧪 Testing duplicate notification prevention...');
      
      // Create a test notification
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Duplicate Prevention',
          body: 'Testing duplicate notification handling',
        ),
        data: {
          'recipient_type': 'partner',
          'related_id': 'TEST_DUPLICATE_001',
          'notification_id': 'test_duplicate_001',
          'type': 'new_order'
        },
        messageId: 'test_duplicate_message_001',
      );
      
      // Show the notification first time
      debugPrint('🧪 Showing notification first time...');
      await _showLocalNotification(testMessage);
      
      // Try to show the same notification again
      debugPrint('🧪 Attempting to show same notification again...');
      await _showLocalNotification(testMessage);
      
      // Try with different messageId but same order ID
      final duplicateMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Duplicate Prevention',
          body: 'Testing duplicate notification handling',
        ),
        data: {
          'recipient_type': 'partner',
          'related_id': 'TEST_DUPLICATE_001', // Same order ID
          'notification_id': 'test_duplicate_002',
          'type': 'new_order'
        },
        messageId: 'test_duplicate_message_002', // Different message ID
      );
      
      debugPrint('🧪 Attempting to show notification with same order ID but different message ID...');
      await _showLocalNotification(duplicateMessage);
      
      debugPrint('✅ Duplicate prevention test completed!');
      debugPrint('🔔 Processed notifications count: ${_processedNotifications.length}');
    } catch (e) {
      debugPrint('❌ Error testing duplicate prevention: $e');
    }
  }

  /// Test complete notification action flow
  Future<void> testCompleteActionFlow() async {
    try {
      debugPrint('🧪 Testing complete notification action flow...');
      
      // Test with a real order ID from logs
      final testOrderId = '2508000057'; // Use a real pending order
      
      debugPrint('🧪 Testing with real order ID: $testOrderId');
      
      // Test API call directly
      debugPrint('🧪 Testing direct API call...');
      final success = await _updateOrderStatusDirectly(testOrderId, 'CONFIRMED');
      
      debugPrint('🧪 Direct API call result: $success');
      
      if (success) {
        debugPrint('✅ Direct API call successful!');
        
        // Test storing action result
        debugPrint('🧪 Testing action result storage...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_notification_action', jsonEncode({
          'orderId': testOrderId,
          'action': 'accepted',
          'isSuccess': true,
          'timestamp': DateTime.now().toIso8601String(),
        }));
        
        debugPrint('✅ Action result stored successfully!');
        
        // Test retrieving stored action
        debugPrint('🧪 Testing stored action retrieval...');
        await checkForStoredNotificationAction();
        
        debugPrint('✅ Complete action flow test completed!');
      } else {
        debugPrint('❌ Direct API call failed!');
      }
    } catch (e) {
      debugPrint('❌ Error testing complete action flow: $e');
    }
  }



  /// Check for stored notification action results and navigate if found
  Future<void> checkForStoredNotificationAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAction = prefs.getString('last_notification_action');
      
      if (storedAction != null) {
        debugPrint('🔔 Found stored notification action: $storedAction');
        
        final actionData = jsonDecode(storedAction) as Map<String, dynamic>;
        final orderId = actionData['orderId'] as String? ?? '';
        final action = actionData['action'] as String? ?? '';
        final isSuccess = actionData['isSuccess'] as bool? ?? false;
        
        debugPrint('🔔 Stored action - Order ID: $orderId, Action: $action, Success: $isSuccess');
        
        // Clear the stored action
        await prefs.remove('last_notification_action');
        
        // Navigate to result page
        if (orderId.isNotEmpty && action.isNotEmpty) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            Routes.orderActionResult,
            (route) => false,
            arguments: {
              'orderId': orderId,
              'action': action,
              'isSuccess': isSuccess,
            },
          );
          debugPrint('🔔 Navigated to order action result page');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for stored notification action: $e');
    }
  }

  /// Test chat message notification (should use system sound)
  Future<void> testChatMessageNotification() async {
    try {
      final testMessage = RemoteMessage(
        notification: RemoteNotification(
          title: 'New Message',
          body: 'You have received a new message from customer',
        ),
        data: {'type': 'chat_message', 'message_id': 'msg_123'},
        messageId: 'test_chat_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _showLocalNotification(testMessage);
    } catch (e) {
      debugPrint('❌ Error testing chat message notification: $e');
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

  /// Test background notification simulation (public)
  Future<void> testBackgroundNotification() async {
    try {
      debugPrint('🧪 Testing background notification simulation...');
      
      // Create a test message that simulates a background notification
      final testMessage = RemoteMessage(
        data: {
          'type': 'new_order',
          'title': 'Test Background Order',
          'body': 'This is a test background order notification',
          'order_id': 'test_123'
        },
        messageId: 'test_background_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Call the background handler directly
      await _firebaseMessagingBackgroundHandler(testMessage);
      
      debugPrint('✅ Background notification test completed');
    } catch (e) {
      debugPrint('❌ Error testing background notification: $e');
    }
  }

  /// Create notification details with optional custom sound
  NotificationDetails _createNotificationDetails({String? notificationType}) {
    // Use custom sound only for 'new_order' type notifications
    final useCustomSound = notificationType == 'new_order';
    final isChatMessage = notificationType == 'chat_message';
    
    debugPrint('🔔 Creating notification details - Type: $notificationType, Custom sound: $useCustomSound');

    if (useCustomSound) {
      // Create action buttons for new order notifications
      const acceptAction = AndroidNotificationAction(
        'accept_order',
        'Accept',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
        contextual: true,
        showsUserInterface: true,
        cancelNotification: false,
      );
      const rejectAction = AndroidNotificationAction(
        'reject_order', 
        'Reject',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
        contextual: true,
        showsUserInterface: true,
        cancelNotification: false,
      );

      // Use custom sound from raw resources for new order notifications
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_order_channel',
        'Bird Partner Order Notifications',
        channelDescription: 'Order notifications with custom ringtone',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_ringtone'),
        actions: [acceptAction, rejectAction],
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
    } else if (isChatMessage) {
      // Use a separate channel for chat messages with sound disabled
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_chat_channel',
        'Bird Partner Chat Notifications',
        channelDescription: 'Chat notifications for Bird Partner app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      return const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    } else {
      // Fallback for other types: system default sound, default channel
      const androidDetails = AndroidNotificationDetails(
        'bird_partner_default_channel',
        'Bird Partner Default Notifications',
        channelDescription: 'Default notifications for Bird Partner app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      return const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    }
  }
}