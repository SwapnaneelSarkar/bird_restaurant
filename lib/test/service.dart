// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<String> readBy;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
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
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      createdAt: DateTime.parse(json['createdAt']),
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

class ChatService {
  static const String baseUrl = 'https://api.bird.delivery/api/';
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtb2JpbGUiOiIxMTExMTExMTExIiwiaWF0IjoxNzQ5MjgxMDg1LCJleHAiOjE3NTA1NzcwODV9.ZlkI3-crTFz-rX-kHQSnX5KlUCMvxQ7o0JCyiq6JF1w';
  static const String userId = 'R4dcc94f725';
  static const String roomId = '716333182e6b460a9eb2918fbf48c5b1';

  late IO.Socket socket;
  bool _isConnected = false;

  // Socket event callbacks
  Function(ChatMessage)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  ChatService() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('https://api.bird.delivery', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {
        'Authorization': 'Bearer $token',
      },
    });

    socket.on('connect', (_) {
      print('Socket connected successfully');
      _isConnected = true;
      onConnected?.call();
      // Join the room
      print('Joining room: $roomId');
      socket.emit('join_room', roomId);
    });

    socket.on('disconnect', (_) {
      print('Disconnected from socket');
      _isConnected = false;
      onDisconnected?.call();
    });

    socket.on('connect_error', (data) {
      print('Socket Connect Error: $data');
    });

    socket.on('connect_timeout', (data) {
      print('Socket Connect Timeout: $data');
    });

    // Listen for receive_message event (as per your backend developer)
    socket.on('receive_message', (data) {
      print('Received message via socket: $data');
      try {
        // Handle the case where data might be missing some fields
        Map<String, dynamic> messageData = Map<String, dynamic>.from(data);
        
        // Add missing fields for socket messages if they don't exist
        if (!messageData.containsKey('_id') || messageData['_id'] == null) {
          messageData['_id'] = 'socket_${DateTime.now().millisecondsSinceEpoch}';
        }
        if (!messageData.containsKey('createdAt') || messageData['createdAt'] == null) {
          messageData['createdAt'] = DateTime.now().toIso8601String();
        }
        if (!messageData.containsKey('readBy') || messageData['readBy'] == null) {
          messageData['readBy'] = [];
        }
        
        print('Parsed message data: $messageData');
        final message = ChatMessage.fromJson(messageData);
        print('Created ChatMessage object: ${message.content}');
        onMessageReceived?.call(message);
      } catch (e, stackTrace) {
        print('Error parsing received message: $e');
        print('Stack trace: $stackTrace');
        print('Raw message data: $data');
      }
    });

    socket.on('user_typing', (data) {
      print('${data['userId']} is typing...');
      // You can handle typing indicators here if needed
    });

    socket.on('user_stop_typing', (data) {
      print('${data['userId']} stopped typing.');
      // Handle stop typing here if needed
    });

    socket.on('error', (data) {
      print('Socket error: $data');
    });

    // Add a test listener to see all events
    socket.onAny((event, data) {
      print('Socket received event: $event with data: $data');
    });
  }

  void connect() {
    if (!_isConnected) {
      print('Attempting to connect socket to: https://api.bird.delivery');
      socket.connect();
    } else {
      print('Socket already connected.');
      // Still join the room if already connected
      joinRoom(roomId);
    }
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
    }
  }

  void joinRoom(String roomId) {
    if (_isConnected) {
      print('Joining room: $roomId');
      socket.emit('join_room', roomId);
    } else {
      print('Socket not connected. Cannot join room.');
    }
  }

  void leaveRoom(String roomId) {
    if (_isConnected) {
      print('Leaving room: $roomId');
      socket.emit('leave_room', roomId);
    } else {
      print('Socket not connected. Cannot leave room.');
    }
  }

  void sendMessageViaSocket({
    required String content,
    String messageType = 'text',
    String? fileUrl,
  }) {
    if (_isConnected) {
      print('Sending message via socket to room $roomId: $content');
      final messageData = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'partner',
        'content': content,
        'messageType': messageType,
        'fileUrl': fileUrl,
      };
      socket.emit('send_message', messageData);
    } else {
      print('Socket not connected. Cannot send message.');
    }
  }

  void sendTyping() {
    if (_isConnected) {
      socket.emit('typing', {'roomId': roomId, 'userId': userId});
    }
  }

  void sendStopTyping() {
    if (_isConnected) {
      socket.emit('stop_typing', {'roomId': roomId, 'userId': userId});
    }
  }

  Future<ChatMessage?> sendMessage({
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'roomId': roomId,
          'senderId': userId,
          'senderType': 'partner',
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

  Future<List<ChatMessage>> getMessageHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}chat/history/$roomId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Failed to get message history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting message history: $e');
      return [];
    }
  }

  Future<ChatRoom?> getChatRoom(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}chat/rooms/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'SUCCESS') {
          return ChatRoom.fromJson(data['data']);
        }
      }
      print('Failed to get chat room: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  void dispose() {
    disconnect();
    socket.dispose();
  }
}