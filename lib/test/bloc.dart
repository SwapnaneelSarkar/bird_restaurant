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
    
    // Set up socket callbacks
    _chatService.onMessageReceived = (message) {
      print('ChatService received message, adding to BLoC: ${message.content}');
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
    emit(state.copyWith(
      status: ChatStatus.sendingMessage,
      isSendingMessage: true,
    ));

    try {
      // Send via REST API for persistence
      final sentMessage = await _chatService.sendMessage(
        content: event.content,
        messageType: event.messageType,
      );

      if (sentMessage != null) {
        // Note: Don't send via socket as well, as the REST API should trigger the socket event
        // This prevents duplicate messages
        
        // Add the sent message to the list only if it doesn't exist
        final messageExists = state.messages.any((msg) => 
            msg.id == sentMessage.id ||
            (msg.content == sentMessage.content && 
             msg.senderId == sentMessage.senderId &&
             msg.createdAt.difference(sentMessage.createdAt).abs().inSeconds < 5)
        );
        
        if (!messageExists) {
          final updatedMessages = List<ChatMessage>.from(state.messages)
            ..add(sentMessage);
          
          // Sort messages by creation time
          updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
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
    } catch (e) {
      add(MessageSendingFailed(e.toString()));
    }
  }

  void _onLoadMessageHistory(LoadMessageHistory event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingHistory: true));

    try {
      final messages = await _chatService.getMessageHistory();
      
      // Sort messages by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
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
    print('Processing received message: ${event.message.content}');
    
    // Check if message already exists to avoid duplicates
    final messageExists = state.messages.any((msg) => 
        msg.id == event.message.id || 
        (msg.content == event.message.content && 
         msg.senderId == event.message.senderId &&
         msg.createdAt.difference(event.message.createdAt).abs().inSeconds < 5)
    );
    
    if (!messageExists) {
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(event.message);
      
      // Sort messages by creation time
      updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      print('Adding new message to state. Total messages: ${updatedMessages.length}');
      
      emit(state.copyWith(
        status: ChatStatus.messageReceived,
        messages: updatedMessages,
      ));
    } else {
      print('Message already exists, skipping duplicate');
    }
  }

  void _onLoadChatRoom(LoadChatRoom event, Emitter<ChatState> emit) async {
    try {
      final chatRoom = await _chatService.getChatRoom(event.orderId);
      
      emit(state.copyWith(
        chatRoom: chatRoom,
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

  @override
  Future<void> close() {
    _chatService.dispose();
    return super.close();
  }
}