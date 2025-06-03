// lib/models/chat_room_model.dart

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
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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

  // Get formatted time for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = lastMessageTime.hour > 12 
          ? lastMessageTime.hour - 12 
          : lastMessageTime.hour == 0 ? 12 : lastMessageTime.hour;
      final minute = lastMessageTime.minute.toString().padLeft(2, '0');
      final period = lastMessageTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[lastMessageTime.weekday - 1];
    } else {
      // Older - show date
      final month = lastMessageTime.month.toString().padLeft(2, '0');
      final day = lastMessageTime.day.toString().padLeft(2, '0');
      return '$month/$day/${lastMessageTime.year}';
    }
  }

  // Get display message
  String get displayMessage {
    if (lastMessage.isEmpty) {
      return 'No messages yet';
    }
    return lastMessage;
  }
}

class Participant {
  final String userId;
  final String userType;
  final String id;

  Participant({
    required this.userId,
    required this.userType,
    required this.id,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}