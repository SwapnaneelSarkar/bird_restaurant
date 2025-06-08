// lib/services/order_service.dart

import 'dart:convert';
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
      case 'READY':
        return 'Ready for Pickup';
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

  // Get available status options based on current status
  static List<String> getAvailableStatusOptions(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'PENDING':
        return ['CONFIRMED', 'CANCELLED'];
      case 'CONFIRMED':
        return ['PREPARING', 'CANCELLED'];
      case 'PREPARING':
        return ['READY'];
      case 'READY':
        return ['OUT_FOR_DELIVERY'];
      case 'OUT_FOR_DELIVERY':
        return ['DELIVERED'];
      default:
        return [];
    }
  }
}