// // lib/services/socket_chat_service.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import '../constants/api_constants.dart';
// import 'token_service.dart';
// import 'chat_services.dart';

// class SocketChatService extends ChangeNotifier {
//   IO.Socket? _socket;
//   List<ApiChatMessage> _messages = [];
//   bool _isConnected = false;
//   String? _currentRoomId;
//   String? _currentUserId;
//   bool _isDisposed = false;

//   // Stream controller for real-time message updates
//   final StreamController<ApiChatMessage> _messageStreamController = 
//       StreamController<ApiChatMessage>.broadcast();
  
//   List<ApiChatMessage> get messages => List.unmodifiable(_messages);
//   bool get isConnected => _isConnected;
//   String? get currentUserId => _currentUserId;
  
//   Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;

//   SocketChatService() {
//     _initializeService();
//   }

//   Future<void> _initializeService() async {
//     try {
//       _currentUserId = await TokenService.getUserId();
//       debugPrint('SocketChatService: 🆔 User ID retrieved: $_currentUserId');
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error getting user ID: $e');
//     }
//   }

//   Future<void> connect() async {
//     if (_socket != null && _socket!.connected) {
//       debugPrint('SocketChatService: ✅ Already connected');
//       return;
//     }

//     try {
//       final token = await TokenService.getToken();
//       if (token == null) {
//         debugPrint('SocketChatService: ❌ No token available for connection');
//         return;
//       }

//       debugPrint('SocketChatService: 🔌 Connecting to socket server...');

//       _socket = IO.io(
//         ApiConstants.baseUrl.replaceFirst('/api', ''), // Remove /api from base URL
//         IO.OptionBuilder()
//             .setTransports(['websocket'])
//             .setAuth({'token': token})
//             .setExtraHeaders({'Authorization': 'Bearer $token'})
//             .enableAutoConnect()
//             .build(),
//       );

//       _setupSocketListeners();
      
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error connecting: $e');
//     }
//   }

//   void _setupSocketListeners() {
//     if (_socket == null) return;

//     // Connection events
//     _socket!.onConnect((data) {
//       debugPrint('SocketChatService: ✅ Connected to server');
//       _isConnected = true;
//       notifyListeners();
//     });

//     _socket!.onDisconnect((data) {
//       debugPrint('SocketChatService: ❌ Disconnected from server');
//       _isConnected = false;
//       notifyListeners();
//     });

//     // Chat events
//     _socket!.on('receive_message', (data) {
//       debugPrint('SocketChatService: 📥 Received message: $data');
//       _handleReceivedMessage(data);
//     });

//     _socket!.on('message_sent', (data) {
//       debugPrint('SocketChatService: ✅ Message sent confirmation: $data');
//       _handleMessageSent(data);
//     });

//     _socket!.on('user_joined', (data) {
//       debugPrint('SocketChatService: 👋 User joined room: $data');
//     });

//     _socket!.on('user_left', (data) {
//       debugPrint('SocketChatService: 👋 User left room: $data');
//     });

//     _socket!.on('typing', (data) {
//       debugPrint('SocketChatService: ⌨️ User typing: $data');
//       // Handle typing indicator
//     });

//     _socket!.on('stop_typing', (data) {
//       debugPrint('SocketChatService: ⌨️ User stopped typing: $data');
//       // Handle stop typing indicator
//     });

//     // Error handling
//     _socket!.onError((error) {
//       debugPrint('SocketChatService: ❌ Socket error: $error');
//     });

//     _socket!.onConnectError((error) {
//       debugPrint('SocketChatService: ❌ Connection error: $error');
//     });
//   }

//   void _handleReceivedMessage(dynamic data) {
//     try {
//       final messageData = data is String ? jsonDecode(data) : data;
//       final message = ApiChatMessage.fromJson(messageData);
      
//       // Check if message already exists to avoid duplicates
//       if (!_messages.any((existing) => existing.id == message.id)) {
//         _messages.add(message);
//         _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
//         // Emit to stream for immediate UI updates
//         if (!_messageStreamController.isClosed) {
//           _messageStreamController.add(message);
//         }
        
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error handling received message: $e');
//     }
//   }

//   void _handleMessageSent(dynamic data) {
//     try {
//       final messageData = data is String ? jsonDecode(data) : data;
//       final message = ApiChatMessage.fromJson(messageData);
      
//       // Update local message if it exists, or add it
//       final existingIndex = _messages.indexWhere((m) => 
//         m.content == message.content && 
//         m.senderId == message.senderId &&
//         m.createdAt.difference(message.createdAt).abs().inSeconds < 5
//       );
      
//       if (existingIndex != -1) {
//         _messages[existingIndex] = message;
//       } else {
//         _messages.add(message);
//       }
      
//       _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//       notifyListeners();
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error handling sent message: $e');
//     }
//   }

//   Future<void> joinRoom(String roomId) async {
//     if (_isDisposed) return;
    
//     try {
//       debugPrint('SocketChatService: 🏠 Joining room: $roomId');
      
//       // Ensure we have current user ID
//       if (_currentUserId == null) {
//         _currentUserId = await TokenService.getUserId();
//         debugPrint('SocketChatService: 🆔 Retrieved user ID: $_currentUserId');
//       }
      
//       // Leave previous room if any
//       if (_currentRoomId != null) {
//         leaveRoom(_currentRoomId!);
//       }
      
//       _currentRoomId = roomId;
      
//       // Connect to socket if not connected
//       if (_socket == null || !_socket!.connected) {
//         await connect();
//       }
      
//       // Join the room
//       _socket?.emit('join_room', {
//         'roomId': roomId,
//         'userId': _currentUserId,
//         'userType': 'partner',
//       });
      
//       // Load chat history
//       await loadChatHistory(roomId);
      
//       debugPrint('SocketChatService: ✅ Successfully joined room');
      
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error joining room: $e');
//     }
//   }

//   void leaveRoom(String roomId) {
//     debugPrint('SocketChatService: 👋 Leaving room: $roomId');
    
//     _socket?.emit('leave_room', {
//       'roomId': roomId,
//       'userId': _currentUserId,
//     });
    
//     _currentRoomId = null;
//   }

//   Future<bool> sendMessage(String roomId, String content, {String messageType = 'text'}) async {
//     if (_isDisposed || _socket == null || !_socket!.connected) {
//       debugPrint('SocketChatService: ❌ Cannot send message - not connected');
//       return false;
//     }
    
//     try {
//       final userId = _currentUserId ?? await TokenService.getUserId();
      
//       if (userId == null) {
//         debugPrint('SocketChatService: ❌ No user ID found');
//         return false;
//       }

//       final messageData = {
//         'roomId': roomId,
//         'senderId': userId,
//         'senderType': 'partner',
//         'content': content,
//         'messageType': messageType,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       debugPrint('SocketChatService: 📤 Sending message: "$content"');
      
//       // Emit the message
//       _socket!.emit('send_message', messageData);
      
//       // Optimistically add to local messages
//       final optimisticMessage = ApiChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         roomId: roomId,
//         senderId: userId,
//         senderType: 'partner',
//         content: content,
//         messageType: messageType,
//         readBy: [],
//         createdAt: DateTime.now(),
//       );
      
//       if (!_messages.any((msg) => 
//           msg.content == content && 
//           msg.senderId == userId &&
//           msg.createdAt.difference(optimisticMessage.createdAt).abs().inSeconds < 2)) {
//         _messages.add(optimisticMessage);
//         _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//         notifyListeners();
//       }
      
//       debugPrint('SocketChatService: ✅ Message emitted to socket');
//       return true;
      
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error sending message: $e');
//       return false;
//     }
//   }

//   Future<void> loadChatHistory(String roomId) async {
//     if (_isDisposed) return;
    
//     try {
//       debugPrint('SocketChatService: 📚 Loading chat history for room: $roomId');
      
//       // Emit request for chat history
//       _socket?.emit('get_chat_history', {
//         'roomId': roomId,
//         'limit': 100,
//       });
      
//       // Listen for chat history response
//       _socket?.on('chat_history', (data) {
//         try {
//           final List<dynamic> historyData = data is List ? data : [];
          
//           _messages = historyData
//               .map((messageJson) => ApiChatMessage.fromJson(messageJson))
//               .toList();
          
//           _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
//           debugPrint('SocketChatService: ✅ Loaded ${_messages.length} messages from history');
          
//           if (!_isDisposed) {
//             notifyListeners();
//           }
//         } catch (e) {
//           debugPrint('SocketChatService: ❌ Error processing chat history: $e');
//         }
//       });
      
//     } catch (e) {
//       debugPrint('SocketChatService: ❌ Error loading chat history: $e');
//     }
//   }

//   // Typing indicators
//   void sendTyping(String roomId) {
//     if (_socket != null && _socket!.connected) {
//       _socket!.emit('typing', {
//         'roomId': roomId,
//         'userId': _currentUserId,
//         'userType': 'partner',
//       });
//       debugPrint('SocketChatService: ⌨️ Typing indicator sent');
//     }
//   }

//   void sendStopTyping(String roomId) {
//     if (_socket != null && _socket!.connected) {
//       _socket!.emit('stop_typing', {
//         'roomId': roomId,
//         'userId': _currentUserId,
//         'userType': 'partner',
//       });
//       debugPrint('SocketChatService: ⌨️ Stop typing indicator sent');
//     }
//   }

//   void clearMessages() {
//     if (_isDisposed) return;
    
//     _messages.clear();
//     notifyListeners();
//   }

//   void disconnect() {
//     debugPrint('SocketChatService: 🔌 Disconnecting from socket server');
    
//     if (_currentRoomId != null) {
//       leaveRoom(_currentRoomId!);
//     }
    
//     _socket?.disconnect();
//     _socket = null;
//     _isConnected = false;
//     _currentRoomId = null;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     debugPrint('SocketChatService: 🗑️ Disposing service');
//     _isDisposed = true;
//     disconnect();
//     _messageStreamController.close();
//     super.dispose();
//   }
// }