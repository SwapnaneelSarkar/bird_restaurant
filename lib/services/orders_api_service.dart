// lib/services/orders_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../models/order_model.dart';

class OrdersApiService {
  static const int timeoutSeconds = 10;

  // Fetch order summary - UPDATED with partner ID
  static Future<OrderSummaryResponse> fetchOrderSummary() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      // Get partner ID - you'll need to implement this method in TokenService
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/summary/$partnerId');
      
      debugPrint('OrdersApiService: 📊 Fetching order summary: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: timeoutSeconds));

      debugPrint('OrdersApiService: 📊 Summary response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 Summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderSummaryResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch order summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching order summary: $e');
      rethrow;
    }
  }

  // Fetch order history - UPDATED with partner ID
  static Future<OrderHistoryResponse> fetchOrderHistory() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      // Get partner ID - you'll need to implement this method in TokenService
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/history/$partnerId');
      
      debugPrint('OrdersApiService: 📋 Fetching order history: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: timeoutSeconds));

      debugPrint('OrdersApiService: 📋 History response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 History response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderHistoryResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch order history. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching order history: $e');
      rethrow;
    }
  }

  // Update order status - existing method (unchanged)
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/$orderId/status');
      
      debugPrint('OrdersApiService: 🔄 Updating order status: $url');
      debugPrint('OrdersApiService: 📝 New status: $newStatus');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': newStatus,
        }),
      ).timeout(const Duration(seconds: timeoutSeconds));

      debugPrint('OrdersApiService: 🔄 Update response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['status'] == 'SUCCESS';
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to update order status. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error updating order status: $e');
      rethrow;
    }
  }

  // Fetch orders with date range - UPDATED with partner ID
  static Future<OrderHistoryResponse> fetchOrdersWithDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      // Get partner ID - you'll need to implement this method in TokenService
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      };
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/history/$partnerId').replace(
        queryParameters: queryParams,
      );
      
      debugPrint('OrdersApiService: 📅 Fetching orders with date range: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: timeoutSeconds));

      debugPrint('OrdersApiService: 📅 Date range response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderHistoryResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching orders with date range: $e');
      rethrow;
    }
  }

  // Helper method to get date range for today
  static Map<String, String> getTodayDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return {
      'startDate': today.toIso8601String().split('T')[0],
      'endDate': tomorrow.toIso8601String().split('T')[0],
    };
  }

  // Helper method to get date range for this week
  static Map<String, String> getThisWeekDateRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return {
      'startDate': startOfWeek.toIso8601String().split('T')[0],
      'endDate': endOfWeek.toIso8601String().split('T')[0],
    };
  }

  // Helper method to get date range for this month
  static Map<String, String> getThisMonthDateRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return {
      'startDate': startOfMonth.toIso8601String().split('T')[0],
      'endDate': endOfMonth.toIso8601String().split('T')[0],
    };
  }
}