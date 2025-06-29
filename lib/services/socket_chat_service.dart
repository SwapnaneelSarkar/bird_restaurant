// lib/services/socket_chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'token_service.dart';
import 'chat_services.dart';

class SocketChatService extends ChangeNotifier {
  IO.Socket? _socket;
  List<ApiChatMessage> _messages = [];
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  bool _isDisposed = false;

  // Stream controller for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  // Stream controller for read status updates (blue tick)
  final StreamController<Map<String, dynamic>> _readStatusStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get readStatusStream => _readStatusStreamController.stream;

  SocketChatService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _currentUserId = await TokenService.getUserId();
      debugPrint('SocketChatService: 🆔 User ID retrieved: $_currentUserId');
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error getting user ID: $e');
    }
  }

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('SocketChatService: ✅ Already connected');
      return;
    }

    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('SocketChatService: ❌ No token available for connection');
        return;
      }

      debugPrint('SocketChatService: 🔌 Connecting to socket server...');

      _socket = IO.io(
        ApiConstants.baseUrl.replaceFirst('/api', ''), // Remove /api from base URL
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .build(),
      );

      _setupSocketListeners();
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error connecting: $e');
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((data) {
      debugPrint('SocketChatService: ✅ Connected to server');
      _isConnected = true;
      notifyListeners();
    });

    _socket!.onDisconnect((data) {
      debugPrint('SocketChatService: ❌ Disconnected from server');
      _isConnected = false;
      notifyListeners();
    });

    // Chat events
    _socket!.on('receive_message', (data) {
      debugPrint('SocketChatService: 📥 Received message: $data');
      _handleReceivedMessage(data);
    });

    _socket!.on('message_sent', (data) {
      debugPrint('SocketChatService: ✅ Message sent confirmation: $data');
      _handleMessageSent(data);
    });

    // Blue tick functionality - handle message_seen events
    // _socket!.on('message_seen', (data) {
    //   debugPrint('SocketChatService: ✅ Message seen event received: $data');
    //   _handleMessageSeen(data);
    // });

    _socket!.on('user_joined', (data) {
      debugPrint('SocketChatService: 👋 User joined room: $data');
    });

    _socket!.on('user_left', (data) {
      debugPrint('SocketChatService: 👋 User left room: $data');
    });

    // Typing indicators
    _socket!.on('user_typing', (data) {
      debugPrint('SocketChatService: ⌨️ User typing: $data');
      // NEW: When someone starts typing, mark all messages as read and update blue ticks
      if (_currentRoomId != null && _currentUserId != null) {
        _markAllMessagesAsReadForBlueTicks();
      }
    });

    _socket!.on('user_stop_typing', (data) {
      debugPrint('SocketChatService: ⌨️ User stopped typing: $data');
    });

    // Error handling
    _socket!.onError((error) {
      debugPrint('SocketChatService: ❌ Socket error: $error');
    });

    _socket!.onConnectError((error) {
      debugPrint('SocketChatService: ❌ Connection error: $error');
    });
  }

  void _handleReceivedMessage(dynamic data) {
    try {
      final messageData = data is String ? jsonDecode(data) : data;
      final message = ApiChatMessage.fromJson(messageData);
      
      // Check if message already exists to avoid duplicates
      if (!_messages.any((existing) => existing.id == message.id)) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        // Emit to stream for immediate UI updates
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
        
        // NEW: Auto-emit typing when receiving a message on active chat page
        if (_currentRoomId != null) {
          debugPrint('SocketChatService: 🔍 Auto-emission check - Room ID: $_currentRoomId');
          debugPrint('SocketChatService: 🔍 Auto-emission check - Socket ready: ${_socket != null && _socket!.connected}');
          
          sendTyping(_currentRoomId!);
          debugPrint('SocketChatService: ⌨️ Auto-emitted typing for received message');
          
          // Stop typing after 3 seconds
          Timer(const Duration(seconds: 3), () {
            if (_currentRoomId != null) {
              debugPrint('SocketChatService: 🔍 Auto-stop typing check - Room ID: $_currentRoomId');
              sendStopTyping(_currentRoomId!);
              debugPrint('SocketChatService: ⌨️ Auto-stopped typing after received message');
            } else {
              debugPrint('SocketChatService: ⚠️ Cannot auto-stop typing - no current room');
            }
          });
        } else {
          debugPrint('SocketChatService: ⚠️ Cannot auto-emit typing - no current room ID');
        }
        
        // Emit message_seen event immediately when we receive a message
        // This is the key part for blue tick functionality
        // _emitMessageSeen(message);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling received message: $e');
    }
  }

  void _handleMessageSent(dynamic data) {
    try {
      final messageData = data is String ? jsonDecode(data) : data;
      final message = ApiChatMessage.fromJson(messageData);
      
      // Update local message if it exists, or add it
      final existingIndex = _messages.indexWhere((m) => 
        m.content == message.content && 
        m.senderId == message.senderId &&
        m.createdAt.difference(message.createdAt).abs().inSeconds < 5
      );
      
      if (existingIndex != -1) {
        _messages[existingIndex] = message;
      } else {
        _messages.add(message);
      }
      
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error handling sent message: $e');
    }
  }

  // void _handleMessageSeen(dynamic data) {
  //   try {
  //     final messageData = data is String ? jsonDecode(data) : data;
  //     debugPrint('SocketChatService: 🔵 Processing message seen: $messageData');
  //     
  //     final String messageId = messageData['messageId'] ?? '';
  //     final String seenByUserId = messageData['seenByUserId'] ?? '';
  //     final String seenByUserType = messageData['seenByUserType'] ?? '';
  //     final String roomId = messageData['roomId'] ?? '';
  //     
  //     debugPrint('SocketChatService: 🔵 Message ID: $messageId, Seen by: $seenByUserId ($seenByUserType)');
  //     
  //     // Find the message and update its read status
  //     final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
  //     if (messageIndex != -1) {
  //       final message = _messages[messageIndex];
  //       final updatedReadBy = List<ReadByEntry>.from(message.readBy);
  //       
  //       // Check if user is already in readBy list
  //       final existingReadEntry = updatedReadBy.where((entry) => entry.userId == seenByUserId).firstOrNull;
  //       if (existingReadEntry == null) {
  //         // Add new read entry
  //         final newReadEntry = ReadByEntry(
  //           userId: seenByUserId,
  //           readAt: DateTime.now(),
  //           id: DateTime.now().millisecondsSinceEpoch.toString(),
  //         );
  //         updatedReadBy.add(newReadEntry);
  //         
  //         // Create updated message with new read status
  //         final updatedMessage = ApiChatMessage(
  //           id: message.id,
  //           roomId: message.roomId,
  //           senderId: message.senderId,
  //           senderType: message.senderType,
  //           content: message.content,
  //           messageType: message.messageType,
  //           readBy: updatedReadBy,
  //           createdAt: message.createdAt,
  //         );
  //         
  //         // Update the message in the list
  //         _messages[messageIndex] = updatedMessage;
  //         
  //         debugPrint('SocketChatService: 🔵 Updated message read status: ${updatedMessage.readBy.length} readers');
  //         
  //         // Emit to read status stream for UI updates
  //         if (!_readStatusStreamController.isClosed) {
  //           _readStatusStreamController.add({
  //             'messageId': messageId,
  //             'readBy': updatedReadBy.map((entry) => entry.userId).toList(),
  //             'seenByUserId': seenByUserId,
  //             'seenByUserType': seenByUserType,
  //           });
  //         }
  //         
  //         notifyListeners();
  //       }
  //     } else {
  //       debugPrint('SocketChatService: ⚠️ Message not found for ID: $messageId');
  //     }
  //   } catch (e) {
  //     debugPrint('SocketChatService: ❌ Error handling message seen: $e');
  //   }
  // }

  // Public method to manually mark a message as seen
  // void markMessageAsSeen(String messageId, String roomId) {
  //   if (_socket != null && _socket!.connected && _currentUserId != null) {
  //     final messageSeenData = {
  //       'messageId': messageId,
  //       'roomId': roomId,
  //       'seenByUserId': _currentUserId,
  //       'seenByUserType': 'partner',
  //       'timestamp': DateTime.now().toIso8601String(),
  //     };
  //     
  //     debugPrint('SocketChatService: 🔵 Manually marking message as seen: $messageSeenData');
  //     _socket!.emit('message_seen', messageSeenData);
  //   }
  // }

  // NEW: Mark all messages as read for blue ticks
  void _markAllMessagesAsReadForBlueTicks() {
    debugPrint('SocketChatService: 🔵 Starting blue tick update for typing event');
    
    if (_currentRoomId != null && _currentUserId != null) {
      debugPrint('SocketChatService: 🔵 Current room: $_currentRoomId, Current user: $_currentUserId');
      debugPrint('SocketChatService: 🔵 Total messages: ${_messages.length}');
      
      bool hasUpdates = false;
      
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        
        // Only update messages sent by current user (to show blue ticks when others read them)
        if (message.roomId == _currentRoomId && 
            message.senderId == _currentUserId && 
            !message.isRead) {
          
          debugPrint('SocketChatService: 🔵 Updating message ${message.id} for blue tick');
          
          final updatedReadBy = List<ReadByEntry>.from(message.readBy);
          
          // Add a dummy read entry to simulate the message being read
          updatedReadBy.add(ReadByEntry(
            userId: 'typing_user', // Dummy user to indicate someone is typing
            readAt: DateTime.now(),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
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
          
          _messages[i] = updatedMessage;
          hasUpdates = true;
          
          debugPrint('SocketChatService: 🔵 Updated message read status: ${updatedMessage.isRead}');
          debugPrint('SocketChatService: 🔵 Updated readBy count: ${updatedMessage.readBy.length}');
        }
      }
      
      if (hasUpdates) {
        // Emit to read status stream for UI updates
        if (!_readStatusStreamController.isClosed) {
          _readStatusStreamController.add({
            'type': 'typing_blue_tick_update',
            'roomId': _currentRoomId,
            'updatedMessages': _messages.where((m) => m.senderId == _currentUserId && m.isRead).toList(),
          });
          debugPrint('SocketChatService: 📡 Emitted typing blue tick update to stream');
        }
        
        notifyListeners();
        debugPrint('SocketChatService: ✅ Blue tick update completed');
      } else {
        debugPrint('SocketChatService: 🔄 No messages needed blue tick update');
      }
    } else {
      debugPrint('SocketChatService: ❌ Cannot update blue ticks - missing room or user ID');
    }
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
      
      // Leave previous room if any
      if (_currentRoomId != null) {
        leaveRoom(_currentRoomId!);
      }
      
      _currentRoomId = roomId;
      
      // Connect to socket if not connected
      if (_socket == null || !_socket!.connected) {
        await connect();
      }
      
      // Join the room
      _socket?.emit('join_room', {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      });
      
      // Load chat history
      await loadChatHistory(roomId);
      
      debugPrint('SocketChatService: ✅ Successfully joined room');
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error joining room: $e');
    }
  }

  void leaveRoom(String roomId) {
    debugPrint('SocketChatService: 👋 Leaving room: $roomId');
    
    _socket?.emit('leave_room', {
      'roomId': roomId,
      'userId': _currentUserId,
    });
    
    _currentRoomId = null;
  }

  Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
    if (_isDisposed || _socket == null || !_socket!.connected) {
      debugPrint('SocketChatService: ❌ Cannot send message - not connected');
      return false;
    }
    
    try {
      final userId = _currentUserId ?? await TokenService.getUserId();
      
      if (userId == null) {
        debugPrint('SocketChatService: ❌ No user ID found');
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

      debugPrint('SocketChatService: 📤 Sending message: "$content"');
      
      // Emit the message
      _socket!.emit('send_message', messageData);
      
      // Optimistically add to local messages
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
      
      if (!_messages.any((msg) => 
          msg.content == content && 
          msg.senderId == userId &&
          msg.createdAt.difference(optimisticMessage.createdAt).abs().inSeconds < 2)) {
        _messages.add(optimisticMessage);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }
      
      debugPrint('SocketChatService: ✅ Message emitted to socket');
      return true;
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error sending message: $e');
      return false;
    }
  }

  Future<void> loadChatHistory(String roomId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('SocketChatService: 📚 Loading chat history for room: $roomId');
      
      // Emit request for chat history
      _socket?.emit('get_chat_history', {
        'roomId': roomId,
        'limit': 100,
      });
      
      // Listen for chat history response
      _socket?.on('chat_history', (data) {
        try {
          final List<dynamic> historyData = data is List ? data : [];
          
          _messages = historyData
              .map((messageJson) => ApiChatMessage.fromJson(messageJson))
              .toList();
          
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('SocketChatService: ✅ Loaded ${_messages.length} messages from history');
          
          if (!_isDisposed) {
            notifyListeners();
          }
        } catch (e) {
          debugPrint('SocketChatService: ❌ Error processing chat history: $e');
        }
      });
      
    } catch (e) {
      debugPrint('SocketChatService: ❌ Error loading chat history: $e');
    }
  }

  // Typing indicators
  void sendTyping(String roomId) {
    debugPrint('SocketChatService: 🔍 Attempting to send typing event...');
    debugPrint('SocketChatService: 🔍 Socket exists: ${_socket != null}');
    debugPrint('SocketChatService: 🔍 Socket connected: ${_socket?.connected}');
    debugPrint('SocketChatService: 🔍 Current room ID: $_currentRoomId');
    debugPrint('SocketChatService: 🔍 Current user ID: $_currentUserId');
    
    if (_socket != null && _socket!.connected) {
      final typingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      };
      
      debugPrint('SocketChatService: 📡 Emitting typing event: $typingData');
      _socket!.emit('typing', typingData);
      debugPrint('SocketChatService: ⌨️ Typing indicator sent');
    } else {
      debugPrint('SocketChatService: ❌ Cannot send typing - socket not ready');
      debugPrint('SocketChatService: ❌ Socket null: ${_socket == null}');
      debugPrint('SocketChatService: ❌ Socket connected: ${_socket?.connected}');
    }
  }

  void sendStopTyping(String roomId) {
    debugPrint('SocketChatService: 🔍 Attempting to send stop typing event...');
    debugPrint('SocketChatService: 🔍 Socket exists: ${_socket != null}');
    debugPrint('SocketChatService: 🔍 Socket connected: ${_socket?.connected}');
    
    if (_socket != null && _socket!.connected) {
      final stopTypingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'partner',
      };
      
      debugPrint('SocketChatService: 📡 Emitting stop typing event: $stopTypingData');
      _socket!.emit('stop_typing', stopTypingData);
      debugPrint('SocketChatService: ⌨️ Stop typing indicator sent');
    } else {
      debugPrint('SocketChatService: ❌ Cannot send stop typing - socket not ready');
    }
  }

  void clearMessages() {
    if (_isDisposed) return;
    
    _messages.clear();
    notifyListeners();
  }

  void disconnect() {
    debugPrint('SocketChatService: 🔌 Disconnecting from socket server');
    
    if (_currentRoomId != null) {
      leaveRoom(_currentRoomId!);
    }
    
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _currentRoomId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('SocketChatService: 🗑️ Disposing service');
    _isDisposed = true;
    disconnect();
    _messageStreamController.close();
    _readStatusStreamController.close();
    super.dispose();
  }
}