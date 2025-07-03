import 'dart:convert';
import 'package:http/http.dart' as http;
import 'delivery_partner_auth_service.dart';
import '../../models/order_model.dart';

class DeliveryPartnerOrdersService {
  static const String _baseUrl = 'https://api.bird.delivery/api';

  static Future<List<DeliveryPartnerOrder>> fetchAvailableOrders() async {
    final url = Uri.parse('$_baseUrl/delivery-partner/orders/available');
    print('[API] GET: $url');
    final token = await DeliveryPartnerAuthService.getDeliveryPartnerToken();
    if (token == null || token.isEmpty) {
      print('[API] Error: No delivery partner token found');
      throw Exception('No delivery partner token found. Please login again.');
    }
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
      final data = json.decode(response.body);
      final result = DeliveryPartnerOrderListResponse.fromJson(data);
      print('[API] Orders fetched: ${result.data.length}');
      return result.data;
    } else {
      print('[API] Error: Failed to fetch orders: ${response.statusCode}');
      throw Exception('Failed to fetch orders: ${response.statusCode}');
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
      final data = json.decode(response.body);
      final result = DeliveryPartnerOrderListResponse.fromJson(data);
      print('[API] Assigned orders fetched: ${result.data.length}');
      return result.data;
    } else {
      print('[API] Error: Failed to fetch assigned orders: ${response.statusCode}');
      throw Exception('Failed to fetch assigned orders: ${response.statusCode}');
    }
  }
} 