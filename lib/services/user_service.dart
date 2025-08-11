import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'token_service.dart';

class UserService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/user/$userId');
      debugPrint('UserService: 📞 Fetching user details for userId: $userId');
      debugPrint('UserService: 🌐 API URL: $url');
      
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('UserService: ❌ No token found');
        return {
          'success': false, 
          'message': 'No token found. Please login again.'
        };
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('UserService: 📡 Response status: ${response.statusCode}');
      debugPrint('UserService: 📄 Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == true) {
        debugPrint('UserService: ✅ User details fetched successfully');
        return {
          'success': true, 
          'data': data['data']
        };
      } else {
        debugPrint('UserService: ❌ Failed to fetch user details: ${data['message']}');
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to fetch user details'
        };
      }
    } catch (e) {
      debugPrint('UserService: ❌ Error fetching user details: $e');
      return {
        'success': false, 
        'message': 'Network error: $e'
      };
    }
  }
} 