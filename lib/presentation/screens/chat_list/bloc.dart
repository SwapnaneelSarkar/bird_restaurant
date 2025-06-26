// lib/presentation/screens/chat_list/bloc.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../../models/chat_room_model.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  Timer? _debounce;
  
  ChatListBloc() : super(ChatListInitial()) {
    
    debugPrint('ChatListBloc: Initializing...');
    
    // Register event handlers
    on<LoadChatRooms>(_onLoadChatRooms);
    on<RefreshChatRooms>(_onRefreshChatRooms);
    on<SearchChatRooms>(_onSearchChatRooms);
    on<ClearSearch>(_onClearSearch);
    on<SelectChatRoom>(_onSelectChatRoom);
    
    debugPrint('ChatListBloc: Event handlers registered');
  }

  Future<void> _onLoadChatRooms(LoadChatRooms event, Emitter<ChatListState> emit) async {
    emit(ChatListLoading());
    
    try {
      debugPrint('ChatListBloc: Loading chat rooms');
      
      final chatRooms = await _fetchChatRooms();
      
      if (chatRooms.isEmpty) {
        emit(const ChatListEmpty());
      } else {
        emit(ChatListLoaded(
          chatRooms: chatRooms,
          filteredChatRooms: chatRooms,
        ));
      }
      
      debugPrint('ChatListBloc: Successfully loaded ${chatRooms.length} chat rooms');
    } catch (e) {
      debugPrint('ChatListBloc: Error loading chat rooms: $e');
      emit(ChatListError('Failed to load chats: $e'));
    }
  }

  Future<void> _onRefreshChatRooms(RefreshChatRooms event, Emitter<ChatListState> emit) async {
    try {
      debugPrint('ChatListBloc: Refreshing chat rooms');
      
      final chatRooms = await _fetchChatRooms();
      
      if (chatRooms.isEmpty) {
        emit(const ChatListEmpty());
      } else {
        // Maintain search state if currently searching
        if (state is ChatListLoaded) {
          final currentState = state as ChatListLoaded;
          if (currentState.isSearching) {
            final filteredRooms = _filterChatRooms(chatRooms, currentState.searchQuery);
            emit(ChatListLoaded(
              chatRooms: chatRooms,
              filteredChatRooms: filteredRooms,
              isSearching: true,
              searchQuery: currentState.searchQuery,
            ));
          } else {
            emit(ChatListLoaded(
              chatRooms: chatRooms,
              filteredChatRooms: chatRooms,
            ));
          }
        } else {
          emit(ChatListLoaded(
            chatRooms: chatRooms,
            filteredChatRooms: chatRooms,
          ));
        }
      }
      
      debugPrint('ChatListBloc: Successfully refreshed ${chatRooms.length} chat rooms');
    } catch (e) {
      debugPrint('ChatListBloc: Error refreshing chat rooms: $e');
      // Keep current state and show error in UI instead of replacing state
      if (state is ChatListLoaded) {
        // Could show a snackbar or toast here
      } else {
        emit(ChatListError('Failed to refresh chats: $e'));
      }
    }
  }

  void _onSearchChatRooms(SearchChatRooms event, Emitter<ChatListState> emit) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (state is ChatListLoaded) {
        final currentState = state as ChatListLoaded;
        
        if (event.query.isEmpty) {
          emit(currentState.copyWith(
            filteredChatRooms: currentState.chatRooms,
            isSearching: false,
            searchQuery: '',
          ));
        } else {
          final filteredRooms = _filterChatRooms(currentState.chatRooms, event.query);
          emit(currentState.copyWith(
            filteredChatRooms: filteredRooms,
            isSearching: true,
            searchQuery: event.query,
          ));
        }
      }
    });
  }

  void _onClearSearch(ClearSearch event, Emitter<ChatListState> emit) {
    if (state is ChatListLoaded) {
      final currentState = state as ChatListLoaded;
      emit(currentState.copyWith(
        filteredChatRooms: currentState.chatRooms,
        isSearching: false,
        searchQuery: '',
      ));
    }
  }

  void _onSelectChatRoom(SelectChatRoom event, Emitter<ChatListState> emit) {
    debugPrint('ChatListBloc: Chat room selected - Room ID: ${event.roomId}, Order ID: ${event.orderId}');
    // This event is handled in the UI for navigation
  }

  Future<List<ChatRoom>> _fetchChatRooms() async {
    try {
      // Get authentication data
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }
      
      if (userId == null || userId.isEmpty) {
        throw Exception('No user ID found. Please login again.');
      }

      // Construct API URL
      final url = Uri.parse('${ApiConstants.baseUrl}/chat/rooms/?userId=$userId&userType=partner');
      
      debugPrint('ChatListBloc: Fetching chat rooms from: $url');
      debugPrint('ChatListBloc: Using token: ${token.substring(0, 20)}...');
      debugPrint('ChatListBloc: Using userId: $userId');

      // Make API request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('ChatListBloc: Response status: ${response.statusCode}');
      debugPrint('ChatListBloc: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final chatRoomResponse = ChatRoomResponse.fromJson(jsonData);
        
        // Sort chat rooms by last message time (most recent first)
        final sortedRooms = chatRoomResponse.chatRooms..sort((a, b) => 
          b.lastMessageTime.compareTo(a.lastMessageTime));
        
        return sortedRooms;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        debugPrint('ChatListBloc: No chat rooms found (404)');
        return [];
      } else {
        throw Exception('Failed to fetch chat rooms. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatListBloc: Error in _fetchChatRooms: $e');
      rethrow;
    }
  }

  List<ChatRoom> _filterChatRooms(List<ChatRoom> chatRooms, String query) {
    if (query.isEmpty) return chatRooms;
    
    final lowercaseQuery = query.toLowerCase();
    
    return chatRooms.where((room) {
      // Search in order ID
      final orderIdMatch = room.orderId.toLowerCase().contains(lowercaseQuery);
      
      // Search in last message
      final messageMatch = room.lastMessage.toLowerCase().contains(lowercaseQuery);
      
      // Search in user ID (if available)
      final userIdMatch = room.userParticipant?.userId.toLowerCase().contains(lowercaseQuery) ?? false;
      
      return orderIdMatch || messageMatch || userIdMatch;
    }).toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}