// lib/presentation/screens/chat/state.dart - ENHANCED WITH MENU ITEMS

import 'package:equatable/equatable.dart';
import '../../../services/menu_item_service.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatOrderInfo orderInfo;
  final List<ChatMessage> messages;
  final bool isConnected;
  final bool isSendingMessage;
  final bool isRefreshing;
  final OrderDetails? orderDetails;
  final bool isLoadingOrderDetails;
  final Map<String, MenuItem> menuItems; // NEW: Cache for menu items

  const ChatLoaded({
    required this.orderInfo,
    required this.messages,
    required this.isConnected,
    this.isSendingMessage = false,
    this.isRefreshing = false,
    this.orderDetails,
    this.isLoadingOrderDetails = false,
    this.menuItems = const {}, // NEW: Default empty map
  });

  ChatLoaded copyWith({
    ChatOrderInfo? orderInfo,
    List<ChatMessage>? messages,
    bool? isConnected,
    bool? isSendingMessage,
    bool? isRefreshing,
    OrderDetails? orderDetails,
    bool? isLoadingOrderDetails,
    Map<String, MenuItem>? menuItems, // NEW: Add menu items to copyWith
  }) {
    return ChatLoaded(
      orderInfo: orderInfo ?? this.orderInfo,
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      orderDetails: orderDetails ?? this.orderDetails,
      isLoadingOrderDetails: isLoadingOrderDetails ?? this.isLoadingOrderDetails,
      menuItems: menuItems ?? this.menuItems, // NEW: Include in copyWith
    );
  }

  @override
  List<Object?> get props => [
        orderInfo,
        messages,
        isConnected,
        isSendingMessage,
        isRefreshing,
        orderDetails,
        isLoadingOrderDetails,
        menuItems, // NEW: Include in props
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// Order-related states
class OrderOptionsVisible extends ChatState {
  final String orderId;
  final String partnerId;

  const OrderOptionsVisible({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [orderId, partnerId];
}

class OrderDetailsLoading extends ChatState {}

class OrderDetailsLoaded extends ChatState {
  final OrderDetails orderDetails;
  final Map<String, MenuItem> menuItems; // NEW: Include menu items here too

  const OrderDetailsLoaded(this.orderDetails, {this.menuItems = const {}});

  @override
  List<Object?> get props => [orderDetails, menuItems];
}

class OrderDetailsError extends ChatState {
  final String message;

  const OrderDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Models
class ChatOrderInfo {
  final String orderId;
  final String restaurantName;
  final String estimatedDelivery;
  final String status;

  const ChatOrderInfo({
    required this.orderId,
    required this.restaurantName,
    required this.estimatedDelivery,
    required this.status,
  });

  ChatOrderInfo copyWith({
    String? orderId,
    String? restaurantName,
    String? estimatedDelivery,
    String? status,
  }) {
    return ChatOrderInfo(
      orderId: orderId ?? this.orderId,
      restaurantName: restaurantName ?? this.restaurantName,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      status: status ?? this.status,
    );
  }
}

class ChatMessage {
  final String id;
  final String message;
  final bool isUserMessage;
  final String time;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.isUserMessage,
    required this.time,
  });
}

class OrderDetails {
  final String orderId;
  final String userId;
  final List<String> itemIds;
  final List<OrderItem> items;
  final String totalAmount;
  final String deliveryFees;
  final String orderStatus;

  const OrderDetails({
    required this.orderId,
    required this.userId,
    required this.itemIds,
    required this.items,
    required this.totalAmount,
    required this.deliveryFees,
    required this.orderStatus,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      itemIds: List<String>.from(json['item_ids'] ?? []),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: json['total_amount']?.toString() ?? '0.00',
      deliveryFees: json['delivery_fees']?.toString() ?? '0.00',
      orderStatus: json['order_status'] ?? 'UNKNOWN',
    );
  }

  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;
  double get deliveryFeesDouble => double.tryParse(deliveryFees) ?? 0.0;
  double get grandTotal => totalAmountDouble + deliveryFeesDouble;

  String get formattedTotal => '₹${totalAmount}';
  String get formattedDeliveryFees => '₹${deliveryFees}';
  String get formattedGrandTotal => '₹${grandTotal.toStringAsFixed(2)}';

  // NEW: Get all menu IDs from the order items
  List<String> get allMenuIds => items.map((item) => item.menuId).toList();
}

class OrderItem {
  final String menuId;
  final int quantity;
  final double itemPrice;

  const OrderItem({
    required this.menuId,
    required this.quantity,
    required this.itemPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuId: json['menu_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      itemPrice: (json['item_price'] ?? 0).toDouble(),
    );
  }

  double get totalPrice => itemPrice * quantity;
  String get formattedPrice => '₹${itemPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(2)}';

  // NEW: Helper method to get menu item info
  MenuItem? getMenuItem(Map<String, MenuItem> menuItems) {
    return menuItems[menuId];
  }

  // NEW: Get display name (either from menu item or fallback to menu ID)
  String getDisplayName(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.name ?? 'Menu ID: $menuId';
  }

  // NEW: Get display image URL
  String? getImageUrl(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.displayImageUrl;
  }
}