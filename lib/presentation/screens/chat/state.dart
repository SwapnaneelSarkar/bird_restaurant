// lib/presentation/screens/chat/state.dart

import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatOrderInfo orderInfo;
  final List<ChatMessage> messages;
  final bool isSendingMessage;
  final bool isConnected;
  final bool isRefreshing;

  const ChatLoaded({
    required this.orderInfo,
    required this.messages,
    this.isSendingMessage = false,
    this.isConnected = false,
    this.isRefreshing = false,
  });

  ChatLoaded copyWith({
    ChatOrderInfo? orderInfo,
    List<ChatMessage>? messages,
    bool? isSendingMessage,
    bool? isConnected,
    bool? isRefreshing,
  }) {
    return ChatLoaded(
      orderInfo: orderInfo ?? this.orderInfo,
      messages: messages ?? this.messages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isConnected: isConnected ?? this.isConnected,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    orderInfo,
    messages,
    isSendingMessage,
    isConnected,
    isRefreshing,
  ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatMessage extends Equatable {
  final String id;
  final String message;
  final bool isUserMessage;
  final String time;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.isUserMessage,
    required this.time,
  });

  @override
  List<Object> get props => [id, message, isUserMessage, time];
}

class ChatOrderInfo extends Equatable {
  final String orderId;
  final String restaurantName;
  final String estimatedDelivery;
  final String status;

  const ChatOrderInfo({
    required this.orderId,
    required this.restaurantName,
    required this.estimatedDelivery,
    required this.status,
  });

  @override
  List<Object> get props => [orderId, restaurantName, estimatedDelivery, status];
}