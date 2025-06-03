// lib/presentation/screens/chat_list/state.dart

import 'package:equatable/equatable.dart';
import '../../../models/chat_room_model.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();
  
  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatRoom> chatRooms;
  final List<ChatRoom> filteredChatRooms;
  final bool isSearching;
  final String searchQuery;
  
  const ChatListLoaded({
    required this.chatRooms,
    required this.filteredChatRooms,
    this.isSearching = false,
    this.searchQuery = '',
  });
  
  @override
  List<Object?> get props => [chatRooms, filteredChatRooms, isSearching, searchQuery];
  
  ChatListLoaded copyWith({
    List<ChatRoom>? chatRooms,
    List<ChatRoom>? filteredChatRooms,
    bool? isSearching,
    String? searchQuery,
  }) {
    return ChatListLoaded(
      chatRooms: chatRooms ?? this.chatRooms,
      filteredChatRooms: filteredChatRooms ?? this.filteredChatRooms,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChatListError extends ChatListState {
  final String message;
  
  const ChatListError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ChatListEmpty extends ChatListState {
  final String message;
  
  const ChatListEmpty({
    this.message = 'No chats available',
  });
  
  @override
  List<Object?> get props => [message];
}