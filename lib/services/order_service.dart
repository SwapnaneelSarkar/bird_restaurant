// lib/services/order_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../presentation/screens/chat/state.dart';
import 'token_service.dart';

class OrderService {
  static const String baseUrl = 'https://api.bird.delivery/api';
  
  static Future<OrderDetails?> getOrderDetails({
    required String partnerId,
    required String orderId,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Use the FULL order ID - do not truncate or format it
      final fullOrderId = _getFullOrderId(orderId);
      final url = Uri.parse('$baseUrl/partner/orders/$partnerId/$fullOrderId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('OrderService: GET $url');
      print('OrderService: Using Partner ID: $partnerId');
      print('OrderService: Using Full Order ID: $fullOrderId');
      print('OrderService: Response status: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        
        if (responseBody['status'] == 'SUCCESS' && responseBody['data'] != null) {
          return OrderDetails.fromJson(responseBody['data']);
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to get order details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch order details');
      }
    } catch (e) {
      print('OrderService: Error fetching order details: $e');
      rethrow;
    }
  }

  static Future<bool> updateOrderStatus({
    required String partnerId,
    required String orderId,
    required String newStatus,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Validate status before API call
      if (!isValidStatus(newStatus)) {
        print('OrderService: Invalid status: $newStatus');
        return false;
      }

      // Use the FULL order ID - do not truncate or format it
      final fullOrderId = _getFullOrderId(orderId);
      final url = Uri.parse('$baseUrl/partner/orders/$partnerId/$fullOrderId/status');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': newStatus,
        }),
      );

      print('OrderService: PUT $url');
      print('OrderService: Request body: {"status": "$newStatus"}');
      print('OrderService: Response status: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return responseBody['status'] == 'SUCCESS';
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to update order status');
      }
    } catch (e) {
      print('OrderService: Error updating order status: $e');
      return false;
    }
  }

  // Helper method to get partner ID from token or user preferences
  static Future<String?> getPartnerId() async {
    try {
      // This should be implemented based on how partner ID is stored
      // It might be in the token, user preferences, or a separate API call
      final userId = await TokenService.getUserId();
      return userId; // Assuming partner ID is same as user ID for now
    } catch (e) {
      print('OrderService: Error getting partner ID: $e');
      return null;
    }
  }

  // CRITICAL FIX: Get the full order ID without truncation
  static String _getFullOrderId(String orderId) {
    // Remove # prefix if present, but keep the FULL ID
    if (orderId.startsWith('#')) {
      return orderId.substring(1);
    }
    return orderId;
  }

  // Helper method to format order status for display
  static String formatOrderStatus(String status) {
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
        return status;
    }
  }

  // Updated: Get available status options based on current status - RESTRICTED TO REQUIRED STATUSES ONLY
  static List<String> getAvailableStatusOptions(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'PENDING':
        return ['CONFIRMED', 'CANCELLED'];
      case 'CONFIRMED':
        return ['PREPARING', 'CANCELLED'];
      case 'PREPARING':
        return ['READY_FOR_DELIVERY', 'CANCELLED'];
      case 'READY_FOR_DELIVERY':
        return ['OUT_FOR_DELIVERY', 'CANCELLED'];
      case 'OUT_FOR_DELIVERY':
        return ['DELIVERED'];
      case 'DELIVERED':
        return []; // No further status changes allowed
      case 'CANCELLED':
        return []; // No further status changes allowed
      default:
        return ['CONFIRMED', 'CANCELLED']; // Default to pending options
    }
  }

  // Validate if the status is one of the allowed statuses
  static bool isValidStatus(String status) {
    const allowedStatuses = [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_DELIVERY',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELLED'
    ];
    return allowedStatuses.contains(status.toUpperCase());
  }

  // Get all valid statuses
  static List<String> getAllValidStatuses() {
    return [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_DELIVERY',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELLED'
    ];
  }

  // Get status icon
  static IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY_FOR_DELIVERY':
        return Icons.done_all;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return const Color(0xFFE17A47);
      case 'READY_FOR_DELIVERY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}