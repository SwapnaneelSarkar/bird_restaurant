// lib/presentation/screens/chat/state.dart - ENHANCED WITH READ STATUS

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
  final bool isUpdatingOrderStatus;
  final bool? lastUpdateSuccess;
  final String? lastUpdateMessage;
  final DateTime? lastUpdateTimestamp;

  const ChatLoaded({
    required this.orderInfo,
    required this.messages,
    required this.isConnected,
    this.isSendingMessage = false,
    this.isRefreshing = false,
    this.orderDetails,
    this.isLoadingOrderDetails = false,
    this.menuItems = const {},
    this.isUpdatingOrderStatus = false,
    this.lastUpdateSuccess,
    this.lastUpdateMessage,
    this.lastUpdateTimestamp,
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
    bool? isUpdatingOrderStatus,
    bool? lastUpdateSuccess,
    String? lastUpdateMessage,
    DateTime? lastUpdateTimestamp,
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
      isUpdatingOrderStatus: isUpdatingOrderStatus ?? this.isUpdatingOrderStatus,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess,
      lastUpdateMessage: lastUpdateMessage ?? this.lastUpdateMessage,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
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
        isUpdatingOrderStatus,
        lastUpdateSuccess,
        lastUpdateMessage,
        lastUpdateTimestamp,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
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

// ENHANCED: ChatMessage with read status
class ChatMessage {
  final String id;
  final String message;
  final bool isUserMessage;
  final String time;
  final bool isRead; // NEW: Read status for blue/grey ticks

  const ChatMessage({
    required this.id,
    required this.message,
    required this.isUserMessage,
    required this.time,
    this.isRead = false, // Default to false (grey tick)
  });

  ChatMessage copyWith({
    String? id,
    String? message,
    bool? isUserMessage,
    String? time,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}

class OrderDetails {
  final String orderId;
  final String userId;
  final String userName;
  final String partnerId;
  final List<String> itemIds;
  final List<OrderItem> items;
  final String totalAmount;
  final String deliveryFees;
  final String orderStatus;
  final String? deliveryAddress;
  final String? deliveryDate;
  final String? deliveryTime;
  final double deliveryPrice;

  const OrderDetails({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.partnerId,
    required this.itemIds,
    required this.items,
    required this.totalAmount,
    required this.deliveryFees,
    required this.orderStatus,
    this.deliveryAddress,
    this.deliveryDate,
    this.deliveryTime,
    this.deliveryPrice = 0.0,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      partnerId: json['partner_id'] ?? '',
      itemIds: List<String>.from(json['item_ids'] ?? []),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      totalAmount: _parseAmount(json['total_price']),
      deliveryFees: _parseAmount(json['delivery_fees']),
      orderStatus: json['order_status'] ?? 'UNKNOWN',
      deliveryAddress: json['delivery_address'] ?? json['address'],
      deliveryDate: json['delivery_date'],
      deliveryTime: json['delivery_time'],
      deliveryPrice: double.tryParse(json['delivery_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  OrderDetails copyWith({
    String? orderId,
    String? userId,
    String? userName,
    String? partnerId,
    List<String>? itemIds,
    List<OrderItem>? items,
    String? totalAmount,
    String? deliveryFees,
    String? orderStatus,
    String? deliveryAddress,
    String? deliveryDate,
    String? deliveryTime,
    double? deliveryPrice,
  }) {
    return OrderDetails(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      partnerId: partnerId ?? this.partnerId,
      itemIds: itemIds ?? this.itemIds,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFees: deliveryFees ?? this.deliveryFees,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
    );
  }

  static String _parseAmount(dynamic amount) {
    if (amount == null) return '0.00';
    
    if (amount is String) return amount;
    if (amount is double) return amount.toStringAsFixed(2);
    if (amount is int) return amount.toStringAsFixed(2);
    
    return amount.toString();
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity));
  double get deliveryFeesDouble => double.tryParse(deliveryFees) ?? 0.0;
  double get grandTotal => subtotal + deliveryFeesDouble;

  String formattedTotal(String currencySymbol) => '$currencySymbol${subtotal.toStringAsFixed(2)}';
  String formattedDeliveryFees(String currencySymbol) => '$currencySymbol$deliveryFees';
  String formattedGrandTotal(String currencySymbol) => '$currencySymbol${grandTotal.toStringAsFixed(2)}';

  List<String> get allMenuIds => items.map((item) => item.menuId).toList();
}

class OrderItem {
  final String menuId;
  final int quantity;
  final double itemPrice;
  final Map<String, dynamic>? attributes;

  const OrderItem({
    required this.menuId,
    required this.quantity,
    required this.itemPrice,
    this.attributes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuId: json['menu_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      itemPrice: _parsePrice(json['item_price']),
      attributes: json['attributes'] != null ? Map<String, dynamic>.from(json['attributes']) : null,
    );
  }

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
  String formattedPrice(String currencySymbol) => '$currencySymbol${itemPrice.toStringAsFixed(2)}';
  String formattedTotalPrice(String currencySymbol) => '$currencySymbol${totalPrice.toStringAsFixed(2)}';

  MenuItem? getMenuItem(Map<String, MenuItem> menuItems) {
    return menuItems[menuId];
  }

  String getDisplayName(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    if (menuItem != null) {
      return menuItem.name;
    }
    return 'Item ID: $menuId';
  }

  String? getImageUrl(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.displayImageUrl;
  }

  String? getDescription(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.description;
  }

  bool? isAvailable(Map<String, MenuItem> menuItems) {
    final menuItem = getMenuItem(menuItems);
    return menuItem?.isAvailable;
  }
}