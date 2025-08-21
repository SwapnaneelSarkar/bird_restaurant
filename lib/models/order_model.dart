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
  final double deliveryFees;

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
    this.deliveryFees = 0.0,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // ENHANCED DEBUG: Check all possible status field names
    debugPrint('Order.fromJson: 🔍 DEBUGGING ORDER PARSING');
    debugPrint('Order.fromJson: 🔍 Order ID:  [33m${json['order_id'] ?? json['id']} [0m');
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
      customerName: (json['user_name'] ?? json['customer_name'] ?? json['customerName'] ?? json['user_id'] ?? '').toString(),
      amount: double.tryParse(json['total_price']?.toString() ?? '0') ?? 
              double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: TimeUtils.parseToIST(json['datetime'] ?? json['created_at'] ?? json['date'] ?? ''),
      status: orderStatus,
      customerPhone: json['customer_phone'] ?? json['phone'],
      deliveryAddress: json['delivery_address'] ?? json['address'],
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
      deliveryFees: double.tryParse(json['delivery_fees']?.toString() ?? '0') ?? 0.0,
    );
    
    debugPrint('Order.fromJson: ✅ Final parsed order - ID:  [33m${order.id} [0m, Status: "${order.status}", Enum: ${order.orderStatus}');
    
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
      'delivery_fees': deliveryFees,
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
    return customerName.isNotEmpty ? customerName : (customerPhone ?? '');
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
  final String menuId;
  final int quantity;
  final double price;
  final String? name;
  final String? description;
  final String? imageUrl;

  const OrderItem({
    required this.menuId,
    required this.quantity,
    required this.price,
    this.name,
    this.description,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuId: json['menu_id'] ?? json['id'] ?? json['item_id'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['item_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      name: json['name'] ?? json['item_name'],
      description: json['description'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': menuId,
      'quantity': quantity,
      'item_price': price,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

class DeliveryPartnerOrder {
  final String orderId;
  final String partnerId;
  final String userId;
  final String totalPrice;
  final String address;
  final String deliveryFees;
  final String subtotal;
  final String? paymentMode;
  final String orderStatus;
  final String createdAt;
  final String updatedAt;
  final String latitude;
  final String longitude;
  final String? deliveryPartnerId;

  DeliveryPartnerOrder({
    required this.orderId,
    required this.partnerId,
    required this.userId,
    required this.totalPrice,
    required this.address,
    required this.deliveryFees,
    required this.subtotal,
    required this.paymentMode,
    required this.orderStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    required this.deliveryPartnerId,
  });

  factory DeliveryPartnerOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerOrder(
      orderId: json['order_id'] ?? '',
      partnerId: json['partner_id'] ?? '',
      userId: json['user_id'] ?? '',
      totalPrice: json['total_price'] ?? '',
      address: json['address'] ?? '',
      deliveryFees: json['delivery_fees'] ?? '',
      subtotal: json['subtotal'] ?? '',
      paymentMode: json['payment_mode'],
      orderStatus: json['order_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      deliveryPartnerId: json['delivery_partner_id'],
    );
  }
}

class DeliveryPartnerOrderListResponse {
  final String status;
  final List<DeliveryPartnerOrder> data;

  DeliveryPartnerOrderListResponse({required this.status, required this.data});

  factory DeliveryPartnerOrderListResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerOrderListResponse(
      status: json['status'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => DeliveryPartnerOrder.fromJson(item))
              .toList()
          : [],
    );
  }
}

// Today's Order Summary Response Model
class TodayOrderSummaryResponse {
  final String status;
  final String message;
  final TodayOrderSummaryData? data;

  TodayOrderSummaryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory TodayOrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    return TodayOrderSummaryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? TodayOrderSummaryData.fromJson(json['data']) : null,
    );
  }
}

class TodayOrderSummaryData {
  final String partnerId;
  final String date;
  final TodaySummary summary;
  final List<dynamic> ordersByStatus;
  final List<dynamic> hourlyDistribution;
  final List<dynamic> topSellingItems;
  final List<dynamic> deliveryPerformance;

  TodayOrderSummaryData({
    required this.partnerId,
    required this.date,
    required this.summary,
    required this.ordersByStatus,
    required this.hourlyDistribution,
    required this.topSellingItems,
    required this.deliveryPerformance,
  });

  factory TodayOrderSummaryData.fromJson(Map<String, dynamic> json) {
    return TodayOrderSummaryData(
      partnerId: json['partner_id'] ?? '',
      date: json['date'] ?? '',
      summary: TodaySummary.fromJson(json['summary'] ?? {}),
      ordersByStatus: json['orders_by_status'] ?? [],
      hourlyDistribution: json['hourly_distribution'] ?? [],
      topSellingItems: json['top_selling_items'] ?? [],
      deliveryPerformance: json['delivery_performance'] ?? [],
    );
  }
}

class TodaySummary {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final double completionRate;
  final double cancellationRate;
  final StatusBreakdown statusBreakdown;

  TodaySummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.completionRate,
    required this.cancellationRate,
    required this.statusBreakdown,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      cancellationRate: (json['cancellation_rate'] ?? 0).toDouble(),
      statusBreakdown: StatusBreakdown.fromJson(json['status_breakdown'] ?? {}),
    );
  }
}

class StatusBreakdown {
  final int confirmed;
  final int preparing;
  final int readyForDelivery;
  final int outForDelivery;
  final int delivered;
  final int cancelled;

  StatusBreakdown({
    required this.confirmed,
    required this.preparing,
    required this.readyForDelivery,
    required this.outForDelivery,
    required this.delivered,
    required this.cancelled,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      confirmed: json['confirmed'] ?? 0,
      preparing: json['preparing'] ?? 0,
      readyForDelivery: json['ready_for_delivery'] ?? 0,
      outForDelivery: json['out_for_delivery'] ?? 0,
      delivered: json['delivered'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}