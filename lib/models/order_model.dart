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
    return Order(
      id: json['order_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Unknown Customer',
      amount: double.tryParse(json['total_price']?.toString() ?? '0') ?? 
              double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: DateTime.tryParse(json['created_at'] ?? json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      customerPhone: json['customer_phone'] ?? json['phone'],
      deliveryAddress: json['delivery_address'] ?? json['address'],
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': id,
      'user_id': userId,
      'customer_name': customerName,
      'total_price': amount,
      'created_at': date.toIso8601String(),
      'status': status,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  // Convert string status to OrderStatus enum
  OrderStatus get orderStatus {
    return OrderStatusExtension.fromApiValue(status);
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
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      imageUrl: json['image_url'] ?? json['image'],
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

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Create a copy with updated values
  OrderItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    String? description,
    String? imageUrl,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}