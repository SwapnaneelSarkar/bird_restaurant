// lib/presentation/screens/chat/bloc.dart - COMPLETE REWRITE BASED ON ACTUAL CODE STRUCTURE

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_services.dart';
import '../../../services/menu_item_service.dart';
import '../../../services/token_service.dart';
import '../../../services/order_service.dart';
import '../../../utils/time_utils.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final PollingChatService _chatService;
  Timer? _typingTimer;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentPartnerId;
  String? _fullOrderId; // Store the FULL order ID separately
  StreamSubscription? _chatServiceSubscription;
  StreamSubscription? _messageStreamSubscription;

  ChatBloc({PollingChatService? chatService}) 
    : _chatService = chatService ?? PollingChatService(),
      super(ChatInitial()) {
    
    // Register all event handlers
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<RefreshChat>(_onRefreshChat);
    on<ShowOrderOptions>(_onShowOrderOptions);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<ChangeOrderStatus>(_onChangeOrderStatus);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<ForceRefreshMenuItems>(_onForceRefreshMenuItems);
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

  // Getters for external access
  String? get currentOrderId => _fullOrderId; // Return the FULL order ID
  String? get currentPartnerId => _currentPartnerId;

  void _onChatServiceUpdate() {
    if (!isClosed) {
      // Convert chat service messages to chat state messages
      final messages = _chatService.messages.map((apiMsg) {
        // Use the actual isFromCurrentUser method from ApiChatMessage
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
          time: _formatTime(apiMsg.createdAt),
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
      
      // CRITICAL: Store the FULL order ID without any formatting
      _fullOrderId = event.orderId;
      debugPrint('ChatBloc: 💾 Stored FULL order ID: $_fullOrderId');
      
      // Get current user ID and partner ID
      _currentUserId = await TokenService.getUserId();
      _currentPartnerId = await OrderService.getPartnerId();
      
      if (_currentUserId == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }

      debugPrint('ChatBloc: 🆔 Current User ID: $_currentUserId');
      debugPrint('ChatBloc: 🆔 Current Partner ID: $_currentPartnerId');

      // Set the room ID (use full order ID for chat room)
      _currentRoomId = event.orderId.isNotEmpty ? event.orderId : 'default_room';
      
      // Join the chat room (this will load history and start polling)
      await _chatService.joinRoom(_currentRoomId!);
      
      // Create order info with FORMATTED display ID (for UI only)
      final orderInfo = ChatOrderInfo(
        orderId: _formatOrderIdForDisplay(event.orderId),
        restaurantName: 'Your Restaurant',
        estimatedDelivery: '30 mins',
        status: 'Preparing',
      );

      // Convert chat service messages to UI messages
      final messages = _chatService.messages.map((apiMsg) {
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT, FALSE = Other user = LEFT
          time: _formatTime(apiMsg.createdAt),
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
        menuItems: const {},
        orderDetails: null,
        isLoadingOrderDetails: false,
        isSendingMessage: false,
        isRefreshing: false,
      ));
      
      debugPrint('ChatBloc: ✅ Chat data loaded successfully');
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error loading chat data: $e');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }

  void _onShowOrderOptions(ShowOrderOptions event, Emitter<ChatState> emit) {
    debugPrint('ChatBloc: 📋 Showing order options for order: ${event.orderId}');
    emit(OrderOptionsVisible(
      orderId: event.orderId,
      partnerId: event.partnerId,
    ));
  }

  Future<void> _onLoadOrderDetails(LoadOrderDetails event, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 📄 Loading order details for order: ${event.orderId}');
      debugPrint('ChatBloc: 🔍 Using FULL order ID: $_fullOrderId');
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(isLoadingOrderDetails: true));
      } else {
        emit(OrderDetailsLoading());
      }

      // CRITICAL: Use the FULL order ID, not the formatted one
      final orderIdToUse = _fullOrderId ?? event.orderId;
      debugPrint('ChatBloc: 🎯 API Call - Using order ID: $orderIdToUse');

      final orderDetails = await OrderService.getOrderDetails(
        partnerId: event.partnerId,
        orderId: orderIdToUse, // Pass the FULL order ID to API
      );

      debugPrint('ChatBloc: ✅ Order details loaded successfully');
      debugPrint('ChatBloc: 📦 Found ${orderDetails?.items.length} items in order');
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          orderDetails: orderDetails,
          isLoadingOrderDetails: false,
        ));
        
        // Load menu items with better error handling
        await _loadMenuItemsForOrder(orderDetails!, emit);
      } else {
        // For standalone order details loading
        emit(OrderDetailsLoaded(orderDetails!));
        
        // Load menu items immediately for standalone loading
        final menuItems = await MenuItemService.getMenuItems(orderDetails.allMenuIds);
        emit(OrderDetailsLoaded(orderDetails, menuItems: menuItems));
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error loading order details: $e');
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(isLoadingOrderDetails: false));
      }
      
      emit(const ChatError('Failed to load order details. Please try again.'));
    }
  }

  // Load menu items for order with better error handling
  Future<void> _loadMenuItemsForOrder(OrderDetails orderDetails, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 🍽️ Loading menu items for order items');
      
      // Get all unique menu IDs from the order
      final menuIds = orderDetails.allMenuIds;
      debugPrint('ChatBloc: 📋 Menu IDs to fetch: $menuIds');
      
      if (menuIds.isEmpty) {
        debugPrint('ChatBloc: ⚠️ No menu items to fetch');
        return;
      }

      // Fetch menu items in batch for better performance using the actual method
      final menuItems = await MenuItemService.getMenuItems(menuIds);
      debugPrint('ChatBloc: ✅ Loaded ${menuItems.length} out of ${menuIds.length} menu items');

      // Log which items were successfully loaded and which failed
      for (final menuId in menuIds) {
        if (menuItems.containsKey(menuId)) {
          final item = menuItems[menuId]!;
          debugPrint('ChatBloc:   ✅ ${item.name} (ID: $menuId)');
        } else {
          debugPrint('ChatBloc:   ❌ Failed to load menu item with ID: $menuId');
        }
      }

      // Update the state with the menu items
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          menuItems: {...currentState.menuItems, ...menuItems}, // Merge with existing
        ));
        
        debugPrint('ChatBloc: 🎯 Updated state with ${menuItems.length} menu items');
      } else if (state is OrderDetailsLoaded) {
        // Handle standalone order details loading
        final currentState = state as OrderDetailsLoaded;
        emit(OrderDetailsLoaded(
          currentState.orderDetails,
          menuItems: {...(currentState.menuItems ?? {}), ...menuItems},
        ));
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error loading menu items: $e');
      // Don't emit error state for menu items - just log the error
      // The UI will gracefully fall back to showing menu IDs
    }
  }

  Future<void> _onForceRefreshMenuItems(ForceRefreshMenuItems event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      if (currentState.orderDetails != null) {
        debugPrint('ChatBloc: 🔄 Force refreshing menu items');
        
        // Clear existing menu items
        emit(currentState.copyWith(menuItems: {}));
        
        // Reload menu items
        await _loadMenuItemsForOrder(currentState.orderDetails!, emit);
      }
    }
  }

  void _onChangeOrderStatus(ChangeOrderStatus event, Emitter<ChatState> emit) {
    debugPrint('ChatBloc: 🔄 Opening order status change for order: ${event.orderId}');
    // This will trigger the status change bottom sheet in the UI
    // The actual status change happens in _onUpdateOrderStatus
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 🔄 Updating order status to: ${event.newStatus}');
      debugPrint('ChatBloc: 🔍 Using FULL order ID: $_fullOrderId');
      
      // CRITICAL: Use the FULL order ID, not the formatted one
      final orderIdToUse = _fullOrderId ?? event.orderId;
      debugPrint('ChatBloc: 🎯 API Call - Using order ID: $orderIdToUse');

      final success = await OrderService.updateOrderStatus(
        partnerId: event.partnerId,
        orderId: orderIdToUse, // Pass the FULL order ID to API
        newStatus: event.newStatus,
      );

      if (success) {
        debugPrint('ChatBloc: ✅ Order status updated successfully');
        
        // Update the order info in the current state
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          final updatedOrderInfo = currentState.orderInfo.copyWith(
            status: OrderService.formatOrderStatus(event.newStatus),
          );
          
          emit(currentState.copyWith(orderInfo: updatedOrderInfo));
        }
        
        // Optionally refresh order details if they are loaded
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          if (currentState.orderDetails != null) {
            add(LoadOrderDetails(
              orderId: event.orderId,
              partnerId: event.partnerId,
            ));
          }
        }
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error updating order status: $e');
      emit(const ChatError('Failed to update order status. Please try again.'));
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

  void _onAddIncomingMessage(_AddIncomingMessage event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Convert API message to UI message
      final isFromCurrentUser = event.message.isFromCurrentUser(_currentUserId);
      
      final newChatMessage = ChatMessage(
        id: event.message.id,
        message: event.message.content,
        isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT, FALSE = Other user = LEFT
        time: _formatTime(event.message.createdAt),
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
        debugPrint('ChatBloc: 📤 Sending message: ${event.message}');
        debugPrint('ChatBloc: 🆔 Will be sent from current user ID: $_currentUserId');
        
        // Create the sent message immediately for better UX (optimistic update)
        final sentMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: true, // TRUE = Current user message = RIGHT side
          time: _getCurrentTime(),
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
        }
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error sending message: $e');
        emit(currentState.copyWith(isSendingMessage: false));
        emit(const ChatError('Failed to send message. Please try again.'));
      }
    }
  }

  void _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) {
    // Handle received messages if needed
    debugPrint('ChatBloc: 📥 Received message: ${event.message}');
  }

  Future<void> _onStartTyping(StartTyping event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        debugPrint('ChatBloc: ⌨️ Starting typing indicator');
        _chatService.sendTyping(_currentRoomId!);
        
        // Cancel any existing timer
        _typingTimer?.cancel();
        
        // Set a timer to auto-stop typing after 3 seconds
        _typingTimer = Timer(const Duration(seconds: 3), () {
          add(StopTyping());
        });
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error starting typing: $e');
      }
    }
  }

  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        debugPrint('ChatBloc: 🛑 Stopping typing indicator');
        _chatService.sendStopTyping(_currentRoomId!);
        _typingTimer?.cancel();
        debugPrint('ChatBloc: 🛑 Stopped typing indicator');
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error stopping typing: $e');
      }
    }
  }

  Future<void> _onRefreshChat(RefreshChat event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        debugPrint('ChatBloc: 🔄 Refreshing chat history');
        
        // Show refreshing state briefly
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: true));
        }
        
        // Manually trigger a poll for new messages
        await _chatService.refreshMessages();
        
        // Reload complete chat history from server
        await _chatService.loadChatHistory(_currentRoomId!);
        debugPrint('ChatBloc: ✅ Chat refreshed successfully');
        
        // The updated messages will be handled by the chat service listener
        // Just update the refreshing state
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          
          // Convert the refreshed messages
          final refreshedMessages = _chatService.messages.map((apiMsg) {
            final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
            
            return ChatMessage(
              id: apiMsg.id,
              message: apiMsg.content,
              isUserMessage: isFromCurrentUser, // TRUE = Current user = RIGHT, FALSE = Other user = LEFT
              time: _formatTime(apiMsg.createdAt),
            );
          }).toList();
          
          emit(currentState.copyWith(
            messages: refreshedMessages,
            isRefreshing: false,
          ));
        }
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error refreshing chat: $e');
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: false));
        }
        
        // Show error message briefly
        emit(const ChatError('Failed to refresh chat. Please try again.'));
      }
    }
  }

  // Helper method to format order ID for display (shortened version)
  String _formatOrderIdForDisplay(String orderId) {
    if (orderId.length > 8) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId;
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
  final istTime = TimeUtils.toIST(dateTime);
  final istNow = TimeUtils.getCurrentIST();
  
  // Check if it's today
  if (TimeUtils.isToday(dateTime)) {
    // Today: show 12-hour IST time (e.g., "2:30 PM")
    return TimeUtils.formatChatMessageTime(dateTime);
  } else if (TimeUtils.isYesterday(dateTime)) {
    // Yesterday: show "Yesterday 2:30 PM"
    final timeStr = TimeUtils.formatChatMessageTime(dateTime);
    return 'Yesterday $timeStr';
  } else {
    // Older: show date with time (e.g., "12/25/2024 2:30 PM")
    final dateStr = '${istTime.month.toString().padLeft(2, '0')}/${istTime.day.toString().padLeft(2, '0')}/${istTime.year}';
    final timeStr = TimeUtils.formatChatMessageTime(dateTime);
    return '$dateStr $timeStr';
  }
}

  // Helper method to get current time
  String _getCurrentTime() {
  final istNow = TimeUtils.getCurrentIST();
  return TimeUtils.formatChatMessageTime(istNow);
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
  List<Object> get props => [messages];
}

class _UpdateConnectionStatus extends ChatEvent {
  final bool isConnected;
  
  const _UpdateConnectionStatus(this.isConnected);
  
  @override
  List<Object> get props => [isConnected];
}

class _AddIncomingMessage extends ChatEvent {
  final ApiChatMessage message;
  
  const _AddIncomingMessage(this.message);
  
  @override
  List<Object> get props => [message];
}