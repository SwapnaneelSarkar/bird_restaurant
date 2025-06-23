// lib/bloc/chat_state.dart
import 'package:equatable/equatable.dart';
import 'service.dart';

enum ChatStatus {
  initial,
  loading,
  connected,
  disconnected,
  error,
  sendingMessage,
  messageSent,
  messageReceived,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final List<ChatRoom> chatRooms;
  final ChatRoom? currentChatRoom;
  final String? currentRoomId;
  final bool isSocketConnected;
  final String? error;
  final bool isLoadingHistory;
  final bool isSendingMessage;
  final bool isLoadingRooms;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.chatRooms = const [],
    this.currentChatRoom,
    this.currentRoomId,
    this.isSocketConnected = false,
    this.error,
    this.isLoadingHistory = false,
    this.isSendingMessage = false,
    this.isLoadingRooms = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    List<ChatRoom>? chatRooms,
    ChatRoom? currentChatRoom,
    String? currentRoomId,
    bool? isSocketConnected,
    String? error,
    bool? isLoadingHistory,
    bool? isSendingMessage,
    bool? isLoadingRooms,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      chatRooms: chatRooms ?? this.chatRooms,
      currentChatRoom: currentChatRoom ?? this.currentChatRoom,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      error: error,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        chatRooms,
        currentChatRoom,
        currentRoomId,
        isSocketConnected,
        error,
        isLoadingHistory,
        isSendingMessage,
        isLoadingRooms,
      ];
}