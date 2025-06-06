// lib/models/order_model.dart
import '../constants/enums.dart';

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
  final String customerName;
  final double amount;
  final DateTime date;
  final String status;
  final String? customerPhone;
  final String? deliveryAddress;
  final List<OrderItem>? items;

  const Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
    this.customerPhone,
    this.deliveryAddress,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'] ?? json['id'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Unknown Customer',
      amount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      date: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['order_date'] != null
              ? DateTime.parse(json['order_date'])
              : DateTime.now(),
      status: json['order_status'] ?? json['status'] ?? 'pending',
      customerPhone: json['customer_phone'] ?? json['phone'],
      deliveryAddress: json['delivery_address'] ?? json['address'],
      items: json['items'] != null
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
    );
  }

  // Convert status string to OrderStatus enum
  OrderStatus get orderStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready_for_delivery':
      case 'ready':
        return OrderStatus.delivery;
      case 'out_for_delivery':
      case 'delivery':
        return OrderStatus.delivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;
  final String? imageUrl;

  const OrderItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'] ?? json['id'] ?? '',
      itemName: json['item_name'] ?? json['name'] ?? 'Unknown Item',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }
}