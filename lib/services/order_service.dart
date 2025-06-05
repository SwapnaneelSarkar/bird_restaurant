// lib/services/order_service.dart - Service for fetching order details

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'token_service.dart';

// Update the ChatOrderInfo class to include more order details
class ChatOrderInfo {
  final String orderId;
  final String restaurantName;
  final String estimatedDelivery;
  final String status;
  final double totalAmount;
  final double deliveryFees;
  final int totalItems;
  final String userId;

  const ChatOrderInfo({
    required this.orderId,
    required this.restaurantName,
    required this.estimatedDelivery,
    required this.status,
    required this.totalAmount,
    required this.deliveryFees,
    required this.totalItems,
    required this.userId,
  });

  factory ChatOrderInfo.fromOrderDetails(OrderDetails orderDetails, String restaurantName) {
    return ChatOrderInfo(
      orderId: orderDetails.orderId,
      restaurantName: restaurantName,
      estimatedDelivery: OrderService.getEstimatedDelivery(orderDetails.orderStatus),
      status: orderDetails.formattedStatus,
      totalAmount: orderDetails.totalAmount,
      deliveryFees: orderDetails.deliveryFees,
      totalItems: orderDetails.totalItems,
      userId: orderDetails.userId,
    );
  }

  double get grandTotal => totalAmount + deliveryFees;
  
  String get formattedTotal => OrderService.formatCurrency(grandTotal);
  String get formattedAmount => OrderService.formatCurrency(totalAmount);
  String get formattedDeliveryFees => OrderService.formatCurrency(deliveryFees);
  
  String get shortOrderId {
    if (orderId.length > 8) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId;
  }
  
  String get shortUserId {
    if (userId.length > 10) {
      return userId.substring(userId.length - 10);
    }
    return userId;
  }
}

class OrderItem {
  final String menuId;
  final int quantity;
  final double itemPrice;

  OrderItem({
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
}

class OrderDetails {
  final String orderId;
  final String userId;
  final List<String> itemIds;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFees;
  final String orderStatus;

  OrderDetails({
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
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      deliveryFees: double.tryParse(json['delivery_fees']?.toString() ?? '0') ?? 0.0,
      orderStatus: json['order_status'] ?? 'UNKNOWN',
    );
  }

  // Helper methods
  double get grandTotal => totalAmount + deliveryFees;
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  String get formattedStatus {
    switch (orderStatus.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'READY':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }
  
  String get statusColor {
    switch (orderStatus.toUpperCase()) {
      case 'PENDING':
        return 'orange';
      case 'CONFIRMED':
        return 'blue';
      case 'PREPARING':
        return 'amber';
      case 'READY':
        return 'green';
      case 'OUT_FOR_DELIVERY':
        return 'indigo';
      case 'DELIVERED':
        return 'green';
      case 'CANCELLED':
        return 'red';
      default:
        return 'grey';
    }
  }
}

class OrderResponse {
  final String status;
  final String message;
  final OrderDetails? data;

  OrderResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? OrderDetails.fromJson(json['data']) : null,
    );
  }
}

class OrderService {
  static Future<OrderResponse> getOrderDetails(String orderId) async {
    try {
      // Get authentication token
      final token = await TokenService.getToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Construct API URL
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/$orderId/orderId');
      
      debugPrint('OrderService: 📋 Fetching order details from: $url');
      debugPrint('OrderService: 🔑 Using token: ${token.substring(0, 20)}...');

      // Make API request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('OrderService: 📊 Response status: ${response.statusCode}');
      debugPrint('OrderService: 📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final orderResponse = OrderResponse.fromJson(jsonData);
        
        if (orderResponse.status == 'SUCCESS' && orderResponse.data != null) {
          debugPrint('OrderService: ✅ Order details fetched successfully');
          debugPrint('OrderService: 📦 Order ID: ${orderResponse.data!.orderId}');
          debugPrint('OrderService: 🔄 Order Status: ${orderResponse.data!.orderStatus}');
          debugPrint('OrderService: 💰 Total Amount: ${orderResponse.data!.totalAmount}');
          debugPrint('OrderService: 🚚 Delivery Fees: ${orderResponse.data!.deliveryFees}');
          
          return orderResponse;
        } else {
          throw Exception(orderResponse.message.isNotEmpty 
              ? orderResponse.message 
              : 'Failed to fetch order details');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Order not found. Please check the order ID.');
      } else {
        throw Exception('Failed to fetch order details. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrderService: ❌ Error fetching order details: $e');
      rethrow;
    }
  }

  // Helper method to format currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Helper method to get estimated delivery time based on status
  static String getEstimatedDelivery(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '45-60 mins';
      case 'CONFIRMED':
        return '35-45 mins';
      case 'PREPARING':
        return '25-35 mins';
      case 'READY':
        return '15-25 mins';
      case 'OUT_FOR_DELIVERY':
        return '10-15 mins';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return '30-45 mins';
    }
  }
}