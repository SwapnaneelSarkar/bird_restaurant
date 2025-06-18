// lib/presentation/screens/chat/state.dart - ENHANCED WITH STATUS UPDATE TRACKING

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
  final Map<String, MenuItem> menuItems;
  final bool isUpdatingOrderStatus; // ADD THIS FIELD
  final bool? lastUpdateSuccess; // ADD THIS FIELD
  final String? lastUpdateMessage; // ADD THIS FIELD
  final DateTime? lastUpdateTimestamp; // ADD THIS FIELD

  const ChatLoaded({
    required this.orderInfo,
    required this.messages,
    required this.isConnected,
    this.isSendingMessage = false,
    this.isRefreshing = false,
    this.orderDetails,
    this.isLoadingOrderDetails = false,
    this.menuItems = const {},
    this.isUpdatingOrderStatus = false, // ADD THIS
    this.lastUpdateSuccess, // ADD THIS
    this.lastUpdateMessage, // ADD THIS
    this.lastUpdateTimestamp, // ADD THIS
  });

  ChatLoaded copyWith({
    ChatOrderInfo? orderInfo,
    List<ChatMessage>? messages,
    bool? isConnected,
    bool? isSendingMessage,
    bool? isRefreshing,
    OrderDetails? orderDetails,
    bool? isLoadingOrderDetails,
    Map<String, MenuItem>? menuItems,
    bool? isUpdatingOrderStatus, // ADD THIS
    bool? lastUpdateSuccess, // ADD THIS
    String? lastUpdateMessage, // ADD THIS
    DateTime? lastUpdateTimestamp, // ADD THIS
  }) {
    return ChatLoaded(
      orderInfo: orderInfo ?? this.orderInfo,
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      orderDetails: orderDetails ?? this.orderDetails,
      isLoadingOrderDetails: isLoadingOrderDetails ?? this.isLoadingOrderDetails,
      menuItems: menuItems ?? this.menuItems,
      isUpdatingOrderStatus: isUpdatingOrderStatus ?? this.isUpdatingOrderStatus, // ADD THIS
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess, // ADD THIS
      lastUpdateMessage: lastUpdateMessage ?? this.lastUpdateMessage, // ADD THIS
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp, // ADD THIS
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
        menuItems,
        isUpdatingOrderStatus, // ADD THIS
        lastUpdateSuccess, // ADD THIS
        lastUpdateMessage, // ADD THIS
        lastUpdateTimestamp, // ADD THIS
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

// NEW: Order-related states
class OrderOptionsVisible extends ChatState {
  final String orderId;
  final String partnerId;

  const OrderOptionsVisible({
    required this.orderId,
    required this.partnerId,
  });

  @override
  List<Object> get props => [orderId, partnerId];
}

class OrderDetailsLoading extends ChatState {}

class OrderDetailsLoaded extends ChatState {
  final OrderDetails orderDetails;
  final Map<String, MenuItem>? menuItems;

  const OrderDetailsLoaded(this.orderDetails, {this.menuItems});

  @override
  List<Object?> get props => [orderDetails, menuItems];
}

class OrderDetailsError extends ChatState {
  final String message;

  const OrderDetailsError(this.message);

  @override
  List<Object> get props => [message];
}

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
      totalAmount: _parseAmount(json['total_amount']),
      deliveryFees: _parseAmount(json['delivery_fees']),
      orderStatus: json['order_status'] ?? 'UNKNOWN',
    );
  }

  // ADD THIS COPYWITH METHOD FOR STATUS UPDATES
  OrderDetails copyWith({
    String? orderId,
    String? userId,
    List<String>? itemIds,
    List<OrderItem>? items,
    String? totalAmount,
    String? deliveryFees,
    String? orderStatus,
  }) {
    return OrderDetails(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      itemIds: itemIds ?? this.itemIds,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFees: deliveryFees ?? this.deliveryFees,
      orderStatus: orderStatus ?? this.orderStatus, // This is the key update
    );
  }

  // FIXED: Helper method to parse amount from string or number
  static String _parseAmount(dynamic amount) {
    if (amount == null) return '0.00';
    
    if (amount is String) return amount;
    if (amount is double) return amount.toStringAsFixed(2);
    if (amount is int) return amount.toStringAsFixed(2);
    
    return amount.toString();
  }

  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;
  double get deliveryFeesDouble => double.tryParse(deliveryFees) ?? 0.0;
  double get grandTotal => totalAmountDouble + deliveryFeesDouble;

  String get formattedTotal => '₹${totalAmount}';
  String get formattedDeliveryFees => '₹${deliveryFees}';
  String get formattedGrandTotal => '₹${grandTotal.toStringAsFixed(2)}';

  // ENHANCED: Get all menu IDs from the order items
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
      itemPrice: _parsePrice(json['item_price']),
    );
  }

  // FIXED: Helper method to parse price from string or number
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        return double.parse(price);
      } catch (e) {
        print('OrderItem: Error parsing price "$price": $e');
        return 0.0;
      }
    }
    
    print('OrderItem: Unknown price type: ${price.runtimeType}');
    return 0.0;
  }

  double get totalPrice => itemPrice * quantity;
  String get formattedPrice => '₹${itemPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(2)}';

  // ENHANCED: Helper method to get menu item info
  MenuItem? getMenuItem(Map<String, MenuItem> menuItems) {
    return menuItems[menuId];
  }

  // ENHANCED: Get display name (either from menu item or fallback to menu ID)
  String getDisplayName(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    if (menuItem != null) {
      return menuItem.name;
    }
    return 'Item ID: $menuId'; // Fallback to show menu ID
  }

  // ENHANCED: Get display image URL
  String? getImageUrl(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.displayImageUrl;
  }

  // ENHANCED: Get menu item description
  String? getDescription(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.description;
  }

  // ENHANCED: Check if menu item is available
  bool? isAvailable(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.isAvailable;
  }
}