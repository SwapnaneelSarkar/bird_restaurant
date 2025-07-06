import 'dart:convert';
import 'package:http/http.dart' as http;
import 'delivery_partner_auth_service.dart';
import '../../models/order_model.dart';

class DeliveryPartnerOrdersService {
  static const String _baseUrl = 'https://api.bird.delivery/api';

  static Future<List<DeliveryPartnerOrder>> fetchAvailableOrders() async {
    final deliveryPartnerId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (deliveryPartnerId == null || deliveryPartnerId.isEmpty) {
      print('[API] Error: No delivery partner ID found');
      throw Exception('No delivery partner ID found. Please login again.');
    }
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      throw Exception('No delivery partner token found. Please login again.');
    }
    print('[API] Using token: ${token.substring(0, 20)}... and ID: $deliveryPartnerId');
    final url = Uri.parse('$_baseUrl/delivery-partner/orders/available?delivery_partner_id=$deliveryPartnerId');
    print('[API] GET: $url');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[API] Response status: \u001b[33m\u001b[1m${response.statusCode}\u001b[0m');
    print('[API] Response body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('[API] Parsed JSON: $data');
        if (data['status'] == 'SUCCESS') {
          final result = DeliveryPartnerOrderListResponse.fromJson(data);
          print('[API] Orders fetched: ${result.data.length}');
          return result.data;
        } else {
          print('[API] API returned non-success status: ${data['status']}');
          throw Exception('API returned: ${data['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        print('[API] Error parsing response: $e');
        throw Exception('Failed to parse response: $e');
      }
    } else {
      print('[API] Error: Failed to fetch orders: ${response.statusCode}');
      print('[API] Error response: ${response.body}');
      throw Exception('Failed to fetch orders: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<DeliveryPartnerOrder>> fetchAssignedOrders() async {
    final deliveryPartnerId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (deliveryPartnerId == null || deliveryPartnerId.isEmpty) {
      print('[API] Error: No delivery partner ID found');
      throw Exception('No delivery partner ID found. Please login again.');
    }
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      throw Exception('No delivery partner token found. Please login again.');
    }
    print('[API] Using token: ${token.substring(0, 20)}... and ID: $deliveryPartnerId');
    final url = Uri.parse('$_baseUrl/delivery-partner/orders/assigned?delivery_partner_id=$deliveryPartnerId');
    print('[API] GET: $url');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[API] Response status: \u001b[33m\u001b[1m${response.statusCode}\u001b[0m');
    print('[API] Response body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        print('[API] Parsed JSON: $data');
        if (data['status'] == 'SUCCESS') {
          final result = DeliveryPartnerOrderListResponse.fromJson(data);
          print('[API] Assigned orders fetched: ${result.data.length}');
          return result.data;
        } else {
          print('[API] API returned non-success status: ${data['status']}');
          throw Exception('API returned: ${data['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        print('[API] Error parsing response: $e');
        throw Exception('Failed to parse response: $e');
      }
    } else {
      print('[API] Error: Failed to fetch assigned orders: ${response.statusCode}');
      print('[API] Error response: ${response.body}');
      throw Exception('Failed to fetch assigned orders: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> fetchOrderDetailsById(String orderId) async {
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'No delivery partner token found. Please login again.'};
    }
    final url = Uri.parse('$_baseUrl/delivery-partner/orders/$orderId');
    print('[API] GET: $url');
    print('[API] Fetching order details for order ID: $orderId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[API] Order details response status: ${response.statusCode}');
    print('[API] Order details response body: ${response.body}');
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
      print('[API] Order details fetched successfully');
      return {'success': true, 'data': data['data']};
    } else {
      print('[API] Failed to fetch order details: ${data['message']}');
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch order details'};
    }
  }

  static Future<Map<String, dynamic>> acceptOrder({
    required String orderId,
  }) async {
    final deliveryPartnerId = await DeliveryPartnerAuthService.getDeliveryPartnerId();
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (deliveryPartnerId == null || deliveryPartnerId.isEmpty) {
      print('[API] Error: No delivery partner ID found');
      return {'success': false, 'message': 'No delivery partner ID found. Please login again.'};
    }
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      return {'success': false, 'message': 'No delivery partner token found. Please login again.'};
    }
    final url = Uri.parse('$_baseUrl/delivery-partner/orders/accept?delivery_partner_id=$deliveryPartnerId');
    print('[API] POST: $url');
    print('[API] Accepting order: $orderId for delivery partner: $deliveryPartnerId');
    print('[API] Using token: ${token.substring(0, 20)}...');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'order_id': orderId}),
    );
    print('[API] Accept order response status: ${response.statusCode}');
    print('[API] Accept order response body: ${response.body}');
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
      print('[API] Order accepted successfully');
      return {'success': true, 'data': data['data']};
    } else {
      print('[API] Failed to accept order: ${data['message']}');
      return {'success': false, 'message': data['message'] ?? 'Failed to accept order'};
    }
  }

  static Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    final url = Uri.parse('$_baseUrl/user/$userId');
    print('[API] GET: $url');
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      return {'success': false, 'message': 'No delivery partner token found. Please login again.'};
    }
    print('[API] Using token: ${token.substring(0, 20)}...');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[API] User details response status: ${response.statusCode}');
    print('[API] User details response body: ${response.body}');
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      print('[API] User details fetched successfully');
      return {'success': true, 'data': data['data']};
    } else {
      print('[API] Failed to fetch user details: ${data['message']}');
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch user details'};
    }
  }

  static Future<Map<String, dynamic>> fetchRestaurantDetails(String partnerId) async {
    final url = Uri.parse('$_baseUrl/partner/restaurant/$partnerId');
    print('[API] GET: $url');
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      return {'success': false, 'message': 'No delivery partner token found. Please login again.'};
    }
    print('[API] Using token: ${token.substring(0, 20)}...');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[API] Restaurant details response status: ${response.statusCode}');
    print('[API] Restaurant details response body: ${response.body}');
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
      print('[API] Restaurant details fetched successfully');
      return {'success': true, 'data': data['data']};
    } else {
      print('[API] Failed to fetch restaurant details: ${data['message']}');
      return {'success': false, 'message': data['message'] ?? 'Failed to fetch restaurant details'};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final url = Uri.parse('$_baseUrl/partner/orders/$orderId/status');
    print('[API] PUT: $url');
    print('[API] Request body: {"status": "$status"}');
    
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      return {'success': false, 'message': 'No delivery partner token found. Please login again.'};
    }
    
    print('[API] Using token: ${token.substring(0, 20)}...');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );
      
      print('[API] Update order status response status: ${response.statusCode}');
      print('[API] Update order status response body: ${response.body}');
      
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
        print('[API] Order status updated successfully');
        return {'success': true, 'message': data['message'] ?? 'Order status updated successfully'};
      } else {
        print('[API] Failed to update order status: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to update order status'};
      }
    } catch (e) {
      print('[API] Error updating order status: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
} 