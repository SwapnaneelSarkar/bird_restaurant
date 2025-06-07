// lib/presentation/screens/chat/bloc.dart - Updated with IST time formatting

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_services.dart';
import '../../../services/token_service.dart';
import '../../../utils/time_utils.dart'; // Import time utils
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final PollingChatService _chatService;
  Timer? _typingTimer;
  String? _currentRoomId;
  String? _currentUserId;
  StreamSubscription? _chatServiceSubscription;
  StreamSubscription? _messageStreamSubscription;

  ChatBloc({PollingChatService? chatService}) 
    : _chatService = chatService ?? PollingChatService(),
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
        debugPrint('ChatBloc: 🔥 Received real-time message from polling: ${message.content}');
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
      final messages = _chatService.messages.map((apiMsg) {
        // SIMPLE: Compare sender ID directly with current user ID
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        
        debugPrint('ChatBloc: 🔄 Converting API message to UI message:');
        debugPrint('  - Content: "${apiMsg.content}"');
        debugPrint('  - API Sender ID: "${apiMsg.senderId}"');
        debugPrint('  - Current User ID: "${_currentUserId ?? 'null'}"');
        debugPrint('  - Is from current user: $isFromCurrentUser');
        debugPrint('  - Will appear on: ${isFromCurrentUser ? 'RIGHT' : 'LEFT'} side');
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT side, FALSE = Other user = LEFT side
          time: _formatMessageTime(apiMsg.createdAt), // Use IST formatting
        );
      }).toList();

      // Add internal event to update messages
      add(_UpdateMessages(messages));
      
      // Update connection status (polling status)
      add(_UpdateConnectionStatus(_chatService.isConnected));
    }
  }

  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      debugPrint('ChatBloc: 📱 Loading chat data for order: ${event.orderId}');
      
      // Get current user ID
      _currentUserId = await TokenService.getUserId();
      if (_currentUserId == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }

      debugPrint('ChatBloc: 🆔 Current User ID: $_currentUserId');

      // Set the room ID
      _currentRoomId = event.orderId.isNotEmpty ? event.orderId : 'default_room';
      
      // Join the chat room (this will load history and start polling)
      await _chatService.joinRoom(_currentRoomId!);
      
      // Create order info based on the order ID
      final orderInfo = ChatOrderInfo(
        orderId: _formatOrderId(event.orderId),
        restaurantName: 'Your Restaurant',
        estimatedDelivery: '30 mins',
        status: 'Preparing',
      );

      // Convert chat service messages to UI messages with SIMPLE logic
      final messages = _chatService.messages.map((apiMsg) {
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT, FALSE = Other user = LEFT
          time: _formatMessageTime(apiMsg.createdAt), // Use IST formatting
        );
      }).toList();

      // Debug: Count and show message directions
      final rightMessages = messages.where((m) => m.isUserMessage).length;
      final leftMessages = messages.where((m) => !m.isUserMessage).length;
      debugPrint('ChatBloc: 📊 Message summary:');
      debugPrint('  - RIGHT side (current user): $rightMessages messages');
      debugPrint('  - LEFT side (other users): $leftMessages messages');
      debugPrint('  - Total messages: ${messages.length}');

      emit(ChatLoaded(
        orderInfo: orderInfo,
        messages: messages,
        isConnected: _chatService.isConnected,
      ));
      
      debugPrint('ChatBloc: ✅ Chat data loaded successfully');
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error loading chat data: $e');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      // Show sending state
      emit(currentState.copyWith(isSendingMessage: true));
      
      try {
        debugPrint('ChatBloc: 📤 Sending message: ${event.message}');
        debugPrint('ChatBloc: 🆔 Will be sent from current user ID: $_currentUserId');
        
        // Create the sent message immediately for better UX (optimistic update)
        // Current user sends message = TRUE (appears on RIGHT side)
        final sentMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: true, // TRUE = Current user message = RIGHT side
          time: _getCurrentTime(), // Use IST formatting
        );
        
        debugPrint('ChatBloc: 🎯 Creating optimistic message for RIGHT side');
        
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
          debugPrint('ChatBloc: ✅ Message sent successfully');
          
          // Update sending state to false
          emit(currentState.copyWith(
            messages: updatedMessages,
            isSendingMessage: false,
          ));
          
        } else {
          debugPrint('ChatBloc: ❌ Failed to send message');
          
          // Remove the optimistically added message on failure
          emit(currentState.copyWith(isSendingMessage: false));
          emit(const ChatError('Failed to send message. Please try again.'));
          
          // Restore the previous state without the failed message
          emit(currentState);
        }
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error sending message: $e');
        
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
        debugPrint('ChatBloc: 📨 Receiving message via event: ${event.message}');
        
        // Create new message - Other user message = FALSE (appears on LEFT side)
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: false, // FALSE = Other user message = LEFT side
          time: _getCurrentTime(), // Use IST formatting
        );
        
        debugPrint('ChatBloc: 🎯 Creating other user message for LEFT side');
        
        // Check if message already exists to avoid duplicates
        final messageExists = currentState.messages.any((m) => 
          m.message == event.message && 
          m.isUserMessage == false &&
          m.time == newMessage.time);
          
        if (!messageExists) {
          // Add message to list
          final updatedMessages = [...currentState.messages, newMessage];
          emit(currentState.copyWith(messages: updatedMessages));
          debugPrint('ChatBloc: ✅ Message received successfully via event');
        } else {
          debugPrint('ChatBloc: 🔄 Duplicate message via event, skipping');
        }
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error receiving message: $e');
      }
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null) {
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
        
        debugPrint('ChatBloc: 🎯 Started typing indicator');
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error starting typing: $e');
      }
    }
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (_currentRoomId != null) {
      try {
        _chatService.sendStopTyping(_currentRoomId!);
        _typingTimer?.cancel();
        debugPrint('ChatBloc: 🎯 Stopped typing indicator');
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error stopping typing: $e');
      }
    }
  }

  Future<void> _onRefreshChat(RefreshChat event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isRefreshing: true));
      
      try {
        await _chatService.refreshMessages();
        emit(currentState.copyWith(isRefreshing: false));
      } catch (e) {
        emit(currentState.copyWith(isRefreshing: false));
        debugPrint('ChatBloc: ❌ Error refreshing chat: $e');
      }
    }
  }

  void _onUpdateMessages(_UpdateMessages event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Debug: Count and show message directions
      final rightMessages = event.messages.where((m) => m.isUserMessage).length;
      final leftMessages = event.messages.where((m) => !m.isUserMessage).length;
      debugPrint('ChatBloc: 📊 Updating messages:');
      debugPrint('  - RIGHT side (current user): $rightMessages messages');
      debugPrint('  - LEFT side (other users): $leftMessages messages');
      debugPrint('  - Total messages: ${event.messages.length}');
      
      emit(currentState.copyWith(
        messages: event.messages,
        isSendingMessage: false,
      ));
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

  void _onAddIncomingMessage(_AddIncomingMessage event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Convert API message to UI message with SIMPLE logic
      final isFromCurrentUser = event.message.isFromCurrentUser(_currentUserId);
      
      final newChatMessage = ChatMessage(
        id: event.message.id,
        message: event.message.content,
        isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT, FALSE = Other user = LEFT
        time: _formatMessageTime(event.message.createdAt), // Use IST formatting
      );
      
      debugPrint('ChatBloc: 🔥 Adding incoming message:');
      debugPrint('  - Content: "${event.message.content}"');
      debugPrint('  - API Sender ID: "${event.message.senderId}"');
      debugPrint('  - Current User ID: "${_currentUserId ?? 'null'}"');
      debugPrint('  - From current user: $isFromCurrentUser');
      debugPrint('  - Will appear on: ${isFromCurrentUser ? 'RIGHT' : 'LEFT'} side');
      
      // Check if message already exists to avoid duplicates
      final messageExists = currentState.messages.any((m) => 
        m.id == newChatMessage.id ||
        (m.message == newChatMessage.message && 
         m.isUserMessage == newChatMessage.isUserMessage &&
         m.time == newChatMessage.time));
      
      if (!messageExists) {
        final updatedMessages = [...currentState.messages, newChatMessage];
        
        // Sort messages by timestamp
        updatedMessages.sort((a, b) {
          // Try to parse timestamp from ID if possible
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
        
        debugPrint('ChatBloc: ✅ Added incoming message');
        
        emit(currentState.copyWith(
          messages: updatedMessages,
        ));
      } else {
        debugPrint('ChatBloc: 🔄 Message already exists, skipping duplicate');
      }
    }
  }

  // IST Time formatting methods
  String _getCurrentTime() {
    return TimeUtils.formatChatMessageTime(TimeUtils.getCurrentIST());
  }

  String _formatMessageTime(DateTime dateTime) {
    return TimeUtils.formatChatMessageTime(dateTime);
  }

  String _formatOrderId(String orderId) {
    if (orderId.isEmpty) return '#2504';
    
    if (orderId.startsWith('#')) return orderId;
    
    if (orderId.length > 8) {
      return '#${orderId.substring(orderId.length - 6)}';
    }
    
    return '#$orderId';
  }

  // Get detailed polling information for debugging
  Map<String, dynamic> getPollingInfo() {
    return _chatService.getPollingInfo();
  }

  @override
  Future<void> close() {
    debugPrint('ChatBloc: 🗑️ Closing and cleaning up resources');
    
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
  final dynamic message; // ApiChatMessage type
  
  const _AddIncomingMessage(this.message);
  
  @override
  List<Object?> get props => [message];
}