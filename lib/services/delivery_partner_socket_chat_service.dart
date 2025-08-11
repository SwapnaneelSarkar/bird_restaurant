// lib/services/delivery_partner_socket_chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'delivery_partner_services/delivery_partner_auth_service.dart';
import 'chat_services.dart';

class DeliveryPartnerSocketChatService extends ChangeNotifier {
  static const String baseUrl = 'https://api.bird.delivery/api';
  static const String wsUrl = 'https://api.bird.delivery/';
  
  IO.Socket? _socket;
  List<ApiChatMessage> _messages = [];
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _token;
  Timer? _typingTimer;
  Timer? _reconnectTimer;
  Timer? _notifyDebounceTimer;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  
  // Track sent messages to avoid duplicates (for future use)
  // final Set<String> _sentMessageIds = <String>{};
  
  // Stream controller for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  // Stream controller for real-time read status updates
  final StreamController<Map<String, dynamic>> _readStatusStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream => _readStatusStreamController.stream;

  DeliveryPartnerSocketChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      // Use delivery partner credentials instead of regular user credentials
      _currentUserId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
      _token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
      debugPrint('DeliveryPartnerSocketChatService: 🆔 User ID: $_currentUserId');
      debugPrint('DeliveryPartnerSocketChatService: 🔑 Token available: ${_token != null}');
    } catch (e) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error initializing service: $e');
    }
  }

  Future<void> _initializeSocket() async {
    if (_isDisposed) return;
    
    try {
      // Ensure we have current credentials
      if (_currentUserId == null || _token == null) {
        await _initializeService();
      }
      
      if (_currentUserId == null || _token == null) {
        throw Exception('Missing delivery partner credentials');
      }

      debugPrint('DeliveryPartnerSocketChatService: 🔌 Initializing socket connection...');
      debugPrint('DeliveryPartnerSocketChatService: 🌐 WebSocket URL: $wsUrl');
      debugPrint('DeliveryPartnerSocketChatService: 🆔 User ID: $_currentUserId');
      
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {
          'userId': _currentUserId,
          'userType': 'delivery_partner', // Important: specify user type
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
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error initializing socket: $e');
      _handleConnectionFailure('Socket initialization failed: $e');
    }
  }

  void _setupSocketEventHandlers() {
    if (_socket == null) return;

    _socket!.on('connect', (data) {
      debugPrint('DeliveryPartnerSocketChatService: ✅ Connected to server');
      _isConnected = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      notifyListeners();
    });

    _socket!.on('disconnect', (data) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Disconnected from server: $data');
      _isConnected = false;
      notifyListeners();
      
      if (!_isDisposed) {
        _scheduleReconnect();
      }
    });

    _socket!.on('connect_error', (error) {
      debugPrint('DeliveryPartnerSocketChatService: 🚨 Connection error: $error');
      _isConnected = false;
      notifyListeners();
      _handleConnectionFailure('Connection error: $error');
    });

    _socket!.on('new_message', (data) {
      debugPrint('DeliveryPartnerSocketChatService: 📨 New message received: $data');
      _handleIncomingMessage(data);
    });

    _socket!.on('message_read', (data) {
      debugPrint('DeliveryPartnerSocketChatService: 👁️ Message read status updated: $data');
      _handleReadStatusUpdate(data);
    });

    _socket!.on('user_typing', (data) {
      debugPrint('DeliveryPartnerSocketChatService: ⌨️ User typing: $data');
    });

    _socket!.on('error', (error) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Socket error: $error');
    });
  }

  Future<void> connect() async {
    if (_isConnected || _isDisposed) return;
    
    try {
      await _initializeSocket();
      
      if (_socket != null) {
        debugPrint('DeliveryPartnerSocketChatService: 🔌 Connecting socket...');
        _socket!.connect();
        
        // Wait for connection with timeout
        await _waitForConnection();
      }
    } catch (e) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error connecting: $e');
      _handleConnectionFailure('Connection failed: $e');
    }
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
    debugPrint('DeliveryPartnerSocketChatService: 🚨 Connection failure: $error');
    _isConnected = false;
    notifyListeners();
    
    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) {
      debugPrint('DeliveryPartnerSocketChatService: 🛑 Max reconnection attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: 3 * _reconnectAttempts);
    
    debugPrint('DeliveryPartnerSocketChatService: 🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Cannot join room - not connected');
      return;
    }
    
    _currentRoomId = roomId;
    
    debugPrint('DeliveryPartnerSocketChatService: 🚪 Joining room: $roomId');
    _socket!.emit('join_room', {
      'roomId': roomId,
      'userId': _currentUserId,
      'userType': 'delivery_partner',
    });
    
    // Load chat history immediately after joining
    await loadChatHistory(roomId);
  }

  Future<void> loadChatHistory(String roomId) async {
    try {
      debugPrint('DeliveryPartnerSocketChatService: 📚 Loading chat history for room: $roomId');
      
      if (_token == null) {
        debugPrint('DeliveryPartnerSocketChatService: ❌ No token found for loading chat history');
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
      
      debugPrint('DeliveryPartnerSocketChatService: 📚 Chat history response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('DeliveryPartnerSocketChatService: 📚 Response data: $responseData');
        
        List<dynamic> messagesJson = [];
        
        // Handle different response structures
        if (responseData is List) {
          // Direct array of messages
          messagesJson = responseData;
          debugPrint('DeliveryPartnerSocketChatService: 📚 Response is direct array with ${messagesJson.length} messages');
        } else if (responseData is Map && responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          // Wrapped in data object
          if (responseData['data'] is List) {
            messagesJson = responseData['data'];
          } else if (responseData['data']['messages'] != null) {
            messagesJson = responseData['data']['messages'];
          }
          debugPrint('DeliveryPartnerSocketChatService: 📚 Found ${messagesJson.length} messages in wrapped response');
        }
        
        if (messagesJson.isNotEmpty) {
          _messages = messagesJson.map((json) {
            try {
              debugPrint('DeliveryPartnerSocketChatService: 📚 Parsing message: $json');
              return ApiChatMessage.fromJson(json);
            } catch (e) {
              debugPrint('DeliveryPartnerSocketChatService: ❌ Error parsing message: $e');
              debugPrint('DeliveryPartnerSocketChatService: ❌ Message JSON: $json');
              return null;
            }
          }).where((msg) => msg != null).cast<ApiChatMessage>().toList();
          
          // Sort messages by creation time
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('DeliveryPartnerSocketChatService: ✅ Loaded ${_messages.length} messages');
          notifyListeners();
        } else {
          debugPrint('DeliveryPartnerSocketChatService: ❌ No messages found in response');
        }
      } else {
        debugPrint('DeliveryPartnerSocketChatService: ❌ Failed to load chat history: ${response.statusCode}');
        debugPrint('DeliveryPartnerSocketChatService: ❌ Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error loading chat history: $e');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = ApiChatMessage.fromJson(data);
      
      // Avoid duplicates
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('DeliveryPartnerSocketChatService: ✅ Added new message: ${message.id}');
        
        // Notify listeners
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error handling incoming message: $e');
    }
  }

  void _handleReadStatusUpdate(dynamic data) {
    try {
      debugPrint('DeliveryPartnerSocketChatService: 👁️ Processing read status update: $data');
      
      // Update read status in local messages
      final messageId = data['messageId']?.toString();
      final readBy = data['readBy'] as List<dynamic>?;
      
      if (messageId != null && readBy != null) {
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex >= 0) {
          // Update the message's read status
          final updatedMessage = _messages[messageIndex];
          _messages[messageIndex] = ApiChatMessage(
            id: updatedMessage.id,
            roomId: updatedMessage.roomId,
            senderId: updatedMessage.senderId,
            senderType: updatedMessage.senderType,
            content: updatedMessage.content,
            messageType: updatedMessage.messageType,
            readBy: readBy.map((e) => ReadByEntry(
              userId: e.toString(),
              readAt: DateTime.now(),
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            )).toList(),
            createdAt: updatedMessage.createdAt,
          );
          
          debugPrint('DeliveryPartnerSocketChatService: ✅ Updated read status for message: $messageId');
        }
      }
      
      // Notify read status stream
      if (!_readStatusStreamController.isClosed) {
        _readStatusStreamController.add(data);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Error handling read status update: $e');
    }
  }

  Future<void> markAsRead(String roomId) async {
    if (!_isConnected || _socket == null) {
      debugPrint('DeliveryPartnerSocketChatService: ❌ Cannot mark as read via socket - not connected');
      
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
        
        debugPrint('DeliveryPartnerSocketChatService: ✅ Marked as read via API');
      } catch (e) {
        debugPrint('DeliveryPartnerSocketChatService: ❌ Error marking as read via API: $e');
      }
      return;
    }
    
    debugPrint('DeliveryPartnerSocketChatService: 👁️ Marking messages as read for room: $roomId');
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
    debugPrint('DeliveryPartnerSocketChatService: 🔄 Handling app resume');
    
    // Reconnect if not connected
    if (!_isConnected) {
      await connect();
    }
    
    // Refresh messages if we have a current room
    if (_currentRoomId != null) {
      await refreshMessages();
    }
  }

  void disconnect() {
    debugPrint('DeliveryPartnerSocketChatService: 🔌 Disconnecting socket...');
    
    _isDisposed = true;
    _isConnected = false;
    
    _reconnectTimer?.cancel();
    _typingTimer?.cancel();
    _notifyDebounceTimer?.cancel();
    
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