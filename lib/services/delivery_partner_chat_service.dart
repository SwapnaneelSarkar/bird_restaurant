// lib/services/delivery_partner_chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'delivery_partner_services/delivery_partner_auth_service.dart';

// Separate message model for delivery partner chat API
class DeliveryPartnerApiMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<DeliveryPartnerReadByEntry> readBy;
  final DateTime createdAt;

  DeliveryPartnerApiMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory DeliveryPartnerApiMessage.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    List<DeliveryPartnerReadByEntry> readBy = [];
    try {
      if (json['readBy'] != null && json['readBy'] is List) {
        readBy = (json['readBy'] as List).map((entry) {
          try {
            return DeliveryPartnerReadByEntry.fromJson(entry);
          } catch (e) {
            return null;
          }
        }).where((entry) => entry != null).cast<DeliveryPartnerReadByEntry>().toList();
      }
    } catch (e) {
      readBy = [];
    }
    
    return DeliveryPartnerApiMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: readBy,
      createdAt: createdAt,
    );
  }

  // Check if this message is from current user
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return senderId == currentUserId;
  }

  // Check if message is read by others (for blue tick)
  bool isReadByOthers(String senderId) {
    return readBy.any((entry) => entry.userId != senderId);
  }

  // Get read status for UI
  bool get isRead => readBy.isNotEmpty && readBy.any((entry) => entry.userId != senderId);
}

// Separate read by entry model for delivery partner chat
class DeliveryPartnerReadByEntry {
  final String userId;
  final DateTime readAt;
  final String id;

  DeliveryPartnerReadByEntry({
    required this.userId,
    required this.readAt,
    required this.id,
  });

  factory DeliveryPartnerReadByEntry.fromJson(Map<String, dynamic> json) {
    DateTime readAt;
    try {
      readAt = DateTime.parse(json['readAt']);
    } catch (e) {
      readAt = DateTime.now();
    }
    
    return DeliveryPartnerReadByEntry(
      userId: json['userId'] ?? '',
      readAt: readAt,
      id: json['_id'] ?? '',
    );
  }
}

class DeliveryPartnerChatService extends ChangeNotifier {
  static const String baseUrl = 'https://api.bird.delivery/api';
  static const String wsUrl = 'https://api.bird.delivery/';
  
  IO.Socket? _socket;
  List<DeliveryPartnerApiMessage> _messages = [];
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _token;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  
  // Stream controllers
  final StreamController<DeliveryPartnerApiMessage> _messageStreamController = 
      StreamController<DeliveryPartnerApiMessage>.broadcast();
  
  final StreamController<Map<String, dynamic>> _readStatusStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  List<DeliveryPartnerApiMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  
  Stream<DeliveryPartnerApiMessage> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream => _readStatusStreamController.stream;

  DeliveryPartnerChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _currentUserId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
      _token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
      debugPrint('DeliveryPartnerChatService: 🆔 User ID: $_currentUserId');
      debugPrint('DeliveryPartnerChatService: 🔑 Token available: ${_token != null}');
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error initializing service: $e');
    }
  }

  Future<void> connect() async {
    if (_isConnected || _isDisposed) return;
    
    try {
      await _initializeSocket();
      
      if (_socket != null) {
        debugPrint('DeliveryPartnerChatService: 🔌 Connecting socket...');
        _socket!.connect();
        await _waitForConnection();
      }
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error connecting: $e');
      _handleConnectionFailure('Connection failed: $e');
    }
  }

  Future<void> _initializeSocket() async {
    if (_isDisposed) return;
    
    try {
      if (_currentUserId == null || _token == null) {
        await _initializeService();
      }
      
      if (_currentUserId == null || _token == null) {
        throw Exception('Missing delivery partner credentials');
      }

      debugPrint('DeliveryPartnerChatService: 🔌 Initializing socket connection...');
      
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {
          'userId': _currentUserId,
          'userType': 'delivery_partner',
        },
        'extraHeaders': {
          'Authorization': 'Bearer $_token',
        },
        'timeout': 20000,
        'reconnection': true,
        'reconnectionAttempts': _maxReconnectAttempts,
        'reconnectionDelay': 3000,
        'reconnectionDelayMax': 10000,
        'maxReconnectionAttempts': _maxReconnectAttempts,
        'forceNew': true,
        'upgrade': false,
        'rememberUpgrade': false,
        'secure': true,
        'rejectUnauthorized': false,
        'pingTimeout': 60000,
        'pingInterval': 25000,
      });

      _setupSocketEventHandlers();
      
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error initializing socket: $e');
      _handleConnectionFailure('Socket initialization failed: $e');
    }
  }

  void _setupSocketEventHandlers() {
    if (_socket == null) return;

    _socket!.on('connect', (data) {
      debugPrint('DeliveryPartnerChatService: ✅ Connected to server');
      _isConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      notifyListeners();
    });

    _socket!.on('disconnect', (data) {
      debugPrint('DeliveryPartnerChatService: ❌ Disconnected from server: $data');
      _isConnected = false;
      notifyListeners();
      
      if (!_isDisposed) {
        _scheduleReconnect();
      }
    });

    _socket!.on('connect_error', (error) {
      debugPrint('DeliveryPartnerChatService: 🚨 Connection error: $error');
      _isConnected = false;
      notifyListeners();
      _handleConnectionFailure('Connection error: $error');
    });

    _socket!.on('new_message', (data) {
      debugPrint('DeliveryPartnerChatService: 📨 New message received: $data');
      _handleIncomingMessage(data);
    });

    _socket!.on('message_read', (data) {
      debugPrint('DeliveryPartnerChatService: 👁️ Message read status updated: $data');
      _handleReadStatusUpdate(data);
    });

    _socket!.on('error', (error) {
      debugPrint('DeliveryPartnerChatService: ❌ Socket error: $error');
    });
  }

  Future<void> _waitForConnection() async {
    const timeout = Duration(seconds: 10);
    const interval = Duration(milliseconds: 100);
    int elapsed = 0;
    
    while (!_isConnected && elapsed < timeout.inMilliseconds && !_isDisposed) {
      await Future.delayed(interval);
      elapsed += interval.inMilliseconds;
    }
    
    if (!_isConnected && !_isDisposed) {
      throw Exception('Connection timeout');
    }
  }

  void _handleConnectionFailure(String error) {
    debugPrint('DeliveryPartnerChatService: 🚨 Connection failure: $error');
    _isConnected = false;
    notifyListeners();
    
    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) {
      debugPrint('DeliveryPartnerChatService: 🛑 Max reconnection attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: 3 * _reconnectAttempts);
    
    debugPrint('DeliveryPartnerChatService: 🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      debugPrint('DeliveryPartnerChatService: ❌ Cannot join room - not connected');
      return;
    }
    
    _currentRoomId = roomId;
    
    debugPrint('DeliveryPartnerChatService: 🚪 Joining room: $roomId');
    _socket!.emit('join_room', {
      'roomId': roomId,
      'userId': _currentUserId,
      'userType': 'delivery_partner',
    });
    
    // Load initial chat history
    await loadChatHistory(roomId);
  }

  Future<void> loadChatHistory(String roomId) async {
    try {
      debugPrint('DeliveryPartnerChatService: 📚 Loading chat history for room: $roomId');
      
      if (_token == null) {
        debugPrint('DeliveryPartnerChatService: ❌ No token found for loading chat history');
        return;
      }
      
      final url = Uri.parse('$baseUrl/chat/history/$roomId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('DeliveryPartnerChatService: 📚 Chat history response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('DeliveryPartnerChatService: 📚 Response data: $responseData');
        
        List<dynamic> messagesJson = [];
        
        // Handle different response structures
        if (responseData is List) {
          messagesJson = responseData;
          debugPrint('DeliveryPartnerChatService: 📚 Response is direct array with ${messagesJson.length} messages');
        } else if (responseData is Map && responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          if (responseData['data'] is List) {
            messagesJson = responseData['data'];
          } else if (responseData['data']['messages'] != null) {
            messagesJson = responseData['data']['messages'];
          }
          debugPrint('DeliveryPartnerChatService: 📚 Found ${messagesJson.length} messages in wrapped response');
        }
        
        if (messagesJson.isNotEmpty) {
          _messages = messagesJson.map((json) {
            try {
              debugPrint('DeliveryPartnerChatService: 📚 Parsing message: $json');
              return DeliveryPartnerApiMessage.fromJson(json);
            } catch (e) {
              debugPrint('DeliveryPartnerChatService: ❌ Error parsing message: $e');
              return null;
            }
          }).where((msg) => msg != null).cast<DeliveryPartnerApiMessage>().toList();
          
          // Sort messages by creation time using proper comparison
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('DeliveryPartnerChatService: ✅ Loaded ${_messages.length} messages');
          notifyListeners();
        } else {
          debugPrint('DeliveryPartnerChatService: ❌ No messages found in response');
        }
      } else {
        debugPrint('DeliveryPartnerChatService: ❌ Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error loading chat history: $e');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = DeliveryPartnerApiMessage.fromJson(data);
      
      // Avoid duplicates
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('DeliveryPartnerChatService: ✅ Added new message: ${message.id}');
        
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error handling incoming message: $e');
    }
  }

  void _handleReadStatusUpdate(dynamic data) {
    try {
      debugPrint('DeliveryPartnerChatService: 👁️ Processing read status update: $data');
      
      final messageId = data['messageId']?.toString();
      final readBy = data['readBy'] as List<dynamic>?;
      
      if (messageId != null && readBy != null) {
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex >= 0) {
          final updatedMessage = _messages[messageIndex];
          _messages[messageIndex] = DeliveryPartnerApiMessage(
            id: updatedMessage.id,
            roomId: updatedMessage.roomId,
            senderId: updatedMessage.senderId,
            senderType: updatedMessage.senderType,
            content: updatedMessage.content,
            messageType: updatedMessage.messageType,
            readBy: readBy.map((e) => DeliveryPartnerReadByEntry(
              userId: e.toString(),
              readAt: DateTime.now(),
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            )).toList(),
            createdAt: updatedMessage.createdAt,
          );
          
          debugPrint('DeliveryPartnerChatService: ✅ Updated read status for message: $messageId');
        }
      }
      
      if (!_readStatusStreamController.isClosed) {
        _readStatusStreamController.add(data);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('DeliveryPartnerChatService: ❌ Error handling read status update: $e');
    }
  }

  Future<void> markAsRead(String roomId) async {
    if (!_isConnected || _socket == null) {
      debugPrint('DeliveryPartnerChatService: ❌ Cannot mark as read via socket - not connected');
      
      // Fallback to API call
      try {
        if (_token == null) return;
        
        final url = Uri.parse('$baseUrl/chat/mark-read');
        await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'roomId': roomId,
            'userId': _currentUserId,
          }),
        );
        
        debugPrint('DeliveryPartnerChatService: ✅ Marked as read via API');
      } catch (e) {
        debugPrint('DeliveryPartnerChatService: ❌ Error marking as read via API: $e');
      }
      return;
    }
    
    debugPrint('DeliveryPartnerChatService: 👁️ Marking messages as read for room: $roomId');
    _socket!.emit('mark_as_read', {
      'roomId': roomId,
      'userId': _currentUserId,
    });
  }

  Future<void> refreshMessages() async {
    if (_currentRoomId != null) {
      await loadChatHistory(_currentRoomId!);
    }
  }

  Future<void> handleAppResume() async {
    debugPrint('DeliveryPartnerChatService: 🔄 Handling app resume');
    
    if (!_isConnected) {
      await connect();
    }
    
    if (_currentRoomId != null) {
      await refreshMessages();
    }
  }

  void disconnect() {
    debugPrint('DeliveryPartnerChatService: 🔌 Disconnecting socket...');
    
    _isDisposed = true;
    _isConnected = false;
    
    _reconnectTimer?.cancel();
    
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    _currentRoomId = null;
    _messages.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    
    _messageStreamController.close();
    _readStatusStreamController.close();
    
    super.dispose();
  }
} 