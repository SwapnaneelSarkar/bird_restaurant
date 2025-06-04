// lib/services/chat_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
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
  late io.Socket _socket;
  final String _serverUrl = ApiConstants.baseUrl.replaceAll('/api', ''); // Remove /api for socket connection
  
  List<ApiChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isTyping = false;
  String? _currentRoomId;
  String? _currentUserId;

  List<ApiChatMessage> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;

  ChatService() {
    _initSocket();
  }

  void _initSocket() {
    try {
      _socket = io.io(
        _serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      // Socket event listeners
      _socket.onConnect((_) {
        debugPrint('Socket connected to $_serverUrl');
        _isConnected = true;
        notifyListeners();
      });

      _socket.onConnectError((data) {
        debugPrint('Socket Connect Error: $data');
        _isConnected = false;
        notifyListeners();
      });

      _socket.onDisconnect((_) {
        debugPrint('Socket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _socket.on('receive_message', (data) {
        debugPrint('Received message: $data');
        if (data != null) {
          try {
            final message = ApiChatMessage.fromJson(data);
            _addMessage(message);
          } catch (e) {
            debugPrint('Error parsing received message: $e');
          }
        }
      });

      _socket.on('user_typing', (data) {
        debugPrint('User typing: $data');
        if (data != null && data['userId'] != _currentUserId) {
          _isTyping = true;
          notifyListeners();
        }
      });

      _socket.on('user_stop_typing', (data) {
        debugPrint('User stopped typing: $data');
        _isTyping = false;
        notifyListeners();
      });

    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  Future<void> connect() async {
    if (!_socket.connected) {
      debugPrint('Attempting to connect socket...');
      _socket.connect();
    }
  }

  void disconnect() {
    if (_socket.connected) {
      debugPrint('Disconnecting socket...');
      if (_currentRoomId != null) {
        leaveRoom(_currentRoomId!);
      }
      _socket.disconnect();
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      _currentUserId = await TokenService.getUserId();
      _currentRoomId = roomId;
      
      if (_socket.connected && _currentUserId != null) {
        debugPrint('Joining room: $roomId');
        _socket.emit('join_room', {
          'roomId': roomId,
          'userId': _currentUserId,
          'userType': 'partner'
        });
        
        // Load chat history when joining room
        await loadChatHistory(roomId);
      }
    } catch (e) {
      debugPrint('Error joining room: $e');
    }
  }

  void leaveRoom(String roomId) {
    if (_socket.connected) {
      debugPrint('Leaving room: $roomId');
      _socket.emit('leave_room', roomId);
      _currentRoomId = null;
    }
  }

  Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
    try {
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('No token or user ID found');
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

      debugPrint('Sending message: $messageData');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageData),
      );

      debugPrint('Send message response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final message = ApiChatMessage.fromJson(responseData);
        
        // Add message to local list
        _addMessage(message);
        
        // Also emit via socket for real-time updates
        if (_socket.connected) {
          _socket.emit('send_message', messageData);
        }
        
        return true;
      } else {
        debugPrint('Failed to send message: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<void> loadChatHistory(String roomId) async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('No token found for loading chat history');
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/chat/history/$roomId');
      
      debugPrint('Loading chat history from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Chat history response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        _messages = historyData
            .map((messageJson) => ApiChatMessage.fromJson(messageJson))
            .toList();
        
        // Sort messages by creation time
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('Loaded ${_messages.length} messages from history');
        notifyListeners();
      } else {
        debugPrint('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void sendTyping(String roomId) {
    if (_socket.connected && _currentUserId != null) {
      _socket.emit('typing', {
        'roomId': roomId,
        'userId': _currentUserId,
      });
    }
  }

  void sendStopTyping(String roomId) {
    if (_socket.connected && _currentUserId != null) {
      _socket.emit('stop_typing', {
        'roomId': roomId,
        'userId': _currentUserId,
      });
    }
  }

  void _addMessage(ApiChatMessage message) {
    // Check if message already exists to avoid duplicates
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _socket.dispose();
    debugPrint('Chat service disposed');
    super.dispose();
  }
}