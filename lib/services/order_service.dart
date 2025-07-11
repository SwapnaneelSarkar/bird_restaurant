// lib/services/order_service.dart - UPDATED WITH STATUS FUNCTIONALITY

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../presentation/screens/chat/state.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../utils/time_utils.dart';
import '../models/order_model.dart';

class OrderService {
  static const String baseUrl = 'https://api.bird.delivery/api';
  
  // REQUIRED: The 7 status options as specified
  static const List<String> validStatuses = [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'READY_FOR_DELIVERY',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED'
  ];
  
  static Future<OrderDetails?> getOrderDetails({
    required String partnerId,
    required String orderId,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      final fullOrderId = _getFullOrderId(orderId);
      final partnerUrl = Uri.parse('$baseUrl/partner/orders/$partnerId/$fullOrderId');
      final userUrl = Uri.parse('$baseUrl/user/order/$fullOrderId');
      // Try partner endpoint first
      var response = await http.get(
        partnerUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('OrderService: GET $partnerUrl');
      print('OrderService: Response status:  [33m${response.statusCode} [0m');
      print('OrderService: RAW response body: ${response.body}'); // <-- Added raw response print
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'SUCCESS' && responseBody['data'] != null) {
          return OrderDetails.fromJson(responseBody['data']);
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to get order details');
        }
      } else if (response.statusCode == 404) {
        // Try user endpoint as fallback
        response = await http.get(
          userUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('OrderService: Fallback GET $userUrl');
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
          throw Exception('HTTP ${response.statusCode}: Failed to fetch order details from both endpoints');
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
      print('OrderService: Invalid status: $newStatus. Valid statuses: $validStatuses');
      throw Exception('Invalid status: $newStatus');
    }

    // Use the FULL order ID - do not truncate or format it
    final fullOrderId = _getFullOrderId(orderId);
    final url = Uri.parse('$baseUrl/partner/orders/$fullOrderId/status?partner_id=$partnerId');
    
    final requestBody = {
      'status': newStatus.toUpperCase(),
      'updated_at': TimeUtils.toIsoStringForAPI(TimeUtils.getCurrentIST()),
    };
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    print('OrderService: PUT $url');
    print('OrderService: Request body: ${json.encode(requestBody)}');
    print('OrderService: Response status: ${response.statusCode}');
    print('OrderService: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final success = responseBody['status'] == 'SUCCESS';
      
      if (success) {
        print('OrderService: ✅ Successfully updated order status to $newStatus');
        return true;
      } else {
        // API returned ERROR status - throw with the full response for detailed error handling
        print('OrderService: ❌ API returned error: ${responseBody['message']}');
        final errorMessage = responseBody['message'] ?? 'Unknown error occurred';
        
        // Include allowed next statuses if provided
        if (responseBody['allowedNextStatuses'] != null) {
          final allowedStatuses = List<String>.from(responseBody['allowedNextStatuses']);
          print('OrderService: 📝 Allowed next statuses: $allowedStatuses');
          
          // Throw with structured error info
          throw Exception(json.encode({
            'message': errorMessage,
            'allowedNextStatuses': allowedStatuses,
            'status': 'ERROR'
          }));
        } else {
          throw Exception(json.encode({
            'message': errorMessage,
            'status': 'ERROR'
          }));
        }
      }
    } else if (response.statusCode == 400) {
      // Bad request - likely validation error
      try {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        print('OrderService: ❌ Validation error: ${errorBody['message']}');
        
        throw Exception(json.encode({
          'message': errorBody['message'] ?? 'Invalid request',
          'allowedNextStatuses': errorBody['allowedNextStatuses'],
          'status': 'ERROR'
        }));
      } catch (e) {
        throw Exception(json.encode({
          'message': 'Invalid request - status transition not allowed',
          'status': 'ERROR'
        }));
      }
    } else {
      print('OrderService: ❌ HTTP Error ${response.statusCode}');
      throw Exception(json.encode({
        'message': 'Server error (${response.statusCode}). Please try again.',
        'status': 'ERROR'
      }));
    }
  } catch (e) {
    print('OrderService: ❌ Error updating order status: $e');
    
    // Re-throw if it's already a structured error
    if (e.toString().contains('"status":"ERROR"')) {
      rethrow;
    }
    
    // Otherwise, wrap in a generic error
    throw Exception(json.encode({
      'message': 'Network error. Please check your connection and try again.',
      'status': 'ERROR'
    }));
  }
}

// ALSO ADD this new method to get status validation info
static Map<String, dynamic> getStatusValidationInfo(String currentStatus, String newStatus) {
  final isValid = isValidStatusTransition(currentStatus, newStatus);
  final allowedStatuses = getAvailableStatusOptions(currentStatus);
  
  return {
    'isValid': isValid,
    'currentStatus': currentStatus,
    'requestedStatus': newStatus,
    'allowedStatuses': allowedStatuses,
    'message': isValid 
        ? 'Status transition is valid'
        : 'Cannot change status from ${formatOrderStatus(currentStatus)} to ${formatOrderStatus(newStatus)}',
  };
}

  // Helper method to get partner ID from token or user preferences
  static Future<String?> getPartnerId() async {
    try {
      // First try to get from token service if it has a specific partner ID method
      try {
        return await TokenService.getUserId();
      } catch (e) {
        // Fall back to user ID if no specific partner ID method
        final userId = await TokenService.getUserId();
        print('OrderService: Using user ID as partner ID: $userId');
        return userId;
      }
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
        return status.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
    }
  }

  // UPDATED: Get available status options based on current status - RESTRICTED TO REQUIRED STATUSES ONLY
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
    return validStatuses.contains(status.toUpperCase());
  }

  // Get all valid statuses
  static List<String> getAllValidStatuses() {
    return List.from(validStatuses);
  }

  // ENHANCED: Check if status transition is valid
  static bool isValidStatusTransition(String fromStatus, String toStatus) {
    final availableStatuses = getAvailableStatusOptions(fromStatus);
    return availableStatuses.contains(toStatus.toUpperCase());
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

  // NEW: Get status emoji for enhanced UI
  static String getStatusEmoji(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '⏳';
      case 'CONFIRMED':
        return '✅';
      case 'PREPARING':
        return '👨‍🍳';
      case 'READY_FOR_DELIVERY':
        return '📦';
      case 'OUT_FOR_DELIVERY':
        return '🚚';
      case 'DELIVERED':
        return '🎉';
      case 'CANCELLED':
        return '❌';
      default:
        return '❓';
    }
  }

  // NEW: Get status description for UI
  static String getStatusDescription(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Order is waiting for confirmation';
      case 'CONFIRMED':
        return 'Order has been confirmed and accepted';
      case 'PREPARING':
        return 'Kitchen is preparing the order';
      case 'READY_FOR_DELIVERY':
        return 'Order is ready for pickup/delivery';
      case 'OUT_FOR_DELIVERY':
        return 'Order is on the way to customer';
      case 'DELIVERED':
        return 'Order has been delivered successfully';
      case 'CANCELLED':
        return 'Order has been cancelled';
      default:
        return 'Unknown status';
    }
  }

  // NEW: Batch update multiple order statuses (for future use)
  static Future<Map<String, bool>> batchUpdateOrderStatus({
    required String partnerId,
    required Map<String, String> orderUpdates,
  }) async {
    final results = <String, bool>{};
    
    for (final entry in orderUpdates.entries) {
      final orderId = entry.key;
      final newStatus = entry.value;
      
      try {
        final success = await updateOrderStatus(
          partnerId: partnerId,
          orderId: orderId,
          newStatus: newStatus,
        );
        
        results[orderId] = success;
        print('OrderService: Batch update - Order $orderId: ${success ? "SUCCESS" : "FAILED"}');
        
        // Add a small delay between requests to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('OrderService: Batch update error for order $orderId: $e');
        results[orderId] = false;
      }
    }
    
    final successful = results.values.where((v) => v).length;
    final total = results.length;
    print('OrderService: Batch update completed - $successful/$total successful');
    
    return results;
  }

  // NEW: Get status priority for sorting (lower number = higher priority)
  static int getStatusPriority(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 1;
      case 'CONFIRMED':
        return 2;
      case 'PREPARING':
        return 3;
      case 'READY_FOR_DELIVERY':
        return 4;
      case 'OUT_FOR_DELIVERY':
        return 5;
      case 'DELIVERED':
        return 6;
      case 'CANCELLED':
        return 7;
      default:
        return 999;
    }
  }

  // NEW: Check if status is final (no more changes allowed)
  static bool isFinalStatus(String status) {
    return ['DELIVERED', 'CANCELLED'].contains(status.toUpperCase());
  }

  // NEW: Check if status is active (order is in progress)
  static bool isActiveStatus(String status) {
    return ['CONFIRMED', 'PREPARING', 'READY_FOR_DELIVERY', 'OUT_FOR_DELIVERY']
        .contains(status.toUpperCase());
  }

  static Future<Order?> fetchOrderDetailsById(String orderId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No authentication token found');
      final url = Uri.parse('${ApiConstants.baseUrl}/user/order/$orderId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'SUCCESS' && responseBody['data'] != null) {
          return Order.fromJson(responseBody['data']);
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to get order details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch order details');
      }
    } catch (e) {
      print('OrderService: Error fetching order details: $e');
      return null;
    }
  }
}