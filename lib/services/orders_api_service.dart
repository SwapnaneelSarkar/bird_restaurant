// ENHANCED DEBUG VERSION: lib/services/orders_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../models/order_model.dart';
import '../utils/time_utils.dart';

class OrdersApiService {
  static const int timeoutSeconds = 10;

  // Fetch order summary - UPDATED with partner ID
  static Future<OrderSummaryResponse> fetchOrderSummary() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

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

  // ENHANCED DEBUG: Fetch order history with detailed logging
  static Future<OrderHistoryResponse> fetchOrderHistory() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

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
        
        // ENHANCED DEBUG: Check the actual structure of the API response
        debugPrint('OrdersApiService: 🔍 DEBUGGING API RESPONSE STRUCTURE');
        debugPrint('OrdersApiService: 🔍 Response data type: ${responseData.runtimeType}');
        debugPrint('OrdersApiService: 🔍 Response keys: ${responseData.keys}');
        
        if (responseData['data'] != null) {
          final ordersData = responseData['data'];
          debugPrint('OrdersApiService: 🔍 Orders data type: ${ordersData.runtimeType}');
          debugPrint('OrdersApiService: 🔍 Orders data length: ${ordersData.length}');
          
          // Log first few orders to see their structure
          if (ordersData.isNotEmpty) {
            debugPrint('OrdersApiService: 🔍 FIRST ORDER STRUCTURE:');
            final firstOrder = ordersData[0];
            debugPrint('OrdersApiService: 🔍 First order keys: ${firstOrder.keys}');
            debugPrint('OrdersApiService: 🔍 First order status field: ${firstOrder['status']}');
            debugPrint('OrdersApiService: 🔍 First order order_status field: ${firstOrder['order_status']}');
            debugPrint('OrdersApiService: 🔍 First order state field: ${firstOrder['state']}');
            debugPrint('OrdersApiService: 🔍 Complete first order: $firstOrder');
            
            // Check if there are orders with different statuses
            if (ordersData.length > 1) {
              debugPrint('OrdersApiService: 🔍 CHECKING OTHER ORDERS FOR STATUS VARIETY:');
              for (int i = 0; i < ordersData.length && i < 5; i++) {
                final order = ordersData[i];
                debugPrint('OrdersApiService: 🔍 Order $i - ID: ${order['order_id'] ?? order['id']}, Status: ${order['status']}, OrderStatus: ${order['order_status']}, State: ${order['state']}');
              }
            }
          }
        }
        
        final historyResponse = OrderHistoryResponse.fromJson(responseData);
        
        // ENHANCED DEBUG: Check parsed orders
        debugPrint('OrdersApiService: 🔍 PARSED ORDERS DEBUG:');
        debugPrint('OrdersApiService: 🔍 Total parsed orders: ${historyResponse.data.length}');
        for (int i = 0; i < historyResponse.data.length && i < 5; i++) {
          final order = historyResponse.data[i];
          debugPrint('OrdersApiService: 🔍 Parsed Order $i - ID: ${order.id}, Status: "${order.status}", OrderStatus Enum: ${order.orderStatus}');
        }
        
        return historyResponse;
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
      debugPrint('OrdersApiService: 🎯 updateOrderStatus called');
      debugPrint('OrdersApiService: 🎯 orderId: $orderId');
      debugPrint('OrdersApiService: 🎯 newStatus: $newStatus');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      final partnerId = await TokenService.getUserId();
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/$orderId/status?partner_id=$partnerId');
      
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
        final success = responseData['status'] == 'SUCCESS';
        debugPrint('OrdersApiService: ✅ API call successful, success: $success');
        return success;
      } else if (response.statusCode == 401) {
        debugPrint('OrdersApiService: ❌ Unauthorized error');
        throw Exception('Unauthorized. Please login again.');
      } else {
        debugPrint('OrdersApiService: ❌ HTTP error: ${response.statusCode}');
        throw Exception('Failed to update order status. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error updating order status: $e');
      debugPrint('OrdersApiService: ❌ Error stack trace: ${StackTrace.current}');
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

      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final queryParams = {
        'start_date': TimeUtils.toIsoStringForAPI(startDate).split('T')[0],
        'end_date': TimeUtils.toIsoStringForAPI(endDate).split('T')[0],
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

  // Fetch today's order summary
  static Future<TodayOrderSummaryResponse> fetchTodayOrderSummary() async {
    try {
      final token = await TokenService.getToken();
      
      if (token == null) {
        throw Exception('No authentication found. Please login again.');
      }

      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/orders/today-summary/$partnerId');
      
      debugPrint('OrdersApiService: 📊 Fetching today\'s order summary: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: timeoutSeconds));

      debugPrint('OrdersApiService: 📊 Today\'s summary response status: ${response.statusCode}');
      debugPrint('OrdersApiService: 📋 Today\'s summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return TodayOrderSummaryResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch today\'s order summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrdersApiService: ❌ Error fetching today\'s order summary: $e');
      rethrow;
    }
  }
}