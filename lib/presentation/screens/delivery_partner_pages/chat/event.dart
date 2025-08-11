// lib/presentation/screens/delivery_partner_pages/chat/event.dart - ENHANCED

import 'package:equatable/equatable.dart';
import '../../../../services/chat_services.dart';
import 'state.dart';

abstract class DeliveryPartnerChatEvent extends Equatable {
  const DeliveryPartnerChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryPartnerChatData extends DeliveryPartnerChatEvent {
  final String orderId;

  const LoadDeliveryPartnerChatData(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class AppResume extends DeliveryPartnerChatEvent {
  const AppResume();
}

class RefreshChat extends DeliveryPartnerChatEvent {
  const RefreshChat();
}

class MarkOrderAsDelivered extends DeliveryPartnerChatEvent {
  final String orderId;

  const MarkOrderAsDelivered(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class UpdateMessages extends DeliveryPartnerChatEvent {
  const UpdateMessages();
}

class LoadOrderDetails extends DeliveryPartnerChatEvent {
  final String orderId;
  final String partnerId;

  const LoadOrderDetails({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object> get props => [orderId, partnerId];
}

class LoadUserDetails extends DeliveryPartnerChatEvent {
  final String userId;

  const LoadUserDetails(this.userId);

  @override
  List<Object> get props => [userId];
}

class MarkAsRead extends DeliveryPartnerChatEvent {
  final String roomId;

  const MarkAsRead(this.roomId);

  @override
  List<Object> get props => [roomId];
}

// Internal events for updating state
class _UpdateMessages extends DeliveryPartnerChatEvent {
  final List<DeliveryPartnerChatMessage> messages;
  
  const _UpdateMessages(this.messages);
  
  @override
  List<Object> get props => [messages];
}

class _UpdateConnectionStatus extends DeliveryPartnerChatEvent {
  final bool isConnected;
  
  const _UpdateConnectionStatus(this.isConnected);
  
  @override
  List<Object> get props => [isConnected];
}

class _AddIncomingMessage extends DeliveryPartnerChatEvent {
  final ApiChatMessage message;
  
  const _AddIncomingMessage(this.message);
  
  @override
  List<Object> get props => [message];
} 