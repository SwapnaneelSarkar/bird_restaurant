// lib/models/chat_room_model.dart

import '../utils/time_utils.dart';

class ChatRoomResponse {
  final List<ChatRoom> chatRooms;

  ChatRoomResponse({required this.chatRooms});

  factory ChatRoomResponse.fromJson(List<dynamic> json) {
    return ChatRoomResponse(
      chatRooms: json.map((room) => ChatRoom.fromJson(room)).toList(),
    );
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
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => Participant.fromJson(p))
          .toList() ?? [],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: TimeUtils.parseToIST(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      createdAt: TimeUtils.parseToIST(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Get the user participant (not partner)
  Participant? get userParticipant {
    try {
      return participants.firstWhere((p) => p.userType == 'user');
    } catch (e) {
      return null;
    }
  }

  // Get formatted time for chat list display using IST 12-hour format
  // Shows: 
  // - Today: "2:30 PM" (12-hour IST time)
  // - Yesterday: "Yesterday" 
  // - Older: "12/25/2024" (date)
  String get formattedTime {
    return TimeUtils.formatChatListTime(lastMessageTime);
  }

  // Get display message with proper fallback
  String get displayMessage {
    if (lastMessage.isEmpty) {
      return 'No messages yet';
    }
    return lastMessage;
  }

  // Get partner name for display
  String get partnerName {
    final partner = participants.firstWhere(
      (p) => p.userType != 'user',
      orElse: () => Participant(
        id: '',
        userId: '',
        userType: 'partner',
        name: 'Unknown Partner',
        profilePicture: '',
      ),
    );
    return partner.name.isNotEmpty ? partner.name : 'Partner';
  }
}

class Participant {
  final String id;
  final String userId;
  final String userType;
  final String name;
  final String profilePicture;

  Participant({
    required this.id,
    required this.userId,
    required this.userType,
    required this.name,
    required this.profilePicture,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
    );
  }
}