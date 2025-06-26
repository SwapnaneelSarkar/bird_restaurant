// lib/services/chat_services.dart - FINAL VERSION WITH SOCKET.IO MARK AS READ

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'token_service.dart';

class ReadByEntry {
  final String userId;
  final DateTime readAt;
  final String id;

  ReadByEntry({
    required this.userId,
    required this.readAt,
    required this.id,
  });

  factory ReadByEntry.fromJson(Map<String, dynamic> json) {
    return ReadByEntry(
      userId: json['userId'] ?? '',
      readAt: DateTime.parse(json['readAt']),
      id: json['_id'] ?? '',
    );
  }
}

class ApiChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<ReadByEntry> readBy;
  final DateTime createdAt;

  ApiChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) {
    return ApiChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((readEntry) => ReadByEntry.fromJson(readEntry))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  // Check if this message is from current user by comparing sender IDs
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return senderId == currentUserId;
  }

  // Check if message is read by a specific user
  bool isReadByUser(String userId) {
    return readBy.any((entry) => entry.userId == userId);
  }

  // Check if message is read by anyone other than sender (for tick status)
  bool isReadByOthers(String senderId) {
    return readBy.any((entry) => entry.userId != senderId);
  }

  // Get read status for UI (blue tick if read by others, grey if not)
  bool get isRead => readBy.isNotEmpty && readBy.any((entry) => entry.userId != senderId);

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'readBy': readBy.map((entry) => {
        'userId': entry.userId,
        'readAt': entry.readAt.toIso8601String(),
        '_id': entry.id,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SocketChatService extends ChangeNotifier {
  static const String baseUrl = 'https://api.bird.delivery/api/';
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
  
  // Track sent messages to avoid duplicates
  final Set<String> _sentMessageIds = <String>{};
  
  // Stream controller for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;

  SocketChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _currentUserId = await TokenService.getUserId();
      _token = await TokenService.getToken();
      debugPrint('SocketChatService: 🆔 User ID: $_currentUserId');
      debugPrint('SocketChatService: 🔑 Token available: ${_token != null}');
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error initializing service: $e');
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
        throw Exception('Missing user credentials');
      }

      debugPrint('SocketChatService: 🔌 Initializing socket connection...');
      debugPrint('SocketChatService: 🌐 WebSocket URL: $wsUrl');
      debugPrint('SocketChatService: 🆔 User ID: $_currentUserId');
      
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {
          'userId': _currentUserId,
          'userType': 'partner',
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
      debugPrint('SocketChatService: ❌ Error initializing socket: $e');
      _handleConnectionFailure('Socket initialization failed: $e');
    }
  }

  void _setupSocketEventHandlers() {
    if (_socket == null || _isDisposed) return;

    debugPrint('SocketChatService: 🔧 Setting up socket event handlers...');

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('SocketChatService: ✅ Socket connected successfully');
      debugPrint('SocketChatService: 🔍 Socket ID: ${_socket!.id}');
      debugPrint('SocketChatService: 🔍 Socket connected: ${_socket!.connected}');
      _isConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();
      
      // Rejoin current room if we have one
      if (_currentRoomId != null) {
        _socket!.emit('join_room', _currentRoomId);
        debugPrint('SocketChatService: 🏠 Rejoined room: $_currentRoomId');
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketChatService: ❌ Socket disconnected');
      debugPrint('SocketChatService: 🔍 Socket connected: ${_socket!.connected}');
      _isConnected = false;
      notifyListeners();
      _handleReconnection();
    });

    _socket!.onConnectError((data) {
      debugPrint('SocketChatService: ❌ Connection error: $data');
      debugPrint('SocketChatService: 🔍 Socket connected: ${_socket!.connected}');
      _isConnected = false;
      notifyListeners();
      _handleReconnection();
    });

    _socket!.onError((data) {
      debugPrint('SocketChatService: ❌ Socket error: $data');
    });

    // Message events
    _socket!.on('receive_message', (data) {
      debugPrint('SocketChatService: 📥 Received message via socket: $data');
      _handleReceivedMessage(data);
    });

    // NEW: Message sent confirmation
    _socket!.on('message_sent', (data) {
      debugPrint('SocketChatService: ✅ Message sent confirmation: $data');
      _handleMessageSentConfirmation(data);
    });

    // NEW: Read status events
    _socket!.on('message_read', (data) {
      debugPrint('SocketChatService: 📖 Received message_read event: $data');
      _handleMessageReadUpdate(data);
    });

    _socket!.on('messages_marked_read', (data) {
      debugPrint('SocketChatService: 📖 Received messages_marked_read event: $data');
      _handleMessagesMarkedRead(data);
    });

    // User events
    _socket!.on('user_joined', (data) {
      debugPrint('SocketChatService: 👋 User joined: $data');
    });

    _socket!.on('user_left', (data) {
      debugPrint('SocketChatService: 👋 User left: $data');
    });

    // Typing events
    _socket!.on('user_typing', (data) {
      debugPrint('SocketChatService: ⌨️ User typing: $data');
    });

    _socket!.on('user_stop_typing', (data) {
      debugPrint('SocketChatService: ⌨️ User stopped typing: $data');
    });

    debugPrint('SocketChatService: ✅ Socket event handlers set up successfully');
  }

  // NEW: Debounced notification method
  void _debouncedNotify() {
    _notifyDebounceTimer?.cancel();
    _notifyDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isDisposed) {
        debugPrint('SocketChatService: 📢 Debounced notification sent');
        notifyListeners();
      }
    });
  }

  void _handleReceivedMessage(dynamic data) {
    try {
      debugPrint('SocketChatService: 📥 Processing received message...');
      debugPrint('SocketChatService: Raw data: $data');
      
      Map<String, dynamic> messageData;
      
      if (data is String) {
        messageData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else {
        debugPrint('SocketChatService: ❌ Invalid message format');
        return;
      }
      
      final message = ApiChatMessage.fromJson(messageData);
      
      // CRITICAL: Skip messages from current user to avoid duplicates
      if (message.isFromCurrentUser(_currentUserId)) {
        debugPrint('SocketChatService: 🔄 Skipping own message from socket: ${message.content}');
        return;
      }
      
      // IMPROVED: Better duplicate detection using multiple criteria
      final messageExists = _messages.any((m) => 
        m.id == message.id || // Same ID (definite duplicate)
        (m.content == message.content && 
         m.senderId == message.senderId &&
         m.createdAt.difference(message.createdAt).abs().inMilliseconds < 100) // Same content, sender, and very close time (within 100ms - likely duplicate)
      );
      
      if (!messageExists) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('SocketChatService: ✨ New message added from ${message.senderType}: "${message.content}"');
        debugPrint('SocketChatService: 📊 Total messages: ${_messages.length}');
        
        // Emit to stream for immediate UI updates (only for other users' messages)
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
        
        // AUTO mark as read for incoming messages via SOCKET
        if (_currentRoomId != null) {
          markAsReadViaSocket(_currentRoomId!);
          debugPrint('SocketChatService: 📖 Auto-marked incoming message as read via socket');
        }
        
        _debouncedNotify();
      } else {
        debugPrint('SocketChatService: 🔄 Message already exists, skipping duplicate: "${message.content}"');
        debugPrint('SocketChatService: 🔍 Duplicate check - ID: ${message.id}, Content: ${message.content}, Sender: ${message.senderId}');
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling received message: $e');
    }
  }

  // NEW: Handle message sent confirmation
  void _handleMessageSentConfirmation(dynamic data) {
    try {
      debugPrint('SocketChatService: 📥 Processing message sent confirmation...');
      debugPrint('SocketChatService: Raw confirmation data: $data');
      
      Map<String, dynamic> messageData;
      
      if (data is String) {
        messageData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else {
        debugPrint('SocketChatService: ❌ Invalid confirmation data format');
        return;
      }
      
      final message = ApiChatMessage.fromJson(messageData);
      
      // IMPROVED: Better optimistic message update logic
      final existingIndex = _messages.indexWhere((msg) => 
        msg.content == message.content && 
        msg.senderId == message.senderId &&
        msg.createdAt.difference(message.createdAt).abs().inSeconds < 3);
      
      if (existingIndex != -1) {
        // Update the optimistic message with the real message from server
        final oldMessage = _messages[existingIndex];
        if (oldMessage.id != message.id) {
          _messages[existingIndex] = message;
          debugPrint('SocketChatService: ✅ Updated optimistic message with server confirmation');
          debugPrint('SocketChatService: 🔄 Old ID: ${oldMessage.id} -> New ID: ${message.id}');
        } else {
          debugPrint('SocketChatService: 🔄 Message already has correct ID, no update needed');
        }
      } else {
        // Check if this is a completely new message (shouldn't happen for sent confirmations)
        final isNewMessage = !_messages.any((msg) => 
          msg.id == message.id ||
          (msg.content == message.content && 
           msg.senderId == message.senderId &&
           msg.createdAt.difference(message.createdAt).abs().inSeconds < 3));
        
        if (isNewMessage) {
          _messages.add(message);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          debugPrint('SocketChatService: ✅ Added confirmed message to list');
        } else {
          debugPrint('SocketChatService: 🔄 Confirmed message already exists, skipping');
        }
      }
      
      _debouncedNotify();
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling message sent confirmation: $e');
    }
  }

  // NEW: Handle individual message read update
  void _handleMessageReadUpdate(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final messageId = readData['messageId'];
      final userId = readData['userId'];
      final readAt = DateTime.parse(readData['readAt']);
      
      debugPrint('SocketChatService: 📖 Message $messageId read by $userId at $readAt');
      
      // Find and update the specific message
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedReadBy = List<ReadByEntry>.from(message.readBy);
        
        // Add new read entry if not already present
        if (!updatedReadBy.any((entry) => entry.userId == userId)) {
          updatedReadBy.add(ReadByEntry(
            userId: userId,
            readAt: readAt,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
          // Create updated message
          final updatedMessage = ApiChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            senderType: message.senderType,
            content: message.content,
            messageType: message.messageType,
            readBy: updatedReadBy,
            createdAt: message.createdAt,
          );
          
          _messages[messageIndex] = updatedMessage;
          notifyListeners();
          
          debugPrint('SocketChatService: ✅ Updated read status for message: $messageId');
        }
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling message read update: $e');
    }
  }

  // NEW: Handle bulk messages marked read
  void _handleMessagesMarkedRead(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final roomId = readData['roomId'];
      final userId = readData['userId'];
      final readAt = DateTime.parse(readData['readAt']);
      
      debugPrint('SocketChatService: 📖 All messages in room $roomId marked as read by $userId');
      
      // Update all messages in the room that aren't already read by this user
      bool hasUpdates = false;
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.roomId == roomId && !message.readBy.any((entry) => entry.userId == userId)) {
          final updatedReadBy = List<ReadByEntry>.from(message.readBy);
          updatedReadBy.add(ReadByEntry(
            userId: userId,
            readAt: readAt,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
          _messages[i] = ApiChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            senderType: message.senderType,
            content: message.content,
            messageType: message.messageType,
            readBy: updatedReadBy,
            createdAt: message.createdAt,
          );
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        notifyListeners();
        debugPrint('SocketChatService: ✅ Updated read status for all messages in room: $roomId');
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling messages marked read: $e');
    }
  }

  void _handleReconnection() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 3 * (_reconnectAttempts + 1)), () {
      if (!_isDisposed && !_isConnected) {
        _reconnectAttempts++;
        debugPrint('SocketChatService: 🔄 Reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts');
        _socket?.connect();
      }
    });
  }

  Future<void> connect() async {
    if (_isDisposed) return;
    
    try {
      if (_socket == null) {
        await _initializeSocket();
      }
      
      if (_socket != null && !_isConnected) {
        debugPrint('SocketChatService: 🔌 Connecting socket...');
        debugPrint('SocketChatService: 🔍 Socket state before connect: ${_socket!.connected}');
        
        _socket!.connect();
        
        // Wait for connection with timeout
        int attempts = 0;
        while (!_isConnected && attempts < 10 && !_isDisposed) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          debugPrint('SocketChatService: ⏳ Waiting for connection... attempt $attempts');
        }
        
        if (_isConnected) {
          debugPrint('SocketChatService: ✅ Socket connected successfully');
        } else {
          debugPrint('SocketChatService: ❌ Socket connection timeout');
          _handleConnectionFailure('Connection timeout');
        }
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error connecting: $e');
      _handleConnectionFailure('Connection error: $e');
    }
  }

  void disconnect() {
    debugPrint('SocketChatService: 🔌 Disconnecting socket...');
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> joinRoom(String roomId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('SocketChatService: 🏠 Joining room: $roomId');
      
      // Ensure we have current user ID
      if (_currentUserId == null) {
        _currentUserId = await TokenService.getUserId();
        debugPrint('SocketChatService: 🆔 Retrieved user ID: $_currentUserId');
      }
      
      // Leave current room if we have one
      if (_currentRoomId != null && _currentRoomId != roomId) {
        leaveRoom(_currentRoomId!);
      }
      
      _currentRoomId = roomId;
      
      // Connect socket if not connected
      if (!_isConnected) {
        await connect();
        // Wait for connection to establish
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // Join room via socket
      if (_socket != null && _isConnected) {
        _socket!.emit('join_room', roomId);
        debugPrint('SocketChatService: 📤 Sent join_room event for: $roomId');
      }
      
      // Load initial chat history via REST API
      await loadChatHistory(roomId);
      
      // Mark messages as read when joining room via SOCKET
      markAsReadViaSocket(roomId);
      debugPrint('SocketChatService: 📖 Auto-marked room messages as read via socket on join');
      
      debugPrint('SocketChatService: ✅ Successfully joined room and loaded history');
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error joining room: $e');
    }
  }

  void leaveRoom(String roomId) {
    debugPrint('SocketChatService: 👋 Leaving room: $roomId');
    
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', roomId);
    }
    
    if (_currentRoomId == roomId) {
      _currentRoomId = null;
    }
  }

  Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
    if (_isDisposed) return false;
    
    try {
      final token = _token ?? await TokenService.getToken();
      final userId = _currentUserId ?? await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('SocketChatService: ❌ No token or user ID found');
        return false;
      }

      debugPrint('SocketChatService: 📤 Sending message: "$content"');
      debugPrint('SocketChatService: 🆔 Using sender ID: $userId');

      // PRIMARY: Send via REST API first for reliable message delivery
      final messageData = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'partner',
        'content': content,
        'messageType': messageType,
      };

      final url = Uri.parse('${baseUrl}chat/message');
      
      debugPrint('SocketChatService: 📨 Sending via REST API to: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('SocketChatService: 📨 REST API response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final sentMessage = ApiChatMessage.fromJson(responseData);
        
        // Add the confirmed message from API
        final apiMessageExists = _messages.any((msg) => 
            msg.content == content && 
            msg.senderId == userId &&
            msg.createdAt.difference(sentMessage.createdAt).abs().inSeconds < 3);
        
        if (!apiMessageExists) {
          _messages.add(sentMessage);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
          debugPrint('SocketChatService: ✅ Added API message to local list');
        }
        
        // SECONDARY: Send via Socket.IO for real-time notifications (if connected)
        if (_socket != null && _isConnected) {
          final socketMessageData = {
            'roomId': roomId,
            'senderId': userId,
            'senderType': 'partner',
            'content': content,
            'messageType': messageType,
            'timestamp': DateTime.now().toIso8601String(),
          };

          debugPrint('SocketChatService: 📡 Sending via socket for real-time notification: $socketMessageData');
          _socket!.emit('send_message', socketMessageData);
        }
        
        // Mark as read via socket if connected
        if (_socket != null && _isConnected) {
          markAsReadViaSocket(roomId);
          debugPrint('SocketChatService: 📖 Marked message as read via socket');
        }
        
        return true;
      } else {
        debugPrint('SocketChatService: ❌ Failed to send message via API: ${response.statusCode}');
        debugPrint('SocketChatService: ❌ Response body: ${response.body}');
        
        // FALLBACK: Try WebSocket if API fails
        if (_socket != null && _isConnected) {
          debugPrint('SocketChatService: ⚠️ Falling back to WebSocket due to API failure');
          
          final socketMessageData = {
            'roomId': roomId,
            'senderId': userId,
            'senderType': 'partner',
            'content': content,
            'messageType': messageType,
            'timestamp': DateTime.now().toIso8601String(),
          };

          _socket!.emit('send_message', socketMessageData);
          
          // Create optimistic message for immediate UI update
          final optimisticMessage = ApiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            roomId: roomId,
            senderId: userId,
            senderType: 'partner',
            content: content,
            messageType: messageType,
            readBy: [],
            createdAt: DateTime.now(),
          );
          
          // Add optimistic message
          final optimisticExists = _messages.any((msg) => 
              msg.content == content && 
              msg.senderId == userId &&
              msg.createdAt.difference(optimisticMessage.createdAt).abs().inSeconds < 2);
          
          if (!optimisticExists) {
            _messages.add(optimisticMessage);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
            debugPrint('SocketChatService: ✅ Added optimistic message to local list');
          }
          
          return true;
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error sending message: $e');
      
      // FALLBACK: Try WebSocket if API throws exception
      if (_socket != null && _isConnected) {
        debugPrint('SocketChatService: ⚠️ Falling back to WebSocket due to API exception');
        
        try {
          final userId = _currentUserId ?? await TokenService.getUserId();
          if (userId == null) {
            debugPrint('SocketChatService: ❌ No user ID available for WebSocket fallback');
            return false;
          }
          
          final socketMessageData = {
            'roomId': roomId,
            'senderId': userId,
            'senderType': 'partner',
            'content': content,
            'messageType': messageType,
            'timestamp': DateTime.now().toIso8601String(),
          };

          _socket!.emit('send_message', socketMessageData);
          
          // Create optimistic message
          final optimisticMessage = ApiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            roomId: roomId,
            senderId: userId,
            senderType: 'partner',
            content: content,
            messageType: messageType,
            readBy: [],
            createdAt: DateTime.now(),
          );
          
          _messages.add(optimisticMessage);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
          
          return true;
        } catch (socketError) {
          debugPrint('SocketChatService: ❌ WebSocket fallback also failed: $socketError');
          return false;
        }
      }
      
      return false;
    }
  }

  Future<void> loadChatHistory(String roomId) async {
    if (_isDisposed) return;
    
    try {
      final token = _token ?? await TokenService.getToken();
      
      if (token == null) {
        debugPrint('SocketChatService: ❌ No token found for loading chat history');
        return;
      }

      final url = Uri.parse('${baseUrl}chat/history/$roomId?limit=100');
      
      debugPrint('SocketChatService: 📚 Loading chat history from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('SocketChatService: 📊 Chat history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseBody = response.body;
          debugPrint('SocketChatService: 📊 Raw response: $responseBody');
          
          final dynamic responseData = jsonDecode(responseBody);
          
          List<dynamic> historyData;
          
          // Handle different response formats
          if (responseData is List) {
            historyData = responseData;
          } else if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('data') && responseData['data'] is List) {
              historyData = responseData['data'];
            } else if (responseData.containsKey('messages') && responseData['messages'] is List) {
              historyData = responseData['messages'];
            } else {
              debugPrint('SocketChatService: ❌ Unexpected response format: $responseData');
              historyData = [];
            }
          } else {
            debugPrint('SocketChatService: ❌ Unknown response type: ${responseData.runtimeType}');
            historyData = [];
          }
          
          _messages = historyData
              .map((messageJson) {
                try {
                  return ApiChatMessage.fromJson(messageJson as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('SocketChatService: ❌ Error parsing message: $e');
                  debugPrint('SocketChatService: ❌ Message data: $messageJson');
                  return null;
                }
              })
              .where((message) => message != null)
              .cast<ApiChatMessage>()
              .toList();
          
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Track all existing message IDs to avoid duplicates
          for (final msg in _messages) {
            if (msg.isFromCurrentUser(_currentUserId)) {
              _sentMessageIds.add(msg.id);
            }
          }
          
          debugPrint('SocketChatService: ✅ Loaded ${_messages.length} messages from history');
          debugPrint('SocketChatService: 📋 Tracking ${_sentMessageIds.length} sent message IDs');
          
          // Debug: Print read status for messages
          for (int i = 0; i < _messages.length; i++) {
            final msg = _messages[i];
            final isFromCurrentUser = msg.isFromCurrentUser(_currentUserId);
            final isRead = msg.isReadByOthers(msg.senderId);
            debugPrint('SocketChatService: Message $i - "${msg.content}" - From current user: $isFromCurrentUser - Read: $isRead');
          }
          
          if (!_isDisposed) {
            notifyListeners();
          }
        } catch (parseError) {
          debugPrint('SocketChatService: ❌ Error parsing chat history: $parseError');
          debugPrint('SocketChatService: ❌ Response body: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        // No chat history exists yet, start with empty list
        _messages = [];
        _sentMessageIds.clear();
        debugPrint('SocketChatService: 📝 No chat history found, starting fresh');
        if (!_isDisposed) {
          notifyListeners();
        }
      } else {
        debugPrint('SocketChatService: ❌ Failed to load chat history: ${response.statusCode}');
        debugPrint('SocketChatService: ❌ Response body: ${response.body}');
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error loading chat history: $e');
    }
  }

  // Typing indicators
  void sendTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing', {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      });
      debugPrint('SocketChatService: ⌨️ Typing indicator sent');
    }
  }

  void sendStopTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop_typing', {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      });
      debugPrint('SocketChatService: ⌨️ Stop typing indicator sent');
    }
  }

  // NEW: Mark as read via Socket.IO (PRIMARY METHOD)
  void markAsReadViaSocket(String roomId) {
    if (_socket != null && _isConnected) {
      final markAsReadData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      debugPrint('SocketChatService: 📖 Sending mark_as_read via socket: $markAsReadData');
      _socket!.emit('mark_as_read', markAsReadData);
    } else {
      debugPrint('SocketChatService: ❌ Cannot mark as read via socket - not connected');
    }
  }

  // HYBRID: Mark messages as read (Socket first, API fallback)
  Future<bool> markAsRead(String roomId) async {
    if (_isDisposed) return false;
    
    try {
      // PRIMARY: Try socket first for real-time updates
      if (_isConnected) {
        markAsReadViaSocket(roomId);
        debugPrint('SocketChatService: ✅ Mark as read sent via socket');
        
        // Also call API as backup for persistence
        await _markAsReadViaAPI(roomId);
        return true;
      } else {
        // FALLBACK: Use API if socket not connected
        debugPrint('SocketChatService: 🔄 Socket not connected, using API fallback');
        return await _markAsReadViaAPI(roomId);
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error in mark as read: $e');
      return false;
    }
  }

  // API Fallback method
  Future<bool> _markAsReadViaAPI(String roomId) async {
    try {
      final token = _token ?? await TokenService.getToken();
      final userId = _currentUserId ?? await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('SocketChatService: ❌ No token or user ID for mark as read API');
        return false;
      }

      final url = Uri.parse('${baseUrl}chat/read');
      
      final requestBody = {
        'roomId': roomId,
        'userId': userId,
      };
      
      debugPrint('SocketChatService: 📖 Marking messages as read via API...');
      debugPrint('SocketChatService: 📖 Request body: $requestBody');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      debugPrint('SocketChatService: 📖 Mark as read API response: ${response.statusCode}');
      debugPrint('SocketChatService: 📖 Mark as read API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;
        
        if (success) {
          debugPrint('SocketChatService: ✅ Messages marked as read via API');
          return true;
        }
      }
      
      debugPrint('SocketChatService: ❌ Failed to mark messages as read via API: ${response.statusCode}');
      return false;
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error marking messages as read via API: $e');
      return false;
    }
  }

  void clearMessages() {
    if (_isDisposed) return;
    
    _messages.clear();
    _sentMessageIds.clear();
    notifyListeners();
  }

  // Force refresh messages manually
  Future<void> refreshMessages() async {
    if (_currentRoomId != null) {
      debugPrint('SocketChatService: 🔄 Force refreshing messages...');
      await loadChatHistory(_currentRoomId!);
    }
  }

  // NEW: Test WebSocket functionality
  Future<bool> testWebSocketConnection() async {
    if (_isDisposed) return false;
    
    try {
      debugPrint('SocketChatService: 🧪 Testing WebSocket connection...');
      
      // Check if socket exists and is connected
      if (_socket == null) {
        debugPrint('SocketChatService: ❌ Socket is null');
        return false;
      }
      
      if (!_socket!.connected) {
        debugPrint('SocketChatService: ❌ Socket is not connected');
        return false;
      }
      
      debugPrint('SocketChatService: ✅ Socket exists and is connected');
      debugPrint('SocketChatService: 🔍 Socket ID: ${_socket!.id}');
      debugPrint('SocketChatService: 🔍 Socket connected: ${_socket!.connected}');
      debugPrint('SocketChatService: 🔍 Current room: $_currentRoomId');
      debugPrint('SocketChatService: 🔍 Message count: ${_messages.length}');
      
      // Send a ping to test connectivity
      _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
      debugPrint('SocketChatService: 📡 Sent ping to test connectivity');
      
      return true;
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error testing WebSocket: $e');
      return false;
    }
  }

  // Get connection status info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'currentRoomId': _currentRoomId,
      'currentUserId': _currentUserId,
      'reconnectAttempts': _reconnectAttempts,
      'messageCount': _messages.length,
      'sentMessageIds': _sentMessageIds.length,
      'socketConnected': _socket?.connected ?? false,
      'socketId': _socket?.id,
      'socketExists': _socket != null,
    };
  }

  // NEW: Connection health check
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    final health = <String, dynamic>{
      'socket': <String, dynamic>{
        'connected': _isConnected,
        'socketExists': _socket != null,
        'socketConnected': _socket?.connected ?? false,
        'socketId': _socket?.id,
      },
      'room': <String, dynamic>{
        'currentRoomId': _currentRoomId,
        'messageCount': _messages.length,
      },
      'reconnection': <String, dynamic>{
        'attempts': _reconnectAttempts,
        'maxAttempts': _maxReconnectAttempts,
      }
    };

    debugPrint('SocketChatService: 🔍 Connection health check: $health');
    return health;
  }

  @override
  void dispose() {
    debugPrint('SocketChatService: 🗑️ Disposing service');
    _isDisposed = true;
    
    // Cancel timers
    _typingTimer?.cancel();
    _reconnectTimer?.cancel();
    _notifyDebounceTimer?.cancel();
    
    // Disconnect socket
    _socket?.disconnect();
    _socket?.dispose();
    
    // Close stream
    _messageStreamController.close();
    
    // Clear tracking
    _sentMessageIds.clear();
    
    super.dispose();
  }

  void _handleConnectionFailure(String reason) {
    debugPrint('SocketChatService: 🚨 Connection failure: $reason');
    _isConnected = false;
    notifyListeners();
    
    if (!_isDisposed && _reconnectAttempts < _maxReconnectAttempts) {
      _handleReconnection();
    }
  }
}

// Alias for backward compatibility with your existing code
typedef PollingChatService = SocketChatService;