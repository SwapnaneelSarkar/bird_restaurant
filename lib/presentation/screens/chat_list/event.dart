// lib/presentation/screens/chat_list/event.dart

import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChatRooms extends ChatListEvent {
  const LoadChatRooms();
}

class RefreshChatRooms extends ChatListEvent {
  const RefreshChatRooms();
}

class SearchChatRooms extends ChatListEvent {
  final String query;
  
  const SearchChatRooms(this.query);
  
  @override
  List<Object?> get props => [query];
}

class ClearSearch extends ChatListEvent {
  const ClearSearch();
}

class SelectChatRoom extends ChatListEvent {
  final String roomId;
  final String orderId;
  
  const SelectChatRoom({
    required this.roomId,
    required this.orderId,
  });
  
  @override
  List<Object?> get props => [roomId, orderId];
}

class StartAutoRefresh extends ChatListEvent {
  const StartAutoRefresh();
}

class StopAutoRefresh extends ChatListEvent {
  const StopAutoRefresh();
}