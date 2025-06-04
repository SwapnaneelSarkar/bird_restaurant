// lib/presentation/screens/chat/bloc.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_services.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  Timer? _typingTimer;
  String? _currentRoomId;
  String? _currentUserId;

  ChatBloc({ChatService? chatService}) 
    : _chatService = chatService ?? ChatService(),
      super(ChatInitial()) {
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<RefreshChat>(_onRefreshChat);
    on<_UpdateMessages>(_onUpdateMessages);

    // Listen to chat service changes
    _chatService.addListener(_onChatServiceUpdate);
  }

  void _onChatServiceUpdate() {
    // Convert chat service messages to chat state messages
    final messages = _chatService.messages.map((msg) {
      return ChatMessage(
        id: msg.id,
        message: msg.content,
        isUserMessage: msg.senderType == 'partner',
        time: _formatTime(msg.createdAt),
      );
    }).toList();

    // Add internal event to update messages
    add(_UpdateMessages(messages));
  }

  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      debugPrint('ChatBloc: Loading chat data for order: ${event.orderId}');
      
      // Get current user ID
      _currentUserId = await TokenService.getUserId();
      if (_currentUserId == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }

      // Set the room ID (using order ID as room ID)
      _currentRoomId = event.orderId.isNotEmpty ? event.orderId : 'default_room';
      
      // Connect to chat service if not connected
      await _chatService.connect();
      
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Join the chat room
      await _chatService.joinRoom(_currentRoomId!);
      
      // Mock order info (you can replace this with real API call)
      const orderInfo = ChatOrderInfo(
        orderId: '#2504',
        restaurantName: 'Italian Restaurant',
        estimatedDelivery: '30 mins',
        status: 'Preparing',
      );

      // Convert chat service messages to UI messages
      final messages = _chatService.messages.map((msg) {
        return ChatMessage(
          id: msg.id,
          message: msg.content,
          isUserMessage: msg.senderType == 'partner',
          time: _formatTime(msg.createdAt),
        );
      }).toList();

      emit(ChatLoaded(
        orderInfo: orderInfo,
        messages: messages,
      ));
      
      debugPrint('ChatBloc: Chat data loaded successfully with ${messages.length} messages');
    } catch (e) {
      debugPrint('ChatBloc: Error loading chat data: $e');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }

  void _onUpdateMessages(_UpdateMessages event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(
        messages: event.messages,
        isSendingMessage: false,
      ));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      // Show sending state
      emit(currentState.copyWith(isSendingMessage: true));
      
      try {
        debugPrint('ChatBloc: Sending message: ${event.message}');
        
        // Send message via chat service
        final success = await _chatService.sendMessage(_currentRoomId!, event.message);
        
        if (success) {
          debugPrint('ChatBloc: Message sent successfully');
          
          // Stop typing indicator
          _chatService.sendStopTyping(_currentRoomId!);
          
          // The message will be updated via the chat service listener
          // So we just need to update the sending state
          emit(currentState.copyWith(isSendingMessage: false));
        } else {
          debugPrint('ChatBloc: Failed to send message');
          emit(currentState.copyWith(isSendingMessage: false));
          emit(const ChatError('Failed to send message. Please try again.'));
          emit(currentState.copyWith(isSendingMessage: false));
        }
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        emit(currentState.copyWith(isSendingMessage: false));
        emit(const ChatError('Failed to send message. Please try again.'));
        emit(currentState.copyWith(isSendingMessage: false));
      }
    }
  }

  void _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) {
    // This event is now handled by the chat service listener
    // but keeping it for backward compatibility
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Receiving message: ${event.message}');
        
        // Create new message
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: false,
          time: _getCurrentTime(),
        );
        
        // Add message to list
        final updatedMessages = [...currentState.messages, newMessage];
        
        emit(currentState.copyWith(messages: updatedMessages));
        
        debugPrint('ChatBloc: Message received successfully');
      } catch (e) {
        debugPrint('ChatBloc: Error receiving message: $e');
      }
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null) {
      _chatService.sendTyping(_currentRoomId!);
      
      // Cancel existing timer
      _typingTimer?.cancel();
      
      // Set a timer to stop typing after 3 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        add(const StopTyping());
      });
    }
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null) {
      _chatService.sendStopTyping(_currentRoomId!);
      _typingTimer?.cancel();
    }
  }

  Future<void> _onRefreshChat(RefreshChat event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        await _chatService.loadChatHistory(_currentRoomId!);
        debugPrint('ChatBloc: Chat refreshed successfully');
      } catch (e) {
        debugPrint('ChatBloc: Error refreshing chat: $e');
      }
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _chatService.removeListener(_onChatServiceUpdate);
    _chatService.dispose();
    return super.close();
  }
}

// Internal event for updating messages
class _UpdateMessages extends ChatEvent {
  final List<ChatMessage> messages;
  
  const _UpdateMessages(this.messages);
  
  @override
  List<Object?> get props => [messages];
}