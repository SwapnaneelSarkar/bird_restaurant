// lib/presentation/screens/chat/event.dart - ENHANCED VERSION WITH MARK AS READ

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadChatData extends ChatEvent {
  final String orderId;

  const LoadChatData(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class SendMessage extends ChatEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
}

class RefreshChat extends ChatEvent {
  const RefreshChat();
}

class StartTyping extends ChatEvent {
  const StartTyping();
}

class StopTyping extends ChatEvent {
  const StopTyping();
}

// NEW: Mark messages as read event
class MarkAsRead extends ChatEvent {
  final String roomId;

  const MarkAsRead(this.roomId);

  @override
  List<Object> get props => [roomId];
}

// NEW: Mark individual message as seen event
class MarkMessageAsSeen extends ChatEvent {
  final String messageId;

  const MarkMessageAsSeen(this.messageId);

  @override
  List<Object> get props => [messageId];
}

// Order-related events
class ShowOrderOptions extends ChatEvent {
  final String orderId;
  final String partnerId;

  const ShowOrderOptions({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object> get props => [orderId, partnerId];
}

class LoadOrderDetails extends ChatEvent {
  final String orderId;
  final String partnerId;

  const LoadOrderDetails({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object> get props => [orderId, partnerId];
}

class ChangeOrderStatus extends ChatEvent {
  final String orderId;

  const ChangeOrderStatus(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class UpdateOrderStatus extends ChatEvent {
  final String orderId;
  final String partnerId;
  final String newStatus;

  const UpdateOrderStatus({
    required this.orderId,
    required this.partnerId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [orderId, partnerId, newStatus];
}

// Force refresh menu items (useful for debugging/retry)
class ForceRefreshMenuItems extends ChatEvent {
  const ForceRefreshMenuItems();
}

// Keep these existing events that are used in the original bloc
class ReceiveMessage extends ChatEvent {
  final String message;

  const ReceiveMessage(this.message);

  @override
  List<Object> get props => [message];
}