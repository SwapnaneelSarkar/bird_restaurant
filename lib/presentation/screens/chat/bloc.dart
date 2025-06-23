import 'dart:async';
import 'dart:convert'; 
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
  final SocketChatService _chatService;
  Timer? _typingTimer;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentPartnerId;
  String? _fullOrderId;
  StreamSubscription? _chatServiceSubscription;
  StreamSubscription? _messageStreamSubscription;

  ChatBloc({SocketChatService? chatService}) 
    : _chatService = chatService ?? SocketChatService(),
      super(ChatInitial()) {
    
    debugPrint('ChatBloc: 🔵 Setting up socket callbacks and event handlers');
    
    // Set up socket callbacks FIRST
    _setupSocketCallbacks();
    
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
    on<MarkAsRead>(_onMarkAsRead);

    debugPrint('ChatBloc: ✅ Setup complete');
  }

  void _setupSocketCallbacks() {
    debugPrint('ChatBloc: 🔧 Setting up socket callbacks...');
    
    // Listen to chat service changes for general updates
    _chatService.addListener(_onChatServiceUpdate);
    
    // Listen to real-time message stream for immediate updates (ONLY for other users' messages)
    _messageStreamSubscription = _chatService.messageStream.listen(
      (message) {
        debugPrint('ChatBloc: 🔥 Received real-time message from socket: ${message.content}');
        debugPrint('ChatBloc: 🔍 Message from: ${message.senderId}');
        debugPrint('ChatBloc: 🔍 Current user: $_currentUserId');
        debugPrint('ChatBloc: 🔍 Is from current user: ${message.isFromCurrentUser(_currentUserId)}');
        
        // Only add if it's NOT from current user (avoid duplicates)
        if (!message.isFromCurrentUser(_currentUserId) && !isClosed) {
          debugPrint('ChatBloc: ✅ Adding incoming message from other user');
          add(_AddIncomingMessage(message));
        } else {
          debugPrint('ChatBloc: 🔄 Skipping own message to avoid duplicate');
        }
      },
      onError: (error) {
        debugPrint('ChatBloc: Error in message stream: $error');
      },
    );

    debugPrint('ChatBloc: ✅ Socket callbacks set up successfully');
  }

  // Getters for external access
  String? get currentOrderId => _fullOrderId;
  String? get currentPartnerId => _currentPartnerId;

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<ChatState> emit) async {
    // Emit loading state
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isUpdatingOrderStatus: true));
    }

    try {
      debugPrint('ChatBloc: 🔄 Updating order status to: ${event.newStatus}');
      debugPrint('ChatBloc: 🔍 Using FULL order ID: $_fullOrderId');
      
      // Use the FULL order ID, not the formatted one
      final orderIdToUse = _fullOrderId ?? event.orderId;
      debugPrint('ChatBloc: 🎯 API Call - Using order ID: $orderIdToUse');

      final success = await OrderService.updateOrderStatus(
        partnerId: event.partnerId,
        orderId: orderIdToUse,
        newStatus: event.newStatus,
      );

      if (success) {
        debugPrint('ChatBloc: ✅ Order status updated successfully');
        
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          
          // Update the order info in the current state
          final updatedOrderInfo = currentState.orderInfo.copyWith(
            status: OrderService.formatOrderStatus(event.newStatus),
          );
          
          // Update order details if they exist
          OrderDetails? updatedOrderDetails;
          if (currentState.orderDetails != null) {
            updatedOrderDetails = currentState.orderDetails!.copyWith(
              orderStatus: event.newStatus.toUpperCase(),
            );
          }
          
          emit(currentState.copyWith(
            orderInfo: updatedOrderInfo,
            orderDetails: updatedOrderDetails,
            isUpdatingOrderStatus: false,
            lastUpdateSuccess: true,
            lastUpdateMessage: 'Order status updated successfully!',
            lastUpdateTimestamp: DateTime.now(),
          ));
          
          debugPrint('ChatBloc: 🎯 Emitted success state with updated status: ${event.newStatus}');
        }
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error updating order status: $e');
      
      // Parse structured error if available
      String errorMessage = 'Failed to update order status. Please try again.';
      try {
        if (e.toString().contains('"status":"ERROR"')) {
          final startIndex = e.toString().indexOf('{');
          if (startIndex != -1) {
            final jsonStr = e.toString().substring(startIndex);
            final errorJson = jsonDecode(jsonStr);
            errorMessage = errorJson['message'] ?? errorMessage;
          }
        }
      } catch (parseError) {
        debugPrint('ChatBloc: Could not parse error details: $parseError');
      }
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          isUpdatingOrderStatus: false,
          lastUpdateSuccess: false,
          lastUpdateMessage: errorMessage,
          lastUpdateTimestamp: DateTime.now(),
        ));
        
        debugPrint('ChatBloc: 🎯 Emitted error state within ChatLoaded: $errorMessage');
      }
    }
  }  

  void _onChatServiceUpdate() {
    if (!isClosed) {
      // Convert chat service messages to chat state messages with read status
      final messages = _chatService.messages.map((apiMsg) {
        // Use the actual isFromCurrentUser method from ApiChatMessage
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        
        // Determine read status: blue tick if read by others, grey if not
        final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser,
          time: _formatTime(apiMsg.createdAt),
          isRead: isRead, // Include read status for tick color
        );
      }).toList();

      // Add internal event to update messages
      add(_UpdateMessages(messages));
      
      // Update connection status (socket status)
      add(_UpdateConnectionStatus(_chatService.isConnected));
    }
  }

  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      debugPrint('ChatBloc: 📱 Loading chat data for order: ${event.orderId}');
      
      // Store the FULL order ID without any formatting
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
      
      // Connect to socket and join the chat room (includes auto mark as read)
      await _chatService.connect();
      await _chatService.joinRoom(_currentRoomId!);
      
      // FETCH REAL ORDER STATUS FROM API
      String actualOrderStatus = 'Preparing'; // Default fallback
      try {
        if (_currentPartnerId != null) {
          final orderDetails = await OrderService.getOrderDetails(
            partnerId: _currentPartnerId!,
            orderId: _fullOrderId!,
          );
          if (orderDetails != null) {
            actualOrderStatus = OrderService.formatOrderStatus(orderDetails.orderStatus);
            debugPrint('ChatBloc: 📋 Retrieved actual order status: ${orderDetails.orderStatus} -> $actualOrderStatus');
          }
        }
      } catch (e) {
        debugPrint('ChatBloc: ⚠️ Could not fetch order details, using default status: $e');
      }
      
      // Create order info with REAL status and FORMATTED display ID (for UI only)
      final orderInfo = ChatOrderInfo(
        orderId: _formatOrderIdForDisplay(event.orderId),
        restaurantName: 'Your Restaurant',
        estimatedDelivery: '30 mins',
        status: actualOrderStatus, // Use real status from API
      );

      // Convert chat service messages to UI messages WITH READ STATUS
      final messages = _chatService.messages.map((apiMsg) {
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser,
          time: _formatTime(apiMsg.createdAt),
          isRead: isRead, // Include read status
        );
      }).toList();

      // Debug: Count and show message directions with read status
      final rightMessages = messages.where((m) => m.isUserMessage).length;
      final leftMessages = messages.where((m) => !m.isUserMessage).length;
      final readMessages = messages.where((m) => m.isRead).length;
      debugPrint('ChatBloc: 📊 Message summary:');
      debugPrint('  - RIGHT side (current user): $rightMessages messages');
      debugPrint('  - LEFT side (other users): $leftMessages messages');
      debugPrint('  - Read messages (blue tick): $readMessages messages');
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
      
      debugPrint('ChatBloc: ✅ Chat data loaded successfully with status: $actualOrderStatus');
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

      // Use the FULL order ID, not the formatted one
      final orderIdToUse = _fullOrderId ?? event.orderId;
      debugPrint('ChatBloc: 🎯 API Call - Using order ID: $orderIdToUse');

      final orderDetails = await OrderService.getOrderDetails(
        partnerId: event.partnerId,
        orderId: orderIdToUse,
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
          menuItems: {...currentState.menuItems, ...menuItems},
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
  }

  void _onUpdateMessages(_UpdateMessages event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Debug: Count and show message directions with read status
      final rightMessages = event.messages.where((m) => m.isUserMessage).length;
      final leftMessages = event.messages.where((m) => !m.isUserMessage).length;
      final readMessages = event.messages.where((m) => m.isRead).length;
      debugPrint('ChatBloc: 📊 Updating messages:');
      debugPrint('  - RIGHT side (current user): $rightMessages messages');
      debugPrint('  - LEFT side (other users): $leftMessages messages');
      debugPrint('  - Read messages (blue tick): $readMessages messages');
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
      final isRead = event.message.isReadByOthers(event.message.senderId);
      
      final newChatMessage = ChatMessage(
        id: event.message.id,
        message: event.message.content,
        isUserMessage: isFromCurrentUser,
        time: _formatTime(event.message.createdAt),
        isRead: isRead, // Include read status
      );
      
      debugPrint('ChatBloc: 🔥 Adding incoming message:');
      debugPrint('  - Content: "${event.message.content}"');
      debugPrint('  - API Sender ID: "${event.message.senderId}"');
      debugPrint('  - Current User ID: "${_currentUserId ?? 'null'}"');
      debugPrint('  - From current user: $isFromCurrentUser');
      debugPrint('  - Read status: $isRead');
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
        
        // DON'T create optimistic update - let the service handle it
        debugPrint('ChatBloc: 🎯 Sending via service without optimistic update');
        
        // Send message via chat service (API + Socket mark as read automatically)
        final success = await _chatService.sendMessage(_currentRoomId!, event.message);
        
        if (success) {
          debugPrint('ChatBloc: ✅ Message sent successfully');
          debugPrint('ChatBloc: 📖 Service automatically handled mark as read');
          
          // The message will be added via the service listener automatically
          // The service also handles mark as read automatically via socket
          // Just update the sending state
          emit(currentState.copyWith(
            isSendingMessage: false,
          ));
          
        } else {
          debugPrint('ChatBloc: ❌ Failed to send message');
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
        
        // Manually refresh messages from server
        await _chatService.refreshMessages();
        
        debugPrint('ChatBloc: ✅ Chat refreshed successfully');
        
        // The updated messages will be handled by the chat service listener
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          
          // Convert the refreshed messages with read status
          final refreshedMessages = _chatService.messages.map((apiMsg) {
            final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
            final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
            
            return ChatMessage(
              id: apiMsg.id,
              message: apiMsg.content,
              isUserMessage: isFromCurrentUser,
              time: _formatTime(apiMsg.createdAt),
              isRead: isRead, // Include read status
            );
          }).toList();
          
          emit(currentState.copyWith(
            messages: refreshedMessages,
            isRefreshing: false,
          ));
          
          // Mark messages as read after refresh via SOCKET
          add(MarkAsRead(_currentRoomId!));
        }
      } catch (e) {
        debugPrint('ChatBloc: ❌ Error refreshing chat: $e');
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: false));
        }
        
        emit(const ChatError('Failed to refresh chat. Please try again.'));
      }
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 📖 Marking messages as read for room: ${event.roomId}');
      debugPrint('ChatBloc: 📖 Using hybrid approach (Socket + API fallback)');
      
      final success = await _chatService.markAsRead(event.roomId);
      
      if (success) {
        debugPrint('ChatBloc: ✅ Messages marked as read successfully via socket/API');
        
        // The read status will be updated automatically via socket events
        // No need to manually refresh messages - socket handles it real-time
        debugPrint('ChatBloc: 📖 Read status will update automatically via socket events');
      } else {
        debugPrint('ChatBloc: ⚠️ Failed to mark messages as read');
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error marking messages as read: $e');
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

  // Get detailed connection information for debugging
  Map<String, dynamic> getConnectionInfo() {
    return _chatService.getConnectionInfo();
  }

  @override
  Future<void> close() {
    debugPrint('ChatBloc: 🗑️ Closing and cleaning up resources');
    
    // Cancel timers
    _typingTimer?.cancel();
    
    // Cancel subscriptions
    _chatServiceSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    
    // Disconnect and dispose chat service
    _chatService.removeListener(_onChatServiceUpdate);
    _chatService.disconnect();
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