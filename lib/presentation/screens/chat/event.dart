// lib/presentation/screens/chat/event.dart - Updated with order details events

import 'package:equatable/equatable.dart';
import '../../../services/order_service.dart';

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

class LoadOrderDetails extends ChatEvent {
  final String orderId;
  
  const LoadOrderDetails(this.orderId);
  
  @override
  List<Object?> get props => [orderId];
}

class OrderDetailsLoaded extends ChatEvent {
  final OrderDetails orderDetails;
  
  const OrderDetailsLoaded(this.orderDetails);
  
  @override
  List<Object?> get props => [orderDetails];
}

class OrderDetailsLoadFailed extends ChatEvent {
  final String error;
  
  const OrderDetailsLoadFailed(this.error);
  
  @override
  List<Object?> get props => [error];
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

class RefreshOrderDetails extends ChatEvent {
  final String orderId;
  
  const RefreshOrderDetails(this.orderId);
  
  @override
  List<Object?> get props => [orderId];
}