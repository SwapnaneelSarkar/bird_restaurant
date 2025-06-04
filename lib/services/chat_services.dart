// lib/services/chat_service.dart

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
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
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

  List<ApiChatMessage> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;

  ChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Get user token and ID first
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
      // Dispose existing socket if any
      _socket?.dispose();
      
      debugPrint('ChatService: Initializing socket to $_serverUrl');
      
      _socket = io.io(
        _serverUrl,
        <String, dynamic>{
          'transports': ['websocket', 'polling'], // Allow fallback to polling
          'autoConnect': false,
          'timeout': 10000, // Reduced timeout
          'reconnection': true,
          'reconnectionAttempts': 3,
          'reconnectionDelay': 2000,
          'reconnectionDelayMax': 10000,
          'maxReconnectionAttempts': 5,
          'randomizationFactor': 0.5,
          'forceNew': true, // Force new connection
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
      debugPrint('ChatService: Socket connected successfully to $_serverUrl');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _connectionTimeoutTimer?.cancel();
      
      // Authenticate the connection
      _authenticateConnection();
      
      // Rejoin room if we were in one
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
        // Only attempt reconnect if it wasn't a manual disconnect
        if (reason != 'io client disconnect' && reason != 'client namespace disconnect') {
          _scheduleReconnect();
        }
      }
    });

    // Message handlers
    _socket!.on('receive_message', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: Received message: $data');
      if (data != null) {
        try {
          final message = ApiChatMessage.fromJson(data);
          _addMessage(message);
        } catch (e) {
          debugPrint('ChatService: Error parsing received message: $e');
        }
      }
    });

    _socket!.on('user_typing', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: User typing: $data');
      if (data != null && data['userId'] != _currentUserId) {
        _isTyping = true;
        notifyListeners();
      }
    });

    _socket!.on('user_stop_typing', (data) {
      if (_isDisposed) return;
      debugPrint('ChatService: User stopped typing: $data');
      _isTyping = false;
      notifyListeners();
    });

    // Authentication response
    _socket!.on('authenticated', (data) {
      debugPrint('ChatService: Authentication successful: $data');
    });

    _socket!.on('authentication_error', (data) {
      debugPrint('ChatService: Authentication failed: $data');
    });

    // Room events
    _socket!.on('joined_room', (data) {
      debugPrint('ChatService: Successfully joined room: $data');
    });

    _socket!.on('left_room', (data) {
      debugPrint('ChatService: Left room: $data');
    });
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
        
        // Set connection timeout
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
      debugPrint('ChatService: Joining room: $roomId');
      
      // Ensure we have user ID
      if (_currentUserId == null) {
        _currentUserId = await TokenService.getUserId();
      }
      
      _currentRoomId = roomId;
      
      // Always load chat history first, regardless of socket connection
      await loadChatHistory(roomId);
      
      // Try to connect socket if not connected
      if (!_isConnected && !_isConnecting) {
        connect(); // Don't await this, let it connect in background
      }
      
      // If socket is connected, join the room
      if (_socket?.connected == true && _currentUserId != null) {
        debugPrint('ChatService: Emitting join_room event');
        _socket!.emit('join_room', {
          'roomId': roomId,
          'userId': _currentUserId,
          'userType': 'partner'
        });
      } else {
        debugPrint('ChatService: Socket not connected, room will be joined when connection is established');
      }
    } catch (e) {
      debugPrint('ChatService: Error joining room: $e');
    }
  }

  void _rejoinRoom() {
    if (_currentRoomId != null && _currentUserId != null && _socket?.connected == true) {
      debugPrint('ChatService: Rejoining room: $_currentRoomId');
      _socket!.emit('join_room', {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'userType': 'partner'
      });
    }
  }

  void leaveRoom(String roomId) {
    if (_socket?.connected == true) {
      debugPrint('ChatService: Leaving room: $roomId');
      _socket!.emit('leave_room', {
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

      final url = Uri.parse('${ApiConstants.baseUrl}/chat/message');
      
      final messageData = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'partner',
        'content': content,
        'messageType': messageType,
      };

      debugPrint('ChatService: Sending message via HTTP: $messageData');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('ChatService: Send message response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Only add message if it's not already in the list
        if (!_messages.any((m) => m.id == responseData['_id'])) {
          final message = ApiChatMessage.fromJson(responseData);
          _addMessage(message);
        }
        
        // Emit via socket for real-time updates to other users
        if (_socket?.connected == true) {
          debugPrint('ChatService: Broadcasting message via socket');
          _socket!.emit('send_message', messageData);
        } else {
          debugPrint('ChatService: Socket not connected, message sent via HTTP only');
        }
        
        return true;
      } else {
        debugPrint('ChatService: Failed to send message: ${response.statusCode}');
        return false;
      }
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
      
      debugPrint('ChatService: Loading chat history from: $url');

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
        
        // Sort messages by creation time
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('ChatService: Loaded ${_messages.length} messages from history');
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
      });
    }
  }

  void sendStopTyping(String roomId) {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket!.emit('stop_typing', {
        'roomId': roomId,
        'userId': _currentUserId,
      });
    }
  }

  void _addMessage(ApiChatMessage message) {
    if (_isDisposed) return;
    
    // Check if message already exists to avoid duplicates
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      debugPrint('ChatService: Added new message: ${message.content}');
      notifyListeners();
    }
  }

  void clearMessages() {
    if (_isDisposed) return;
    
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('ChatService: Disposing service');
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    disconnect();
    _socket?.dispose();
    super.dispose();
  }
}