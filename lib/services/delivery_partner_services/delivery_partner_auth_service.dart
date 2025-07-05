import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryPartnerAuthService {
  static const String _baseUrl = 'https://api.bird.delivery/api';
  static const String _deliveryPartnerTokenKey = 'delivery_partner_token';
  static const String _deliveryPartnerIdKey = 'delivery_partner_id';
  static const String _deliveryPartnerMobileKey = 'delivery_partner_mobile';

  // Authenticate delivery partner after OTP verification
  static Future<Map<String, dynamic>> authenticateDeliveryPartner(String phone) async {
    try {
      final url = Uri.parse('$_baseUrl/delivery-partner/auth');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
        // Save authentication data
        await _saveDeliveryPartnerAuthData(data['data']);
        // Ensure 'action' is included in the returned data
        final Map<String, dynamic> resultData = Map<String, dynamic>.from(data['data']);
        return {
          'success': true,
          'action': data['action'],
          'data': resultData,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Authentication failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Save delivery partner authentication data
  static Future<void> _saveDeliveryPartnerAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_deliveryPartnerTokenKey, data['token']);
    await prefs.setString(_deliveryPartnerIdKey, data['delivery_partner_id']);
    await prefs.setString(_deliveryPartnerMobileKey, data['phone']);
    
    print('Delivery partner auth data saved successfully');
  }

  // Get delivery partner token
  static Future<String?> getDeliveryPartnerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deliveryPartnerTokenKey);
  }

  // Get delivery partner ID
  static Future<String?> getDeliveryPartnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deliveryPartnerIdKey);
  }

  // Get delivery partner mobile
  static Future<String?> getDeliveryPartnerMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deliveryPartnerMobileKey);
  }

  // Check if delivery partner is authenticated
  static Future<bool> isDeliveryPartnerAuthenticated() async {
    final token = await getDeliveryPartnerToken();
    final id = await getDeliveryPartnerId();
    final mobile = await getDeliveryPartnerMobile();
    
    return token != null && token.isNotEmpty &&
           id != null && id.isNotEmpty &&
           mobile != null && mobile.isNotEmpty;
  }

  // Clear delivery partner authentication data
  static Future<void> clearDeliveryPartnerAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deliveryPartnerTokenKey);
    await prefs.remove(_deliveryPartnerIdKey);
    await prefs.remove(_deliveryPartnerMobileKey);
    
    print('Delivery partner auth data cleared');
  }

  static Future<Map<String, dynamic>> updateDeliveryPartnerProfile({
    required String deliveryPartnerId,
    required String name,
    required String email,
    required String vehicleNumber,
    required String vehicleType,
    required double latitude,
    required double longitude,
    // Add license and vehicle doc params
    required File? licensePhoto,
    required File? vehicleDocument,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/delivery-partner/$deliveryPartnerId');
      final token = await getDeliveryPartnerToken();
      var request = http.MultipartRequest('PUT', url);
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['vehicle_number'] = vehicleNumber;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['current_latitude'] = latitude.toString();
      request.fields['current_longitude'] = longitude.toString();
      if (licensePhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('license_photo', licensePhoto.path));
      }
      if (vehicleDocument != null) {
        request.files.add(await http.MultipartFile.fromPath('vehicle_document', vehicleDocument.path));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch delivery partner details by ID
  static Future<Map<String, dynamic>> fetchDeliveryPartnerDetails(String deliveryPartnerId) async {
    try {
      final url = Uri.parse('$_baseUrl/delivery-partner/$deliveryPartnerId');
      final token = await getDeliveryPartnerToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
} 