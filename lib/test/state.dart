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
  final ChatRoom? chatRoom;
  final bool isSocketConnected;
  final String? error;
  final bool isLoadingHistory;
  final bool isSendingMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.chatRoom,
    this.isSocketConnected = false,
    this.error,
    this.isLoadingHistory = false,
    this.isSendingMessage = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    ChatRoom? chatRoom,
    bool? isSocketConnected,
    String? error,
    bool? isLoadingHistory,
    bool? isSendingMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      chatRoom: chatRoom ?? this.chatRoom,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      error: error,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        chatRoom,
        isSocketConnected,
        error,
        isLoadingHistory,
        isSendingMessage,
      ];
}