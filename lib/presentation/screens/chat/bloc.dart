// lib/presentation/screens/chat/bloc.dart - COMPLETE VERSION FOR REAL-TIME MESSAGES

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
  StreamSubscription? _chatServiceSubscription;
  StreamSubscription? _messageStreamSubscription;

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
    on<_UpdateConnectionStatus>(_onUpdateConnectionStatus);
    on<_AddIncomingMessage>(_onAddIncomingMessage);

    // Listen to chat service changes for general updates
    _chatService.addListener(_onChatServiceUpdate);
    
    // Listen to real-time message stream for immediate updates
    _messageStreamSubscription = _chatService.messageStream.listen(
      (message) {
        debugPrint('ChatBloc: 🔥 Received real-time message from stream: ${message.content}');
        if (!isClosed) {
          add(_AddIncomingMessage(message));
        }
      },
      onError: (error) {
        debugPrint('ChatBloc: Error in message stream: $error');
      },
    );
  }

  void _onChatServiceUpdate() {
    if (!isClosed) {
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
      
      // Update connection status
      add(_UpdateConnectionStatus(_chatService.isConnected));
    }
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

      // Set the room ID
      _currentRoomId = event.orderId.isNotEmpty ? event.orderId : 'default_room';
      
      // Try to connect to chat service
      await _chatService.connect();
      
      // Wait briefly for connection
      int attempts = 0;
      while (!_chatService.isConnected && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
      
      if (!_chatService.isConnected) {
        debugPrint('ChatBloc: Socket connection failed, using HTTP only mode');
      } else {
        debugPrint('ChatBloc: Socket connected successfully');
      }
      
      // Join the chat room
      await _chatService.joinRoom(_currentRoomId!);
      
      // Mock order info (replace with real API call)
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
        isConnected: _chatService.isConnected,
      ));
      
      debugPrint('ChatBloc: Chat data loaded successfully with ${messages.length} messages (Socket: ${_chatService.isConnected ? 'Connected' : 'Disconnected'})');
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

  void _onAddIncomingMessage(_AddIncomingMessage event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Convert API message to UI message
      final newChatMessage = ChatMessage(
        id: event.message.id,
        message: event.message.content,
        isUserMessage: event.message.senderType == 'partner',
        time: _formatTime(event.message.createdAt),
      );
      
      // Check if message already exists to avoid duplicates
      final messageExists = currentState.messages.any((m) => 
        m.id == newChatMessage.id ||
        (m.message == newChatMessage.message && 
         m.isUserMessage == newChatMessage.isUserMessage &&
         m.time == newChatMessage.time));
      
      if (!messageExists) {
        final updatedMessages = [...currentState.messages, newChatMessage];
        
        // Sort messages by ID or time to maintain order
        updatedMessages.sort((a, b) {
          // Try to parse timestamp from ID if possible, otherwise use time string
          try {
            final aTime = int.tryParse(a.id) ?? 0;
            final bTime = int.tryParse(b.id) ?? 0;
            if (aTime != 0 && bTime != 0) {
              return aTime.compareTo(bTime);
            }
          } catch (e) {
            // Fall back to string comparison
            debugPrint('ChatBloc: Error parsing message IDs for sorting: $e');
          }
          return a.id.compareTo(b.id);
        });
        
        debugPrint('ChatBloc: ✅ Added incoming message from ${event.message.senderType}: ${event.message.content}');
        
        emit(currentState.copyWith(
          messages: updatedMessages,
        ));
      } else {
        debugPrint('ChatBloc: 🔄 Message already exists, skipping duplicate');
      }
    }
  }

  void _onUpdateConnectionStatus(_UpdateConnectionStatus event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(
        isConnected: event.isConnected,
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
        
        // Create the sent message immediately for better UX (optimistic update)
        final sentMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: true,
          time: _getCurrentTime(),
        );
        
        // Add sent message to the list immediately
        final updatedMessages = [...currentState.messages, sentMessage];
        
        // Update UI immediately
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: true, // Keep showing sending state
        ));
        
        // Send message via chat service
        final success = await _chatService.sendMessage(_currentRoomId!, event.message);
        
        if (success) {
          debugPrint('ChatBloc: Message sent successfully');
          
          // Stop typing indicator
          if (_chatService.isConnected) {
            _chatService.sendStopTyping(_currentRoomId!);
          }
          
          // Update sending state to false
          emit(currentState.copyWith(
            messages: updatedMessages,
            isSendingMessage: false,
          ));
          
        } else {
          debugPrint('ChatBloc: Failed to send message');
          
          // Remove the optimistically added message on failure
          emit(currentState.copyWith(isSendingMessage: false));
          emit(const ChatError('Failed to send message. Please try again.'));
          
          // Restore the previous state without the failed message
          emit(currentState);
        }
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        
        // Remove the optimistically added message on error
        emit(currentState.copyWith(isSendingMessage: false));
        emit(const ChatError('Failed to send message. Please try again.'));
        
        // Restore the previous state without the failed message
        emit(currentState);
      }
    }
  }

  void _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) {
    // This is now handled by the message stream listener
    // Keep this for backward compatibility or manual message injection
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Receiving message via event: ${event.message}');
        
        // Create new message
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: false,
          time: _getCurrentTime(),
        );
        
        // Check if message already exists to avoid duplicates
        final messageExists = currentState.messages.any((m) => 
          m.message == event.message && 
          m.isUserMessage == false &&
          m.time == newMessage.time);
          
        if (!messageExists) {
          // Add message to list
          final updatedMessages = [...currentState.messages, newMessage];
          emit(currentState.copyWith(messages: updatedMessages));
          debugPrint('ChatBloc: Message received successfully via event');
        } else {
          debugPrint('ChatBloc: Duplicate message via event, skipping');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error receiving message: $e');
      }
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null && _chatService.isConnected) {
      try {
        _chatService.sendTyping(_currentRoomId!);
        
        // Cancel existing timer
        _typingTimer?.cancel();
        
        // Set a timer to stop typing after 3 seconds of inactivity
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            add(const StopTyping());
          }
        });
        
        debugPrint('ChatBloc: Started typing indicator');
      } catch (e) {
        debugPrint('ChatBloc: Error starting typing: $e');
      }
    }
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null && _chatService.isConnected) {
      try {
        _chatService.sendStopTyping(_currentRoomId!);
        _typingTimer?.cancel();
        debugPrint('ChatBloc: Stopped typing indicator');
      } catch (e) {
        debugPrint('ChatBloc: Error stopping typing: $e');
      }
    }
  }

  Future<void> _onRefreshChat(RefreshChat event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        debugPrint('ChatBloc: Refreshing chat history');
        
        // Show refreshing state briefly
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: true));
        }
        
        // Reload chat history from server
        await _chatService.loadChatHistory(_currentRoomId!);
        debugPrint('ChatBloc: Chat refreshed successfully');
        
        // The updated messages will be handled by the chat service listener
        // Just update the refreshing state
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          
          // Convert the refreshed messages
          final refreshedMessages = _chatService.messages.map((msg) {
            return ChatMessage(
              id: msg.id,
              message: msg.content,
              isUserMessage: msg.senderType == 'partner',
              time: _formatTime(msg.createdAt),
            );
          }).toList();
          
          emit(currentState.copyWith(
            messages: refreshedMessages,
            isRefreshing: false,
          ));
        }
      } catch (e) {
        debugPrint('ChatBloc: Error refreshing chat: $e');
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: false));
        }
        
        // Show error message
        emit(const ChatError('Failed to refresh chat. Please try again.'));
        
        // Restore previous state after showing error
        if (state is ChatError) {
          Timer(const Duration(seconds: 2), () {
            if (!isClosed && state is ChatLoaded) {
              final previousState = state as ChatLoaded;
              emit(previousState);
            }
          });
        }
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
    debugPrint('ChatBloc: Closing and cleaning up resources');
    
    // Cancel timers
    _typingTimer?.cancel();
    
    // Cancel subscriptions
    _chatServiceSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    
    // Remove listeners and dispose chat service
    _chatService.removeListener(_onChatServiceUpdate);
    _chatService.dispose();
    
    return super.close();
  }
}

// Internal events for updating state
class _UpdateMessages extends ChatEvent {
  final List<ChatMessage> messages;
  
  const _UpdateMessages(this.messages);
  
  @override
  List<Object?> get props => [messages];
}

class _UpdateConnectionStatus extends ChatEvent {
  final bool isConnected;
  
  const _UpdateConnectionStatus(this.isConnected);
  
  @override
  List<Object?> get props => [isConnected];
}

class _AddIncomingMessage extends ChatEvent {
  final ApiChatMessage message;
  
  const _AddIncomingMessage(this.message);
  
  @override
  List<Object?> get props => [message];
}