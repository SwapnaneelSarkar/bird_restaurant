import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../models/cuisine_model.dart';

class CuisineService {
  static Future<List<Cuisine>> fetchCuisines() async {
    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('CuisineService: ❌ No token found');
        return [];
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/partner/cuisines');
      debugPrint('CuisineService: 🌐 GET $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('CuisineService: 📡 Status ${response.statusCode}');
      debugPrint('CuisineService: 📄 Body ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody is Map && jsonBody['status'] == 'SUCCESS') {
          final List<dynamic> data = jsonBody['data'] ?? [];
          return data.map((e) => Cuisine.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('CuisineService: ❌ Error $e');
      return [];
    }
  }
}

