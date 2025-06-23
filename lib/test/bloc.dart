// lib/bloc/chat_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'service.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;

  ChatBloc({required ChatService chatService})
      : _chatService = chatService,
        super(const ChatState()) {
    
    print('🔵 ChatBloc: Setting up socket callbacks');
    
    // Set up socket callbacks
    _chatService.onMessageReceived = (message) {
      print('🔵 ChatBloc: onMessageReceived callback triggered with message: ${message.content}');
      add(MessageReceived(message));
    };

    _chatService.onConnected = () {
      print('ChatService connected, updating BLoC state');
      emit(state.copyWith(
        status: ChatStatus.connected,
        isSocketConnected: true,
      ));
    };

    _chatService.onDisconnected = () {
      print('ChatService disconnected, updating BLoC state');
      emit(state.copyWith(
        status: ChatStatus.disconnected,
        isSocketConnected: false,
      ));
    };

    _chatService.onError = (error) {
      print('ChatService error: $error');
      emit(state.copyWith(
        status: ChatStatus.error,
        error: error,
      ));
    };

    print('🔵 ChatBloc: Socket callbacks set up successfully');

    // Register event handlers
    on<InitializeChat>(_onInitializeChat);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<SendMessage>(_onSendMessage);
    on<LoadMessageHistory>(_onLoadMessageHistory);
    on<MessageReceived>(_onMessageReceived);
    on<LoadChatRoom>(_onLoadChatRoom);
    on<ClearMessages>(_onClearMessages);
    on<MessageSendingFailed>(_onMessageSendingFailed);
    on<LoadChatRooms>(_onLoadChatRooms);
    on<MarkAsRead>(_onMarkAsRead);
    on<LoadMessageHistoryForRoom>(_onLoadMessageHistoryForRoom);
    on<SwitchToRoom>(_onSwitchToRoom);
  }

  void _onInitializeChat(InitializeChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    
    try {
      // Load message history first
      add(LoadMessageHistory());
      
      // Connect to socket
      add(ConnectSocket());
      
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onConnectSocket(ConnectSocket event, Emitter<ChatState> emit) {
    try {
      _chatService.connect();
      emit(state.copyWith(status: ChatStatus.loading));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to connect: ${e.toString()}',
      ));
    }
  }

  void _onDisconnectSocket(DisconnectSocket event, Emitter<ChatState> emit) {
    _chatService.disconnect();
    emit(state.copyWith(
      status: ChatStatus.disconnected,
      isSocketConnected: false,
    ));
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    print('🔵 ChatBloc: _onSendMessage called with content: "${event.content}"');
    // print('🔵 ChatBloc: testMode is: ${ChatService.testMode}');
    
    emit(state.copyWith(
      status: ChatStatus.sendingMessage,
      isSendingMessage: true,
    ));

    try {
      // if (ChatService.testMode) {
      //   print('🔵 ChatBloc: In test mode, calling _chatService.sendMessage');
      //   // In test mode, use the sendMessage method which will trigger onMessageReceived
      //   _chatService.sendMessage(event.content);
        
      //   print('🔵 ChatBloc: sendMessage called, waiting for callback');
        
      //   // The message will be added via the onMessageReceived callback
      //   emit(state.copyWith(
      //     status: ChatStatus.messageSent,
      //     isSendingMessage: false,
      //   ));
        
      //   print('🔵 ChatBloc: State updated to messageSent');
      // } else {
        print('🔵 ChatBloc: In production mode, calling sendMessageViaAPI');
        // Send via REST API for persistence in production mode
        final sentMessage = await _chatService.sendMessageViaAPI(
          content: event.content,
          messageType: event.messageType,
          targetRoomId: state.currentRoomId,
        );

        if (sentMessage != null) {
          // Add the sent message to the list only if it doesn't exist
          final messageExists = state.messages.any((msg) => 
              msg.id == sentMessage.id ||
              (msg.content == sentMessage.content && 
               msg.senderId == sentMessage.senderId &&
               msg.timestamp.difference(sentMessage.timestamp).abs().inSeconds < 5)
          );
          
          if (!messageExists) {
            final updatedMessages = List<ChatMessage>.from(state.messages)
              ..add(sentMessage);
            
            // Sort messages by timestamp
            updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            
            emit(state.copyWith(
              status: ChatStatus.messageSent,
              messages: updatedMessages,
              isSendingMessage: false,
            ));
          } else {
            emit(state.copyWith(
              status: ChatStatus.messageSent,
              isSendingMessage: false,
            ));
          }
        } else {
          add(const MessageSendingFailed('Failed to send message'));
        }
      // }
    } catch (e) {
      print('🔴 ChatBloc: Error in _onSendMessage: $e');
      add(MessageSendingFailed(e.toString()));
    }
  }

  void _onLoadMessageHistory(LoadMessageHistory event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingHistory: true));

    try {
      final messages = await _chatService.getMessageHistory(state.currentRoomId ?? _chatService.roomId);
      
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      emit(state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        status: state.isSocketConnected ? ChatStatus.connected : ChatStatus.disconnected,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load message history: ${e.toString()}',
        isLoadingHistory: false,
      ));
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    print('🔵 ChatBloc: _onMessageReceived called with message: ${event.message.content}');
    print('🔵 ChatBloc: Current message count: ${state.messages.length}');
    
    // Check if message already exists to avoid duplicates
    final messageExists = state.messages.any((msg) => 
        msg.id == event.message.id || 
        (msg.content == event.message.content && 
         msg.senderId == event.message.senderId &&
         msg.timestamp.difference(event.message.timestamp).abs().inSeconds < 5)
    );
    
    print('🔵 ChatBloc: Message already exists: $messageExists');
    
    if (!messageExists) {
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(event.message);
      
      // Sort messages by timestamp
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('🔵 ChatBloc: Adding new message to state. Total messages: ${updatedMessages.length}');
      
      emit(state.copyWith(
        status: ChatStatus.messageReceived,
        messages: updatedMessages,
      ));
      
      print('🔵 ChatBloc: State updated with new message');
    } else {
      print('🔵 ChatBloc: Message already exists, skipping duplicate');
    }
  }

  void _onLoadChatRoom(LoadChatRoom event, Emitter<ChatState> emit) async {
    try {
      // Get all chat rooms and find the one with matching orderId
      final chatRooms = await _chatService.getChatRooms();
      final chatRoom = chatRooms.firstWhere(
        (room) => room.orderId == event.orderId,
        orElse: () => throw Exception('Chat room not found'),
      );
      
      emit(state.copyWith(
        currentChatRoom: chatRoom,
        currentRoomId: chatRoom.roomId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load chat room: ${e.toString()}',
      ));
    }
  }

  void _onClearMessages(ClearMessages event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: [],
      status: ChatStatus.initial,
    ));
  }

  void _onMessageSendingFailed(MessageSendingFailed event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      status: ChatStatus.error,
      error: event.error,
      isSendingMessage: false,
    ));
  }

  // Additional methods for new functionality

  /// Get all chat rooms for the current user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      return await _chatService.getChatRooms();
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  /// Mark messages as read for a specific room
  Future<bool> markAsRead(String roomId) async {
    try {
      return await _chatService.markAsRead(
        roomId: roomId,
        userId: ChatService.userId,
      );
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// Load message history for a specific room
  Future<List<ChatMessage>> loadMessageHistoryForRoom(String roomId) async {
    try {
      final messages = await _chatService.getMessageHistory(roomId);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Error loading message history for room: $e');
      return [];
    }
  }

  // New event handlers

  void _onLoadChatRooms(LoadChatRooms event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingRooms: true));

    try {
      final chatRooms = await _chatService.getChatRooms();
      
      emit(state.copyWith(
        chatRooms: chatRooms,
        isLoadingRooms: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load chat rooms: ${e.toString()}',
        isLoadingRooms: false,
      ));
    }
  }

  void _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      final success = await _chatService.markAsRead(
        roomId: event.roomId,
        userId: ChatService.userId,
      );
      
      if (success) {
        print('Messages marked as read for room: ${event.roomId}');
      } else {
        print('Failed to mark messages as read for room: ${event.roomId}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _onLoadMessageHistoryForRoom(LoadMessageHistoryForRoom event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingHistory: true));

    try {
      final messages = await _chatService.getMessageHistory(event.roomId);
      
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      emit(state.copyWith(
        messages: messages,
        currentRoomId: event.roomId,
        isLoadingHistory: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load message history: ${e.toString()}',
        isLoadingHistory: false,
      ));
    }
  }

  void _onSwitchToRoom(SwitchToRoom event, Emitter<ChatState> emit) async {
    try {
      // Find the chat room with matching roomId
      final chatRoom = state.chatRooms.firstWhere(
        (room) => room.roomId == event.roomId,
        orElse: () => throw Exception('Chat room not found'),
      );
      
      // Update current room
      emit(state.copyWith(
        currentChatRoom: chatRoom,
        currentRoomId: event.roomId,
      ));
      
      // Load message history for the new room
      add(LoadMessageHistoryForRoom(event.roomId));
      
      // Mark messages as read
      add(MarkAsRead(event.roomId));
      
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to switch to room: ${e.toString()}',
      ));
    }
  }

  @override
  Future<void> close() {
    _chatService.dispose();
    return super.close();
  }

  // Getter for external access to chat service
  ChatService get chatService => _chatService;
}