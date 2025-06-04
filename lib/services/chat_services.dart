// lib/services/chat_services.dart - FIXED VERSION FOR REAL-TIME MESSAGES

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import 'token_service.dart';

class ApiChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<String> readBy;
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
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper method to check if this message is from the current user
  bool isFromCurrentUser(String? currentUserId) {
    return senderId == currentUserId;
  }
}

class ChatService extends ChangeNotifier {
  io.Socket? _socket;
  final String _serverUrl = "https://api.bird.delivery/";
  
  List<ApiChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isTyping = false;
  String? _currentRoomId;
  String? _currentUserId;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  bool _isDisposed = false;
  bool _isConnecting = false;

  // Add a stream controller for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;
  String? get currentUserId => _currentUserId;
  
  // Stream for real-time message updates
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;

  ChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _currentUserId = await TokenService.getUserId();
      debugPrint('ChatService: User ID retrieved: $_currentUserId');
    } catch (e) {
      debugPrint('ChatService: Error getting user ID: $e');
    }
    
    _initSocket();
  }

  void _initSocket() {
    if (_isDisposed || _isConnecting) return;
    
    try {
      _socket?.dispose();
      
      debugPrint('ChatService: Initializing socket to $_serverUrl');
      
      _socket = io.io(
        _serverUrl,
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': false,
          'timeout': 10000,
          'reconnection': true,
          'reconnectionAttempts': 3,
          'reconnectionDelay': 2000,
          'reconnectionDelayMax': 10000,
          'maxReconnectionAttempts': 5,
          'randomizationFactor': 0.5,
          'forceNew': true,
        },
      );

      _setupSocketListeners();
    } catch (e) {
      debugPrint('ChatService: Error initializing socket: $e');
      _scheduleReconnect();
    }
  }

  void _setupSocketListeners() {
    if (_socket == null || _isDisposed) return;

    _socket!.onConnect((_) {
      debugPrint('ChatService: Socket connected successfully');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _connectionTimeoutTimer?.cancel();
      
      _authenticateConnection();
      
      if (_currentRoomId != null && _currentUserId != null) {
        _rejoinRoom();
      }
      
      if (!_isDisposed) {
        notifyListeners();
      }
    });

    _socket!.onConnectError((error) {
      debugPrint('ChatService: Socket connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      if (!_isDisposed) {
        notifyListeners();
        _scheduleReconnect();
      }
    });

    _socket!.onError((error) {
      debugPrint('ChatService: Socket error: $error');
      _isConnected = false;
      _isConnecting = false;
      if (!_isDisposed) {
        notifyListeners();
        _scheduleReconnect();
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('ChatService: Socket disconnected - reason: $reason');
      _isConnected = false;
      _isConnecting = false;
      _connectionTimeoutTimer?.cancel();
      
      if (!_isDisposed) {
        notifyListeners();
        if (reason != 'io client disconnect' && reason != 'client namespace disconnect') {
          _scheduleReconnect();
        }
      }
    });

    // CRITICAL: Enhanced message handlers for real-time updates
    _socket!.on('receive_message', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: 🔥 Received real-time message: $data');
      
      if (data != null) {
        try {
          // Handle both single message and message object formats
          Map<String, dynamic> messageData;
          if (data is Map<String, dynamic>) {
            messageData = data;
          } else if (data is String) {
            messageData = jsonDecode(data);
          } else {
            debugPrint('ChatService: Unknown message format: ${data.runtimeType}');
            return;
          }
          
          final message = ApiChatMessage.fromJson(messageData);
          debugPrint('ChatService: ✅ Parsed incoming message from ${message.senderType}: ${message.content}');
          
          // Add message and notify listeners immediately
          _addMessage(message);
          
          // Also emit to stream for immediate UI updates
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message);
          }
          
        } catch (e) {
          debugPrint('ChatService: ❌ Error parsing received message: $e');
          debugPrint('ChatService: Raw data: $data');
        }
      }
    });

    // Handle different possible message event names
    _socket!.on('message', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: 📨 Received message via "message" event: $data');
      _handleIncomingMessage(data);
    });

    _socket!.on('new_message', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: 📨 Received message via "new_message" event: $data');
      _handleIncomingMessage(data);
    });

    _socket!.on('chat_message', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: 📨 Received message via "chat_message" event: $data');
      _handleIncomingMessage(data);
    });

    // Typing indicators
    _socket!.on('user_typing', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: User typing: $data');
      if (data != null) {
        try {
          final userId = data['userId'] ?? data['senderId'];
          if (userId != null && userId != _currentUserId) {
            _isTyping = true;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('ChatService: Error handling typing event: $e');
        }
      }
    });

    _socket!.on('user_stop_typing', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: User stopped typing: $data');
      _isTyping = false;
      notifyListeners();
    });

    // Authentication and room events
    _socket!.on('authenticated', (data) {
      debugPrint('ChatService: Authentication successful: $data');
    });

    _socket!.on('authentication_error', (data) {
      debugPrint('ChatService: Authentication failed: $data');
    });

    _socket!.on('joined_room', (data) {
      debugPrint('ChatService: Successfully joined room: $data');
    });

    _socket!.on('left_room', (data) {
      debugPrint('ChatService: Left room: $data');
    });

    // Add error handling for message sending
    _socket!.on('message_error', (data) {
      debugPrint('ChatService: Message sending error: $data');
    });

    _socket!.on('message_sent', (data) {
      debugPrint('ChatService: Message sent confirmation: $data');
    });
  }

  void _handleIncomingMessage(dynamic data) {
    if (data == null) return;
    
    try {
      Map<String, dynamic> messageData;
      if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is String) {
        messageData = jsonDecode(data);
      } else {
        debugPrint('ChatService: Unsupported message format: ${data.runtimeType}');
        return;
      }
      
      final message = ApiChatMessage.fromJson(messageData);
      debugPrint('ChatService: 🚀 Processing incoming message from ${message.senderType}: ${message.content}');
      
      // Only process messages that are not from current user
      if (message.senderId != _currentUserId) {
        _addMessage(message);
        
        // Emit to stream for immediate UI updates
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
      } else {
        debugPrint('ChatService: Ignoring own message');
      }
      
    } catch (e) {
      debugPrint('ChatService: Error handling incoming message: $e');
    }
  }

  Future<void> _authenticateConnection() async {
    try {
      final token = await TokenService.getToken();
      if (token != null && _socket?.connected == true) {
        debugPrint('ChatService: Authenticating socket connection');
        _socket!.emit('authenticate', {
          'token': token,
          'userId': _currentUserId,
          'userType': 'partner'
        });
      }
    } catch (e) {
      debugPrint('ChatService: Error authenticating connection: $e');
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('ChatService: Max reconnection attempts reached or service disposed');
      return;
    }
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 << _reconnectAttempts).clamp(2, 30));
    
    debugPrint('ChatService: Scheduling reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1}/$maxReconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        _reconnectAttempts++;
        debugPrint('ChatService: Attempting reconnect $_reconnectAttempts/$maxReconnectAttempts');
        _initSocket();
        connect();
      }
    });
  }

  Future<void> connect() async {
    if (_isDisposed || _isConnecting) return;
    
    try {
      _isConnecting = true;
      
      if (_socket == null) {
        await _initializeService();
      }
      
      if (_socket != null && !_socket!.connected) {
        debugPrint('ChatService: Attempting to connect socket...');
        
        _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
          if (_isConnecting && !_isConnected) {
            debugPrint('ChatService: Connection timeout');
            _isConnecting = false;
            _socket?.disconnect();
            _scheduleReconnect();
          }
        });
        
        _socket!.connect();
      } else if (_socket?.connected == true) {
        debugPrint('ChatService: Socket already connected');
        _isConnected = true;
        _isConnecting = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatService: Error connecting socket: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void disconnect() {
    debugPrint('ChatService: Disconnecting socket...');
    _reconnectTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    _isConnecting = false;
    
    if (_currentRoomId != null && _socket?.connected == true) {
      leaveRoom(_currentRoomId!);
    }
    
    if (_socket?.connected == true) {
      _socket!.disconnect();
    }
    
    _isConnected = false;
    notifyListeners();
  }

  Future<void> joinRoom(String roomId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('ChatService: 🏠 Joining room: $roomId');
      
      if (_currentUserId == null) {
        _currentUserId = await TokenService.getUserId();
      }
      
      _currentRoomId = roomId;
      
      // Load chat history first
      await loadChatHistory(roomId);
      
      // Connect socket if not connected
      if (!_isConnected && !_isConnecting) {
        connect();
      }
      
      // Join room via socket if connected
      if (_socket?.connected == true && _currentUserId != null) {
        debugPrint('ChatService: 📡 Emitting join_room event for room: $roomId');
        _socket!.emit('join_room', {
          'roomId': roomId,
          'userId': _currentUserId,
          'userType': 'partner'
        });
        
        // Also try alternative event names that the server might be listening for
        _socket!.emit('joinRoom', {
          'roomId': roomId,
          'userId': _currentUserId,
          'userType': 'partner'
        });
        
      } else {
        debugPrint('ChatService: Socket not connected, will join room when connection is established');
      }
    } catch (e) {
      debugPrint('ChatService: Error joining room: $e');
    }
  }

  void _rejoinRoom() {
    if (_currentRoomId != null && _currentUserId != null && _socket?.connected == true) {
      debugPrint('ChatService: 🔄 Rejoining room: $_currentRoomId');
      _socket!.emit('join_room', {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'userType': 'partner'
      });
      
      // Try alternative event name
      _socket!.emit('joinRoom', {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'userType': 'partner'
      });
    }
  }

  void leaveRoom(String roomId) {
    if (_socket?.connected == true) {
      debugPrint('ChatService: 👋 Leaving room: $roomId');
      _socket!.emit('leave_room', {
        'roomId': roomId,
        'userId': _currentUserId,
      });
      
      // Try alternative event name
      _socket!.emit('leaveRoom', {
        'roomId': roomId,
        'userId': _currentUserId,
      });
    }
    _currentRoomId = null;
  }

  Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
    if (_isDisposed) return false;
    
    try {
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('ChatService: No token or user ID found');
        return false;
      }

      final messageData = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'partner',
        'content': content,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('ChatService: 📤 Sending message: $content');

      // 1. First, try to send via socket for immediate delivery
      bool socketSent = false;
      if (_socket?.connected == true) {
        try {
          _socket!.emit('send_message', messageData);
          _socket!.emit('sendMessage', messageData); // Try alternative event name
          socketSent = true;
          debugPrint('ChatService: ✅ Message sent via socket');
        } catch (e) {
          debugPrint('ChatService: ❌ Socket send failed: $e');
        }
      }

      // 2. Also send via HTTP API for persistence
      try {
        final url = Uri.parse('${ApiConstants.baseUrl}/chat/message');
        
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(messageData),
        ).timeout(const Duration(seconds: 10));

        debugPrint('ChatService: HTTP send response: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          
          // Add the message to local list if not already present
          if (!_messages.any((m) => m.content == content && m.senderId == userId)) {
            final message = ApiChatMessage.fromJson(responseData);
            _addMessage(message);
          }
          
          return true;
        }
      } catch (e) {
        debugPrint('ChatService: HTTP send failed: $e');
      }

      // If socket sent successfully, consider it a success even if HTTP failed
      return socketSent;
      
    } catch (e) {
      debugPrint('ChatService: Error sending message: $e');
      return false;
    }
  }

  Future<void> loadChatHistory(String roomId) async {
    if (_isDisposed) return;
    
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('ChatService: No token found for loading chat history');
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/chat/history/$roomId');
      
      debugPrint('ChatService: 📚 Loading chat history from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('ChatService: Chat history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        _messages = historyData
            .map((messageJson) => ApiChatMessage.fromJson(messageJson))
            .toList();
        
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('ChatService: ✅ Loaded ${_messages.length} messages from history');
        if (!_isDisposed) {
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        // No chat history exists yet, start with empty list
        _messages = [];
        debugPrint('ChatService: No chat history found, starting fresh');
        if (!_isDisposed) {
          notifyListeners();
        }
      } else {
        debugPrint('ChatService: Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService: Error loading chat history: $e');
    }
  }

  void sendTyping(String roomId) {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket!.emit('typing', {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      });
    }
  }

  void sendStopTyping(String roomId) {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket!.emit('stop_typing', {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      });
    }
  }

  void _addMessage(ApiChatMessage message) {
    if (_isDisposed) return;
    
    // Check if message already exists to avoid duplicates
    final existingIndex = _messages.indexWhere((m) => 
      m.id == message.id || 
      (m.content == message.content && 
       m.senderId == message.senderId && 
       m.createdAt.difference(message.createdAt).abs().inSeconds < 5));
    
    if (existingIndex == -1) {
      _messages.add(message);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      debugPrint('ChatService: ➕ Added new message from ${message.senderType}: ${message.content}');
      debugPrint('ChatService: Total messages: ${_messages.length}');
      
      notifyListeners();
    } else {
      debugPrint('ChatService: 🔄 Message already exists, skipping duplicate');
    }
  }

  void clearMessages() {
    if (_isDisposed) return;
    
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('ChatService: 🗑️ Disposing service');
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    disconnect();
    _socket?.dispose();
    _messageStreamController.close();
    super.dispose();
  }
}