// lib/presentation/screens/chat/event.dart

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatData extends ChatEvent {
  final String orderId;

  const LoadChatData(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class SendMessage extends ChatEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiveMessage extends ChatEvent {
  final String message;

  const ReceiveMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class StartTyping extends ChatEvent {
  const StartTyping();
}

class StopTyping extends ChatEvent {
  const StopTyping();
}

class RefreshChat extends ChatEvent {
  const RefreshChat();
}

// New events for order functionality
class ShowOrderOptions extends ChatEvent {
  final String orderId;
  final String partnerId;

  const ShowOrderOptions({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [orderId, partnerId];
}

class LoadOrderDetails extends ChatEvent {
  final String orderId;
  final String partnerId;

  const LoadOrderDetails({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [orderId, partnerId];
}

class ChangeOrderStatus extends ChatEvent {
  final String orderId;
  final String partnerId;

  const ChangeOrderStatus({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [orderId, partnerId];
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
  List<Object?> get props => [orderId, partnerId, newStatus];
}