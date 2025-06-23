// lib/bloc/chat_event.dart
import 'package:equatable/equatable.dart';
import 'service.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChat extends ChatEvent {}

class ConnectSocket extends ChatEvent {}

class DisconnectSocket extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String content;
  final String messageType;

  const SendMessage({
    required this.content,
    this.messageType = 'text',
  });

  @override
  List<Object?> get props => [content, messageType];
}

class LoadMessageHistory extends ChatEvent {}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class LoadChatRoom extends ChatEvent {
  final String orderId;

  const LoadChatRoom(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ClearMessages extends ChatEvent {}

class MessageSendingFailed extends ChatEvent {
  final String error;

  const MessageSendingFailed(this.error);

  @override
  List<Object?> get props => [error];
}

// New events for additional functionality

class LoadChatRooms extends ChatEvent {}

class MarkAsRead extends ChatEvent {
  final String roomId;

  const MarkAsRead(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class LoadMessageHistoryForRoom extends ChatEvent {
  final String roomId;

  const LoadMessageHistoryForRoom(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class SwitchToRoom extends ChatEvent {
  final String roomId;
  final String orderId;

  const SwitchToRoom({
    required this.roomId,
    required this.orderId,
  });

  @override
  List<Object?> get props => [roomId, orderId];
}