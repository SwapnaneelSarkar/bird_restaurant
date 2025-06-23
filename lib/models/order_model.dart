// ENHANCED DEBUG VERSION: lib/models/order_model.dart
import '../constants/enums.dart';
import 'package:flutter/foundation.dart';
import '../utils/time_utils.dart';

class OrderSummaryResponse {
  final String status;
  final String message;
  final OrderSummaryData? data;

  OrderSummaryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    return OrderSummaryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? OrderSummaryData.fromJson(json['data']) : null,
    );
  }
}

class OrderSummaryData {
  final int totalOrders;
  final int totalPending;
  final int totalConfirmed;
  final int totalPreparing;
  final int totalReadyForDelivery;
  final int totalOutForDelivery;
  final int totalDelivered;
  final int totalCancelled;

  OrderSummaryData({
    required this.totalOrders,
    required this.totalPending,
    required this.totalConfirmed,
    required this.totalPreparing,
    required this.totalReadyForDelivery,
    required this.totalOutForDelivery,
    required this.totalDelivered,
    required this.totalCancelled,
  });

  factory OrderSummaryData.fromJson(Map<String, dynamic> json) {
    return OrderSummaryData(
      totalOrders: json['total_orders'] ?? 0,
      totalPending: json['total_pending'] ?? 0,
      totalConfirmed: json['total_confirmed'] ?? 0,
      totalPreparing: json['total_preparing'] ?? 0,
      totalReadyForDelivery: json['total_ready_for_delivery'] ?? 0,
      totalOutForDelivery: json['total_out_for_delivery'] ?? 0,
      totalDelivered: json['total_delivered'] ?? 0,
      totalCancelled: json['total_cancelled'] ?? 0,
    );
  }
}

class OrderHistoryResponse {
  final String status;
  final String message;
  final List<Order> data;

  OrderHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? (json['data'] as List).map((item) => Order.fromJson(item)).toList()
          : [],
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String customerName;
  final double amount;
  final DateTime date;
  final String status; // Keep as string for API compatibility
  final String? customerPhone;
  final String? deliveryAddress;
  final List<OrderItem>? items;

  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
    this.customerPhone,
    this.deliveryAddress,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // ENHANCED DEBUG: Check all possible status field names
    debugPrint('Order.fromJson: 🔍 DEBUGGING ORDER PARSING');
    debugPrint('Order.fromJson: 🔍 Order ID: ${json['order_id'] ?? json['id']}');
    debugPrint('Order.fromJson: 🔍 Available keys: ${json.keys.toList()}');
    debugPrint('Order.fromJson: 🔍 status field: ${json['status']}');
    debugPrint('Order.fromJson: 🔍 order_status field: ${json['order_status']}');
    debugPrint('Order.fromJson: 🔍 state field: ${json['state']}');
    debugPrint('Order.fromJson: 🔍 order_state field: ${json['order_state']}');
    debugPrint('Order.fromJson: 🔍 current_status field: ${json['current_status']}');
    
    // Try to find the correct status field - CHECK MULTIPLE POSSIBLE FIELD NAMES
    String orderStatus = 'PENDING'; // Default fallback
    
    // Check common status field names in order of priority
    if (json['status'] != null && json['status'].toString().isNotEmpty) {
      orderStatus = json['status'].toString().toUpperCase();
      debugPrint('Order.fromJson: ✅ Using "status" field: $orderStatus');
    } else if (json['order_status'] != null && json['order_status'].toString().isNotEmpty) {
      orderStatus = json['order_status'].toString().toUpperCase();
      debugPrint('Order.fromJson: ✅ Using "order_status" field: $orderStatus');
    } else if (json['state'] != null && json['state'].toString().isNotEmpty) {
      orderStatus = json['state'].toString().toUpperCase();
      debugPrint('Order.fromJson: ✅ Using "state" field: $orderStatus');
    } else if (json['order_state'] != null && json['order_state'].toString().isNotEmpty) {
      orderStatus = json['order_state'].toString().toUpperCase();
      debugPrint('Order.fromJson: ✅ Using "order_state" field: $orderStatus');
    } else if (json['current_status'] != null && json['current_status'].toString().isNotEmpty) {
      orderStatus = json['current_status'].toString().toUpperCase();
      debugPrint('Order.fromJson: ✅ Using "current_status" field: $orderStatus');
    } else {
      debugPrint('Order.fromJson: ⚠️ No valid status field found, using default: PENDING');
      debugPrint('Order.fromJson: ⚠️ Complete JSON for this order: $json');
    }
    
    final order = Order(
      id: json['order_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Unknown Customer',
      amount: double.tryParse(json['total_price']?.toString() ?? '0') ?? 
              double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: TimeUtils.parseToIST(json['created_at'] ?? json['date'] ?? ''),
      status: orderStatus,
      customerPhone: json['customer_phone'] ?? json['phone'],
      deliveryAddress: json['delivery_address'] ?? json['address'],
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
    );
    
    debugPrint('Order.fromJson: ✅ Final parsed order - ID: ${order.id}, Status: "${order.status}", Enum: ${order.orderStatus}');
    
    return order;
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': id,
      'user_id': userId,
      'customer_name': customerName,
      'total_price': amount,
      'created_at': TimeUtils.toIsoStringForAPI(date),
      'status': status,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  // Convert string status to OrderStatus enum
  OrderStatus get orderStatus {
    final enumStatus = OrderStatusExtension.fromApiValue(status);
    debugPrint('Order.orderStatus: Converting "$status" to enum: $enumStatus');
    return enumStatus;
  }

  // Get display name for customer
  String get displayCustomerName {
    if (customerName.isEmpty || customerName == 'Unknown Customer') {
      return customerPhone ?? 'Unknown Customer';
    }
    return customerName;
  }

  // Create a copy with updated values
  Order copyWith({
    String? id,
    String? userId,
    String? customerName,
    double? amount,
    DateTime? date,
    String? status,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? description;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.description,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? json['item_id'] ?? '',
      name: json['name'] ?? json['item_name'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
  }
}