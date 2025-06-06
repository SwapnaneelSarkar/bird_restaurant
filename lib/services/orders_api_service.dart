// lib/services/orders_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/order_model.dart';
import '../presentation/screens/orders/state.dart';
import 'token_service.dart';

class OrdersApiService {
  static Future<OrderSummaryResponse> getOrderSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await TokenService.getToken();
      final partnerId = await TokenService.getUserId();
      
      if (token == null || partnerId == null) {
        throw Exception('No authentication found. Please login again.');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final queryString = queryParams.isNotEmpty 
          ? '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')
          : '';

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/summary/$partnerId$queryString');
      
      debugPrint('OrdersApiService: 📊 Fetching order summary from: $url');
      debugPrint('OrdersApiService: 🔑 Using token: ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('OrdersApiService: 📈 Summary response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 Summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return OrderSummaryResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Order summary not found.');
      } else {
        throw Exception('Failed to fetch order summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching order summary: $e');
      rethrow;
    }
  }

  static Future<OrderHistoryResponse> getOrderHistory({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = await TokenService.getToken();
      final partnerId = await TokenService.getUserId();
      
      if (token == null || partnerId == null) {
        throw Exception('No authentication found. Please login again.');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status != 'all') queryParams['status'] = status;
      
      final queryString = queryParams.isNotEmpty 
          ? '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')
          : '';

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/history/$partnerId$queryString');
      
      debugPrint('OrdersApiService: 📚 Fetching order history from: $url');
      debugPrint('OrdersApiService: 🔑 Using token: ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('OrdersApiService: 📖 History response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 History response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return OrderHistoryResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        // No orders found is okay, return empty list
        return OrderHistoryResponse(
          status: 'SUCCESS',
          message: 'No orders found',
          data: [],
        );
      } else {
        throw Exception('Failed to fetch order history. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching order history: $e');
      rethrow;
    }
  }

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
      ).timeout(const Duration(seconds: 10));

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

  // Helper method to convert OrderSummaryData to OrderStats
  static OrderStats convertSummaryToStats(OrderSummaryData summary) {
    return OrderStats(
      total: summary.totalOrders,
      pending: summary.totalPending,
      confirmed: summary.totalConfirmed,
      preparing: summary.totalPreparing,
      delivery: summary.totalReadyForDelivery + summary.totalOutForDelivery,
      delivered: summary.totalDelivered,
      cancelled: summary.totalCancelled,
    );
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