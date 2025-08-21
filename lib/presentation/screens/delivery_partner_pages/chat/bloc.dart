// lib/presentation/screens/delivery_partner_pages/chat/bloc.dart - SIMPLIFIED

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../services/delivery_partner_chat_service.dart';
import '../../../../services/delivery_partner_services/delivery_partner_auth_service.dart';
import '../../../../services/delivery_partner_services/delivery_partner_orders_service.dart';
import '../../../../services/menu_item_service.dart';
import '../../../../utils/time_utils.dart';
import 'event.dart';
import 'state.dart';

class DeliveryPartnerChatBloc extends Bloc<DeliveryPartnerChatEvent, DeliveryPartnerChatState> {
  final DeliveryPartnerChatService _chatService;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentPartnerId;
  StreamSubscription? _messageStreamSubscription;
  StreamSubscription? _readStatusStreamSubscription;
  bool _isProcessingMarkAsDelivered = false;

  DeliveryPartnerChatBloc({DeliveryPartnerChatService? chatService}) 
    : _chatService = chatService ?? DeliveryPartnerChatService(),
      super(DeliveryPartnerChatInitial()) {
    
    debugPrint('DeliveryPartnerChatBloc: 🔵 Setting up delivery partner chat');
    
    // Set up socket callbacks
    _setupSocketCallbacks();
    
    // Register event handlers
    on<LoadDeliveryPartnerChatData>(_onLoadChatData);
    on<AppResume>(_onAppResume);
    on<RefreshChat>(_onRefreshChat);
    on<MarkOrderAsDelivered>(_onMarkOrderAsDelivered);
    on<MarkAsRead>(_onMarkAsRead);
    on<UpdateMessages>(_onUpdateMessages);

    debugPrint('DeliveryPartnerChatBloc: ✅ Setup complete');
  }

  void _setupSocketCallbacks() {
    // Listen for new messages
    _messageStreamSubscription = _chatService.messageStream.listen(
      (message) {
        _addIncomingMessage(message);
      },
      onError: (error) {
        // Handle error silently
      },
    );

    // Listen for read status updates
    _readStatusStreamSubscription = _chatService.readStatusStream.listen(
      (data) {
        _updateMessageReadStatus(data['messageId'], data['isRead']);
      },
      onError: (error) {
        // Handle error silently
      },
    );
  }

  void _addIncomingMessage(DeliveryPartnerApiMessage message) {
    if (state is DeliveryPartnerChatLoaded) {
      final currentState = state as DeliveryPartnerChatLoaded;
      
      final isFromCurrentUser = message.isFromCurrentUser(_currentUserId);
      final isRead = message.isReadByOthers(message.senderId);
      
      final newChatMessage = DeliveryPartnerChatMessage(
        id: message.id,
        message: message.content,
        isUserMessage: isFromCurrentUser,
        time: _formatTime(message.createdAt),
        isRead: isRead,
      );
      
      // Check if message already exists
      final messageExists = currentState.messages.any((m) => m.id == newChatMessage.id);
      
      if (!messageExists) {
        final updatedMessages = [...currentState.messages, newChatMessage];
        
        // Sort messages by timestamp - use string comparison for safety
        updatedMessages.sort((a, b) => a.id.compareTo(b.id));
        
        // Use add instead of emit for internal updates
        add(const UpdateMessages());
      }
    }
  }

  void _updateMessageReadStatus(String messageId, bool isRead) {
    if (state is DeliveryPartnerChatLoaded) {
      final currentState = state as DeliveryPartnerChatLoaded;
      
      final updatedMessages = currentState.messages.map((chatMsg) {
        if (chatMsg.id == messageId) {
          return chatMsg.copyWith(isRead: isRead);
        }
        return chatMsg;
      }).toList();
      
      // Use add instead of emit for internal updates
      add(const UpdateMessages());
    }
  }

  Future<void> _onAppResume(AppResume event, Emitter<DeliveryPartnerChatState> emit) async {
    try {
      await _chatService.handleAppResume();
      
      if (state is DeliveryPartnerChatLoaded && _currentRoomId != null) {
        await _chatService.refreshMessages();
        
        final currentState = state as DeliveryPartnerChatLoaded;
        final updatedMessages = _chatService.messages.map((apiMsg) {
          final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
          final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
          
          return DeliveryPartnerChatMessage(
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

  Future<void> _onRefreshChat(RefreshChat event, Emitter<DeliveryPartnerChatState> emit) async {
    if (_currentRoomId != null) {
      try {
        if (state is DeliveryPartnerChatLoaded) {
          final currentState = state as DeliveryPartnerChatLoaded;
          emit(currentState.copyWith(isRefreshing: true));
        }
        
        await _chatService.refreshMessages();
        
        if (state is DeliveryPartnerChatLoaded) {
          final currentState = state as DeliveryPartnerChatLoaded;
          
          final refreshedMessages = _chatService.messages.map((apiMsg) {
            final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
            final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
            
            return DeliveryPartnerChatMessage(
              id: apiMsg.id,
              message: apiMsg.content,
              isUserMessage: isFromCurrentUser,
              time: _formatTime(apiMsg.createdAt),
              isRead: isRead,
            );
          }).toList();
          
          emit(currentState.copyWith(
            messages: refreshedMessages,
            isRefreshing: false,
            lastUpdateTimestamp: DateTime.now(),
          ));
        }
      } catch (e) {
        if (state is DeliveryPartnerChatLoaded) {
          final currentState = state as DeliveryPartnerChatLoaded;
          emit(currentState.copyWith(isRefreshing: false));
        }
      }
    }
  }

  Future<void> _onMarkOrderAsDelivered(MarkOrderAsDelivered event, Emitter<DeliveryPartnerChatState> emit) async {
    debugPrint('DeliveryPartnerChatBloc: 🎯 _onMarkOrderAsDelivered called with orderId: ${event.orderId}');
    
    _isProcessingMarkAsDelivered = true;
    
    try {
      if (state is DeliveryPartnerChatLoaded) {
        final currentState = state as DeliveryPartnerChatLoaded;
        debugPrint('DeliveryPartnerChatBloc: 🔄 Setting isUpdatingOrderStatus to true');
        emit(currentState.copyWith(isUpdatingOrderStatus: true));
      }

      debugPrint('DeliveryPartnerChatBloc: 📞 Calling DeliveryPartnerOrdersService.updateOrderStatus');
      final response = await DeliveryPartnerOrdersService.updateOrderStatus(event.orderId, 'DELIVERED');
      
      debugPrint('DeliveryPartnerChatBloc: 📋 API response: $response');
      
      if (response['success'] == true) {
        debugPrint('DeliveryPartnerChatBloc: ✅ Order marked as delivered successfully');
        // Only emit success state, don't emit multiple states
        emit(DeliveryPartnerChatSuccess('Order marked as delivered successfully!'));
      } else {
        debugPrint('DeliveryPartnerChatBloc: ❌ API returned failure: ${response['message']}');
        // Reset the loading state and emit error
        if (state is DeliveryPartnerChatLoaded) {
          final currentState = state as DeliveryPartnerChatLoaded;
          emit(currentState.copyWith(isUpdatingOrderStatus: false));
        }
        throw Exception(response['message'] ?? 'Failed to mark order as delivered');
      }
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error marking order as delivered: $e');
      
      // Reset the loading state if we're in a loaded state
      if (state is DeliveryPartnerChatLoaded) {
        final currentState = state as DeliveryPartnerChatLoaded;
        emit(currentState.copyWith(isUpdatingOrderStatus: false));
      }
      
      emit(DeliveryPartnerChatError('Error: $e'));
    } finally {
      _isProcessingMarkAsDelivered = false;
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<DeliveryPartnerChatState> emit) async {
    try {
      await _chatService.markAsRead(event.roomId);
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error marking messages as read: $e');
    }
  }

  Future<void> _onUpdateMessages(UpdateMessages event, Emitter<DeliveryPartnerChatState> emit) async {
    if (state is DeliveryPartnerChatLoaded) {
      final currentState = state as DeliveryPartnerChatLoaded;
      final updatedMessages = _chatService.messages.map((apiMsg) {
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
        
        return DeliveryPartnerChatMessage(
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
  }

  Future<void> _onLoadChatData(LoadDeliveryPartnerChatData event, Emitter<DeliveryPartnerChatState> emit) async {
    try {
      debugPrint('DeliveryPartnerChatBloc: 🚀 Loading chat data for order: ${event.orderId}');
      
      emit(DeliveryPartnerChatLoading());

      // Get current user ID and partner ID
      _currentUserId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
      _currentPartnerId = await DeliveryPartnerAuthService.getDeliveryPartnerPartnerId();
      
      debugPrint('DeliveryPartnerChatBloc: 👤 Current User ID: $_currentUserId');
      debugPrint('DeliveryPartnerChatBloc: 🏪 Current Partner ID: $_currentPartnerId');

      if (_currentUserId == null || _currentPartnerId == null) {
        throw Exception('User or partner ID not found. Please login again.');
      }

      // Connect to chat service
      await _chatService.connect();

      // Create basic order info
      final orderInfo = ChatOrderInfo(
        orderId: _formatOrderIdForDisplay(event.orderId),
        restaurantName: 'Restaurant',
        status: 'Out for Delivery',
        estimatedDelivery: '30 mins',
      );

      // Join the chat room
      await _chatService.joinRoom(event.orderId);
      _currentRoomId = event.orderId;
      
      // Convert chat service messages to UI messages
      final chatMessages = _chatService.messages.map((apiMsg) {
        final isFromCurrentUser = apiMsg.isFromCurrentUser(_currentUserId);
        final isRead = apiMsg.isReadByOthers(apiMsg.senderId);
        
        return DeliveryPartnerChatMessage(
          id: apiMsg.id,
          message: apiMsg.content,
          isUserMessage: isFromCurrentUser,
          time: _formatTime(apiMsg.createdAt),
          isRead: isRead,
        );
      }).toList();

      // Sort messages by timestamp - use string comparison for safety
      chatMessages.sort((a, b) => a.id.compareTo(b.id));

              // Load order details
        OrderDetails? orderDetails;
        Map<String, MenuItem> menuItems = {};
      
      try {
        // Fetch order details from the delivery partner orders service
        final orderData = await _fetchOrderDetails(event.orderId);
        if (orderData != null) {
          try {
            orderDetails = OrderDetails.fromJson(orderData);
            debugPrint('DeliveryPartnerChatBloc: ✅ Order details parsed successfully');
            
            // Update order info with real status from API
            final updatedOrderInfo = orderInfo.copyWith(
              status: _formatOrderStatus(orderDetails.orderStatus),
            );
            
            debugPrint('DeliveryPartnerChatBloc: 📊 Original order status from API: ${orderDetails.orderStatus}');
            debugPrint('DeliveryPartnerChatBloc: 📊 Formatted order status: ${_formatOrderStatus(orderDetails.orderStatus)}');
            debugPrint('DeliveryPartnerChatBloc: 📊 Updated order info status: ${updatedOrderInfo.status}');
            
            // Load menu items if needed
            if (orderDetails.items.isNotEmpty) {
              menuItems = await _loadMenuItems(orderDetails.items);
              debugPrint('DeliveryPartnerChatBloc: ✅ Loaded ${menuItems.length} menu items');
            }
            
            // Emit loaded state with updated order info
            emit(DeliveryPartnerChatLoaded(
              messages: chatMessages,
              orderInfo: updatedOrderInfo,
              isConnected: _chatService.isConnected,
              isRefreshing: false,
              orderDetails: orderDetails,
              isLoadingOrderDetails: false,
              menuItems: menuItems,
              isUpdatingOrderStatus: false,
              lastUpdateSuccess: false,
              lastUpdateMessage: '',
              lastUpdateTimestamp: DateTime.now(),
              userDetails: null,
              isLoadingUserDetails: false,
            ));
          } catch (e) {
            debugPrint('DeliveryPartnerChatBloc: ❌ Error parsing order details: $e');
            debugPrint('DeliveryPartnerChatBloc: ❌ Order data: $orderData');
            // Continue without order details
          }
        } else {
          debugPrint('DeliveryPartnerChatBloc: ⚠️ No order details data received');
        }
      } catch (e) {
        debugPrint('DeliveryPartnerChatBloc: ⚠️ Error loading order details: $e');
        // Continue without order details
      }

      // If we didn't emit loaded state above (due to order details error), emit it now
      if (state is! DeliveryPartnerChatLoaded) {
        emit(DeliveryPartnerChatLoaded(
          messages: chatMessages,
          orderInfo: orderInfo,
          isConnected: _chatService.isConnected,
          isRefreshing: false,
          orderDetails: orderDetails,
          isLoadingOrderDetails: false,
          menuItems: menuItems,
          isUpdatingOrderStatus: false,
          lastUpdateSuccess: false,
          lastUpdateMessage: '',
          lastUpdateTimestamp: DateTime.now(),
          userDetails: null,
          isLoadingUserDetails: false,
        ));
      }

      debugPrint('DeliveryPartnerChatBloc: ✅ Chat data loaded successfully');
      debugPrint('DeliveryPartnerChatBloc: 📊 Messages count: ${chatMessages.length}');
      debugPrint('DeliveryPartnerChatBloc: 🏪 Room ID: $_currentRoomId');

      // Mark messages as read
      await _chatService.markAsRead(_currentRoomId!);
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error loading chat data: $e');
      emit(DeliveryPartnerChatError('Failed to load chat: $e'));
    }
  }

  // Helper method to fetch order details
  Future<Map<String, dynamic>?> _fetchOrderDetails(String orderId) async {
    try {
      final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
      if (token == null) {
        debugPrint('DeliveryPartnerChatBloc: ❌ No token available for fetching order details');
        return null;
      }
      
      final url = 'https://api.bird.delivery/api/delivery-partner/orders/$orderId';
      debugPrint('DeliveryPartnerChatBloc: 📋 Fetching order details from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('DeliveryPartnerChatBloc: 📋 Order details response status: ${response.statusCode}');
      debugPrint('DeliveryPartnerChatBloc: 📋 Order details response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS' && data['data'] != null) {
          debugPrint('DeliveryPartnerChatBloc: ✅ Order details fetched successfully');
          return data['data'];
        } else {
          debugPrint('DeliveryPartnerChatBloc: ❌ Order details API returned non-success status: ${data['status']}');
        }
      } else {
        debugPrint('DeliveryPartnerChatBloc: ❌ Order details API returned error status: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error fetching order details: $e');
      return null;
    }
  }
  
  // Helper method to load menu items
  Future<Map<String, MenuItem>> _loadMenuItems(List<OrderItem> orderItems) async {
    try {
      final menuIds = orderItems.map((item) => item.menuId).toList();
      return await MenuItemService.getMenuItems(menuIds);
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error loading menu items: $e');
      return {};
    }
  }

  // Helper method to format order ID for display
  String _formatOrderIdForDisplay(String orderId) {
    if (orderId.length > 12) {
      return orderId.substring(0, 12) + '...';
    }
    return orderId;
  }

  // Helper method to format order status
  String _formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'READY_FOR_DELIVERY':
        return 'Ready for Delivery';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final istTime = TimeUtils.toIST(dateTime);
    if (TimeUtils.isToday(istTime)) {
      return TimeUtils.formatChatMessageTime(istTime);
    } else if (TimeUtils.isYesterday(istTime)) {
      final timeStr = TimeUtils.formatChatMessageTime(istTime);
      return 'Yesterday $timeStr';
    } else {
      final dateStr = '${istTime.month.toString().padLeft(2, '0')}/${istTime.day.toString().padLeft(2, '0')}/${istTime.year}';
      final timeStr = TimeUtils.formatChatMessageTime(istTime);
      return '$dateStr $timeStr';
    }
  }

  // Getters for external access
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  String? get currentPartnerId => _currentPartnerId;
  String? get currentOrderId => _currentRoomId;

  // Get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _chatService.isConnected,
      'roomId': _currentRoomId,
      'userId': _currentUserId,
      'partnerId': _currentPartnerId,
      'messageCount': _chatService.messages.length,
    };
  }

  // Check connection health
  bool checkConnectionHealth() {
    return _chatService.isConnected && _currentRoomId != null;
  }

  // Force reconnect
  Future<void> forceReconnect() async {
    try {
      _chatService.disconnect();
      await _chatService.connect();
      
      if (_currentRoomId != null) {
        _chatService.joinRoom(_currentRoomId!);
      }
    } catch (e) {
      debugPrint('DeliveryPartnerChatBloc: ❌ Error during force reconnect: $e');
    }
  }



  @override
  Future<void> close() {
    debugPrint('DeliveryPartnerChatBloc: 🔄 Closing bloc and cleaning up resources');
    debugPrint('DeliveryPartnerChatBloc: 🔄 Is processing mark as delivered: $_isProcessingMarkAsDelivered');
    
    // Add a small delay if we're processing the mark as delivered event
    if (_isProcessingMarkAsDelivered) {
      debugPrint('DeliveryPartnerChatBloc: ⚠️ Delaying close - processing mark as delivered event');
      return Future.delayed(const Duration(milliseconds: 500), () {
        _closeBloc();
      });
    }
    
    return _closeBloc();
  }
  
  Future<void> _closeBloc() async {
    // Cancel subscriptions
    _messageStreamSubscription?.cancel();
    _readStatusStreamSubscription?.cancel();
    
    // Close chat service
    _chatService.disconnect();
    
    return super.close();
  }
} 