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
  Timer? _updateDebounceTimer;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentPartnerId;
  String? _fullOrderId;
  StreamSubscription? _chatServiceSubscription;
  StreamSubscription? _messageStreamSubscription;
  StreamSubscription? _readStatusStreamSubscription;
  List<ChatMessage> _lastEmittedMessages = [];

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
    on<AppResume>(_onAppResume);
    // on<MarkMessageAsSeen>(_onMarkMessageAsSeen);

    debugPrint('ChatBloc: ✅ Setup complete');
  }

  void _setupSocketCallbacks() {
    // Listen to chat service changes for general updates
    _chatService.addListener(_onChatServiceUpdate);
    
    // Listen to real-time message stream for immediate updates (ONLY for other users' messages)
    _messageStreamSubscription = _chatService.messageStream.listen(
      (message) {
        // Only add if it's NOT from current user (avoid duplicates)
        if (!message.isFromCurrentUser(_currentUserId) && !isClosed) {
          // Check if we're in a loaded state before adding
          if (state is ChatLoaded) {
            add(_AddIncomingMessage(message));
          }
        }
      },
      onError: (error) {
        // Handle error silently
      },
    );

    // NEW: Listen to real-time read status stream for blue tick updates
    _readStatusStreamSubscription = _chatService.readStatusStream.listen(
      (readStatusData) {
        if (!isClosed && state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          
          // Handle different types of read status updates
          if (readStatusData['type'] == 'typing_blue_tick_update') {
            // NEW: Handle typing-based blue tick updates
            
            // Update messages with new read status
            final updatedMessages = currentState.messages.map((chatMsg) {
              // Find corresponding API message
              final apiMessage = _chatService.messages.firstWhere(
                (apiMsg) => apiMsg.id == chatMsg.id,
                orElse: () => ApiChatMessage(
                  id: chatMsg.id,
                  roomId: '',
                  senderId: '',
                  senderType: '',
                  content: chatMsg.message,
                  messageType: 'text',
                  readBy: [],
                  createdAt: DateTime.now(),
                ),
              );
              
              // Update read status - use the isRead property directly
              final isRead = apiMessage.isRead;
              
              return ChatMessage(
                id: chatMsg.id,
                message: chatMsg.message,
                isUserMessage: chatMsg.isUserMessage,
                time: chatMsg.time,
                isRead: isRead, // Updated read status
              );
            }).toList();
            
            // Emit updated state with new read status
            emit(currentState.copyWith(messages: updatedMessages));
          } else {
            // Handle regular message seen updates
            // Update messages with new read status
            final updatedMessages = currentState.messages.map((chatMsg) {
              // Find corresponding API message
              final apiMessage = _chatService.messages.firstWhere(
                (apiMsg) => apiMsg.id == chatMsg.id,
                orElse: () => ApiChatMessage(
                  id: chatMsg.id,
                  roomId: '',
                  senderId: '',
                  senderType: '',
                  content: chatMsg.message,
                  messageType: 'text',
                  readBy: [],
                  createdAt: DateTime.now(),
                ),
              );
              
              // Update read status - use the isRead property directly
              final isRead = apiMessage.isRead;
              
              return ChatMessage(
                id: chatMsg.id,
                message: chatMsg.message,
                isUserMessage: chatMsg.isUserMessage,
                time: chatMsg.time,
                isRead: isRead, // Updated read status
              );
            }).toList();
            
            // Emit updated state with new read status
            emit(currentState.copyWith(messages: updatedMessages));
          }
        }
      },
      onError: (error) {
        // Handle error silently
      },
    );
  }

  // Getters for external access
  String? get currentOrderId => _fullOrderId;
  String? get currentPartnerId => _currentPartnerId;
  String? get currentRoomId => _currentRoomId;

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
    if (!isClosed && state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Convert chat service messages to chat state messages with read status
      final newMessages = _chatService.messages.map((apiMsg) {
        // Use the actual isFromCurrentUser method from ApiChatMessage
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        
        // Determine read status: use the isRead property directly
        final isRead = apiMsg.isRead;
        
        return ChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser,
          time: _formatTime(apiMsg.createdAt),
          isRead: isRead, // Include read status for tick color
        );
      }).toList();

      // CRITICAL: Only update if messages have actually changed
      final hasChanges = newMessages.length != _lastEmittedMessages.length ||
          !_areMessageListsEqual(newMessages, _lastEmittedMessages);
      
      if (hasChanges) {
        // Update the last emitted messages
        _lastEmittedMessages = List.from(newMessages);
        
        // Add internal event to update messages
        add(_UpdateMessages(newMessages));
      }
      
      // Update connection status (socket status) - only if changed
      if (currentState.isConnected != _chatService.isConnected) {
        add(_UpdateConnectionStatus(_chatService.isConnected));
      }
    }
  }

  // Helper method to compare message lists
  bool _areMessageListsEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final msg1 = list1[i];
      final msg2 = list2[i];
      
      if (msg1.id != msg2.id ||
          msg1.message != msg2.message ||
          msg1.isUserMessage != msg2.isUserMessage ||
          msg1.isRead != msg2.isRead) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      // Store the FULL order ID without any formatting
      _fullOrderId = event.orderId;
      
      // Get current user ID and partner ID
      _currentUserId = await TokenService.getUserId();
      _currentPartnerId = await OrderService.getPartnerId();
      
      if (_currentUserId == null) {
        emit(const ChatError('User not authenticated'));
        return;
      }

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
          }
        }
      } catch (e) {
        // Use default status if order details fetch fails
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

      // Create the initial state
      final initialState = ChatLoaded(
        orderInfo: orderInfo,
        messages: messages,
        isConnected: _chatService.isConnected,
        menuItems: const {},
        orderDetails: null,
        isLoadingOrderDetails: false,
        isSendingMessage: false,
        isRefreshing: false,
      );
      
      // Initialize the last emitted messages
      _lastEmittedMessages = List.from(messages);
      
      emit(initialState);
      
      // OPTIMIZATION: Load order details immediately after initial state
      if (_currentPartnerId != null) {
        try {
          final orderDetails = await OrderService.getOrderDetails(
            partnerId: _currentPartnerId!,
            orderId: _fullOrderId!,
          );
          
          if (orderDetails != null && state is ChatLoaded) {
            final currentState = state as ChatLoaded;
            emit(currentState.copyWith(
              orderDetails: orderDetails,
              isLoadingOrderDetails: false,
            ));
            
            // Load menu items in parallel for better performance
            _loadMenuItemsForOrder(orderDetails, emit);
          }
        } catch (e) {
          // Don't fail the entire chat load if order details fail
        }
      }
      
      // Small delay to prevent immediate update cycle
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
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
      
      // Update the last emitted messages
      _lastEmittedMessages = List.from(event.messages);
      
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
      
      // Check if message already exists to avoid duplicates (only by ID)
      final messageExists = currentState.messages.any((m) => m.id == newChatMessage.id);
      
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
            // Handle sorting error silently
          }
          return a.id.compareTo(b.id);
        });
        
        emit(currentState.copyWith(
          messages: updatedMessages,
        ));
        
        // NEW: Emit typing when new message is received (partner is reading)
        if (!isFromCurrentUser) {
          add(const StartTyping());
          
          // Stop typing after 3 seconds
          Timer(const Duration(seconds: 3), () {
            if (!isClosed) {
              add(const StopTyping());
            }
          });
        }
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
        // Send message via chat service (API + Socket mark as read automatically)
        final success = await _chatService.sendMessage(_currentRoomId!, event.message);
        
        if (success) {
          // The message will be added via the service listener automatically
          // The service also handles mark as read automatically via socket
          // Just update the sending state
          emit(currentState.copyWith(
            isSendingMessage: false,
          ));
          
        } else {
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
        _chatService.sendTyping(_currentRoomId!);
        
        // Cancel any existing timer
        _typingTimer?.cancel();
        
        // Note: Timer is now controlled by the view layer for page lifecycle management
        // The view handles when to stop typing based on page open/close and new message events
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        _chatService.sendStopTyping(_currentRoomId!);
        _typingTimer?.cancel();
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _onRefreshChat(RefreshChat event, Emitter<ChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        // Show refreshing state briefly
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: true));
        }
        
        // Manually refresh messages from server
        await _chatService.refreshMessages();
        
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
        if (state is ChatLoaded) {
          final currentState = state as ChatLoaded;
          emit(currentState.copyWith(isRefreshing: false));
        }
        
        emit(const ChatError('Failed to refresh chat. Please try again.'));
      }
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    if (_currentRoomId == null) {
      return;
    }

    try {
      // Use the chat service to mark messages as read
      final success = await _chatService.markAsRead(_currentRoomId!);
      
      if (!success) {
        // Handle failure silently
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onAppResume(AppResume event, Emitter<ChatState> emit) async {
    try {
      // Handle app resume in the chat service
      await _chatService.handleAppResume();
      
      // If we're in a loaded state, refresh the messages
      if (state is ChatLoaded && _currentRoomId != null) {
        // Force refresh messages from the service
        await _chatService.refreshMessages();
        
        // Update the state with refreshed messages
        final currentState = state as ChatLoaded;
        final updatedMessages = _chatService.messages.map((apiMsg) {
          final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
          final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
          
          return ChatMessage(
            id: apiMsg.id,
            message: apiMsg.content,
            isUserMessage: isFromCurrentUser,
            time: _formatTime(apiMsg.createdAt),
            isRead: isRead,
          );
        }).toList();
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          lastUpdateTimestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Helper method to format order ID for display (showing more characters)
  String _formatOrderIdForDisplay(String orderId) {
    if (orderId.length > 12) {
      return orderId.substring(0, 12) + '...';
    }
    return orderId;
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final istTime = TimeUtils.toIST(dateTime);
    // Always use IST for all checks and formatting
    if (TimeUtils.isToday(istTime)) {
      // Today: show 12-hour IST time (e.g., "2:30 PM")
      return TimeUtils.formatChatMessageTime(istTime);
    } else if (TimeUtils.isYesterday(istTime)) {
      // Yesterday: show "Yesterday 2:30 PM"
      final timeStr = TimeUtils.formatChatMessageTime(istTime);
      return 'Yesterday $timeStr';
    } else {
      // Older: show date with time (e.g., "12/25/2024 2:30 PM")
      final dateStr = '${istTime.month.toString().padLeft(2, '0')}/${istTime.day.toString().padLeft(2, '0')}/${istTime.year}';
      final timeStr = TimeUtils.formatChatMessageTime(istTime);
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

  // NEW: Check connection health
  Future<Map<String, dynamic>> checkConnectionHealth() async {
    return await _chatService.checkConnectionHealth();
  }

  // NEW: Force reconnect socket
  Future<void> forceReconnect() async {
    _chatService.disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await _chatService.connect();
    if (_currentRoomId != null) {
      await _chatService.joinRoom(_currentRoomId!);
    }
  }

  @override
  Future<void> close() {
    // Cancel timers
    _typingTimer?.cancel();
    _updateDebounceTimer?.cancel();
    
    // Cancel subscriptions
    _chatServiceSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    _readStatusStreamSubscription?.cancel();
    
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