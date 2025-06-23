// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
// import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/time_utils.dart';

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String receiverId;
  final String content;
  final String messageType;
  final DateTime timestamp;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.readBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['message'] ?? json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      timestamp: json['timestamp'] != null 
          ? TimeUtils.parseToIST(json['timestamp']) 
          : TimeUtils.getCurrentIST(),
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': content,
      'messageType': messageType,
      'timestamp': TimeUtils.toIsoStringForAPI(timestamp),
      'readBy': readBy,
    };
  }

  // WebSocket message format
  Map<String, dynamic> toWebSocketJson() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': content,
      'messageType': messageType,
      'timestamp': TimeUtils.toIsoStringForAPI(timestamp),
    };
  }
}

class ChatRoom {
  final String id;
  final String roomId;
  final String orderId;
  final List<Participant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.roomId,
    required this.orderId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      orderId: json['orderId'] ?? '',
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: TimeUtils.parseToIST(json['lastMessageTime']),
      createdAt: TimeUtils.parseToIST(json['createdAt']),
    );
  }
}

class Participant {
  final String userId;
  final String userType;

  Participant({required this.userId, required this.userType});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
    );
  }
}

class WebSocketMessage {
  final String event;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.event,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'data': data,
    };
  }

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      event: json['event'] ?? '',
      data: json['data'] ?? {},
    );
  }
}

class ChatService {
  static const String baseUrl = 'https://api.bird.delivery/api/';
  static const String wsUrl = 'https://api.bird.delivery/';
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtb2JpbGUiOiIxMTExMTExMTExIiwiaWF0IjoxNzUwNjk5NjE5LCJleHAiOjE3NTE5OTU2MTl9.WIC8mm58FEDr3m2S6ooxvSc-ClFLxFsjR9nYKx4_E4s';
  static const String userId = '08b008c0db73408fbefc9271';
  static const String userType = 'user';
  // static const bool testMode = true; // Set to true to bypass WebSocket for testing
  
  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isConnecting = false;

  // WebSocketChannel? _channel;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  String roomId = '716333182e6b460a9eb2918fbf48c5b1';
  
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  Function(ChatMessage)? onMessageReceived;
  Function(List<ChatRoom>)? onRoomsReceived;
  Function(List<ChatMessage>)? onHistoryReceived;

  ChatService() {
    // if (!testMode) {
      _initWebSocket();
    // } else {
      // print('ChatService initialized in test mode - WebSocket disabled');
    // }
  }

  void _initWebSocket() {
    // if (testMode) {
    //   print('Test mode enabled - skipping WebSocket initialization');
    //   return;
    // }
    _connectWebSocket();
  }

  void _connectWebSocket() {
  if (_isConnecting || _isConnected) return;

  _isConnecting = true;
  print('🔌 Connecting to WebSocket: $wsUrl');

  try {
    final uri = Uri.parse(wsUrl);
    print('Parsed URI: $uri');

    _socket = IO.io(wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId}
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to socket');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      onConnected?.call();

      // Join room if needed
      joinRoom(roomId);
    });

    _socket.onConnectError((data) {
      print('Connect error: $data');
      _handleConnectionFailure('Connect error');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket');
      _isConnected = false;
      _scheduleReconnect();
    });

    _socket.onError((data) {
      print('🚨 Socket error: $data');
      _handleConnectionFailure('Socket error');
    });

  } catch (e) {
    _handleConnectionFailure('Exception: $e');
  }
}

void _handleConnectionFailure(String reason) {
  _isConnecting = false;
  _isConnected = false;
  print('WebSocket connection failed: $reason');
  onError?.call(reason);
  _scheduleReconnect();
}

  void _handleWebSocketMessage(dynamic data) {
    try {
      print('Received WebSocket message: $data');
      
      final jsonData = jsonDecode(data.toString());
      final message = WebSocketMessage.fromJson(jsonData);
      
      print('Parsed WebSocket message - Event: ${message.event}');
      
      switch (message.event) {
        case 'receive_message':
          _handleReceivedMessage(message.data);
          break;
        case 'join_room':
          print('Joined room: ${message.data['roomId']}');
          break;
        case 'error':
          print('WebSocket error: ${message.data['message']}');
          onError?.call(message.data['message'] ?? 'Unknown error');
          break;
        default:
          print('Unknown WebSocket event: ${message.event}');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
      onError?.call('Failed to parse WebSocket message: $e');
    }
  }

  void _handleReceivedMessage(Map<String, dynamic> data) {
    try {
      print('Handling received message: $data');
      
      final chatMessage = ChatMessage(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: data['roomId'] ?? roomId,
        senderId: data['senderId'] ?? '',
        receiverId: data['receiverId'] ?? '',
        content: data['message'] ?? data['content'] ?? '', // Handle both 'message' and 'content' fields
        messageType: data['messageType'] ?? 'text',
        timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        readBy: List<String>.from(data['readBy'] ?? []),
      );
      
      print('Created ChatMessage: ${chatMessage.content}');
      onMessageReceived?.call(chatMessage);
      
    } catch (e) {
      print('Error creating ChatMessage: $e');
      onError?.call('Failed to create chat message: $e');
    }
  }

  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    
    // Check if it's a connection upgrade error
    if (error.toString().contains('502') || 
        error.toString().contains('not upgraded to websocket')) {
      print('Server connection issue detected. This might be a server-side problem.');
      onError?.call('Server connection issue (502). The WebSocket server might be down or not properly configured.');
    } else {
      onError?.call('WebSocket error: $error');
    }
    
    _scheduleReconnect();
  }

  void _handleWebSocketClosed() {
    print('WebSocket connection closed');
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      onError?.call('Max reconnection attempts reached. Please check your internet connection and try again.');
      return;
    }

    _reconnectAttempts++;
    print('Scheduling reconnection attempt $_reconnectAttempts in ${reconnectDelay.inSeconds} seconds');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_isConnected) {
        _connectWebSocket();
      }
    });
  }

  void connect() {
    // if (testMode) {
    //   print('Test mode enabled - bypassing WebSocket connection');
    //   _isConnected = true;
    //   onConnected?.call();
    //   return;
    // }
    
    if (_isConnected || _isConnecting) return;
    _connectWebSocket();
  }

  void disconnect() {
    // if (testMode) {
    //   print('Test mode - simulating disconnect');
    //   _isConnected = false;
    //   onDisconnected?.call();
    //   return;
    // }
    
    _reconnectTimer?.cancel();
    // _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    onDisconnected?.call();
  }

  void joinRoom(String roomId) {
  if (!_isConnected) {
    print('Cannot join room: not connected');
    return;
  }

  if (_socket.connected) {
    print('Emitting join_room with roomId: $roomId');
    _socket.emit('join_room', roomId);

    // Send a test message right after joining the room
    final messageData = {
      'roomId': roomId,
      'senderId': userId,
      'senderType': 'user', // Adjust according to your app
      'content': 'Hello, I just joined the room.',
      'messageType': 'text',
    };

    print('Sending test message after join_room');
    _socket.emit('send_message', messageData);
  } else {
    print('Socket not yet connected');
  }

  // Add listener for incoming messages
  _socket.on('receive_message', (data) {
    print('Received message: $data');
    // You can call a callback or update state here
  });
}

  // void _sendWebSocketMessage(WebSocketMessage message) {
      void _sendWebSocketMessage(String message) {
    // if (!_isConnected || _channel == null) {
    //   print('Cannot send message: not connected');
    //   return;
    // }
    
    // try {
    //   final jsonMessage = jsonEncode(message.toJson());
    //   _channel!.sink.add(jsonMessage);
    //   print('Sent WebSocket message: ${message.event}');
    // } catch (e) {
    //   print('Error sending WebSocket message: $e');
    //   onError?.call('Failed to send message: $e');
    // }
  }

  void sendMessage(String message) {
    // if (testMode) {
    //   print('🔵 Test mode - simulating message send: $message');
      
    //   // Simulate the message being sent via WebSocket
    //   final sentMessage = ChatMessage(
    //     id: DateTime.now().millisecondsSinceEpoch.toString(),
    //     roomId: roomId,
    //     senderId: userId,
    //     receiverId: 'partner',
    //     content: message,
    //     messageType: 'text',
    //     timestamp: DateTime.now(),
    //     readBy: [],
    //   );
      
    //   // Trigger the callback to notify BLoC immediately
    //   print('🔵 Test mode - about to trigger onMessageReceived callback');
    //   print('🔵 Test mode - onMessageReceived is null: ${onMessageReceived == null}');
      
    //   if (onMessageReceived != null) {
    //     print('🔵 Test mode - calling onMessageReceived callback');
    //     onMessageReceived!(sentMessage);
    //     print('🔵 Test mode - onMessageReceived callback completed');
    //   } else {
    //     print('🔴 Test mode - ERROR: onMessageReceived callback is null!');
    //   }
      
    //   // Simulate receiving a response after 1 second
    //   Future.delayed(const Duration(seconds: 1), () {
    //     if (onMessageReceived != null) {
    //       final responseMessage = ChatMessage(
    //         id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
    //         roomId: roomId,
    //         senderId: 'partner',
    //         receiverId: userId,
    //         content: 'This is a test response to: $message',
    //         messageType: 'text',
    //         timestamp: DateTime.now(),
    //         readBy: [],
    //       );
    //       print('🔵 Test mode - simulating response message');
    //       onMessageReceived!(responseMessage);
    //     }
    //   });
      
    //   return;
    // }
    
    if (!_isConnected) {
      print('Cannot send message: not connected');
      return;
    }

    // Create WebSocket message with correct format
    final chatMessage = WebSocketMessage(
      event: 'send_message',
      data: {
        'roomId': roomId,
        'senderId': userId,
        'receiverId': 'partner',
        'message': message,
        'messageType': 'text',
        'timestamp': TimeUtils.toIsoStringForAPI(TimeUtils.getCurrentIST()),
      },
    );

    _sendWebSocketMessage('chatMessage');
  }

  // API Methods using the provided endpoints

  /// Get chat rooms for a user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}chat/rooms/?userId=$userId&userType=$userType'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        print('Failed to get chat rooms: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  /// Get chat history for a specific room
  Future<List<ChatMessage>> getMessageHistory(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}chat/history/$roomId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Failed to get message history: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting message history: $e');
      return [];
    }
  }

  /// Send a message via REST API
  Future<ChatMessage?> sendMessageViaAPI({
    required String content,
    String messageType = 'text',
    String? targetRoomId,
  }) async {
    try {
      final roomIdToUse = targetRoomId ?? roomId;
      
      final response = await http.post(
        Uri.parse('${baseUrl}chat/message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomId': roomIdToUse,
          'senderId': userId,
          'senderType': userType,
          'content': content,
          'messageType': messageType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
      } else {
        print('Failed to send message: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomId': roomId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to mark as read: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // Legacy methods for backward compatibility
  Future<ChatMessage?> sendMessageLegacy({
    required String content,
    String messageType = 'text',
  }) async {
    return sendMessageViaAPI(content: content, messageType: messageType);
  }

  Future<List<ChatMessage>> getMessageHistoryLegacy() async {
    return getMessageHistory(roomId);
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  void dispose() {
    disconnect();
    _reconnectTimer?.cancel();
  }

  // Test mode helper method to simulate receiving messages
  void simulateReceivedMessage(String content, {String senderId = 'partner'}) {
    // if (!testMode) {
    //   print('Cannot simulate message: not in test mode');
    //   return;
    // }
    
    print('🔵 Test mode - simulating received message: $content');
    
    final receivedMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      receiverId: userId,
      content: content,
      messageType: 'text',
      timestamp: DateTime.now(),
      readBy: [],
    );
    
    if (onMessageReceived != null) {
      onMessageReceived!(receivedMessage);
      print('🔵 Test mode - simulated message sent to BLoC');
    } else {
      print('🔴 Test mode - ERROR: onMessageReceived callback is null!');
    }
  }
} 