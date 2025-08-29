import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';

class RestaurantDetails {
  final String? cookingTime;
  final String? supercategoryId;
  final String? supercategoryName;
  final String? restaurantName;
  final String? address;

  const RestaurantDetails({
    this.cookingTime,
    this.supercategoryId,
    this.supercategoryName,
    this.restaurantName,
    this.address,
  });

  factory RestaurantDetails.fromJson(Map<String, dynamic> json) {
    return RestaurantDetails(
      cookingTime: json['cooking_time']?.toString(),
      supercategoryId: json['supercategory_id']?.toString(),
      supercategoryName: json['supercategory_name']?.toString(),
      restaurantName: json['restaurant_name']?.toString(),
      address: json['address']?.toString(),
    );
  }

  bool get isFoodStore {
    // Check if supercategory ID is the food supercategory ID
    return supercategoryId == "7acc47a2fa5a4eeb906a753b3" || 
           supercategoryName?.toLowerCase() == "food";
  }
}

class RestaurantDetailsService {
  static const String baseUrl = 'https://api.bird.delivery/api';
  
  // Cache for restaurant details to avoid multiple API calls
  static Map<String, RestaurantDetails> _cache = {};
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  static Future<RestaurantDetails?> getRestaurantDetails(String partnerId) async {
    try {
      // Check cache first
      if (_cache.containsKey(partnerId) && _lastCacheTime != null) {
        final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
        if (timeSinceCache < _cacheValidDuration) {
          debugPrint('🔄 RestaurantDetailsService: Using cached data for partner: $partnerId');
          return _cache[partnerId];
        }
      }

      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('❌ RestaurantDetailsService: No token found');
        return null;
      }

      final url = Uri.parse('$baseUrl/partner/restaurant/$partnerId');
      debugPrint('🔄 RestaurantDetailsService: Fetching restaurant details from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final data = responseData['data'];
          final restaurantDetails = RestaurantDetails.fromJson(data);
          
          // Update cache
          _cache[partnerId] = restaurantDetails;
          _lastCacheTime = DateTime.now();
          
          debugPrint('✅ RestaurantDetailsService: Fetched restaurant details for partner: $partnerId');
          debugPrint('   - Cooking time: ${restaurantDetails.cookingTime}');
          debugPrint('   - Supercategory: ${restaurantDetails.supercategoryName} (${restaurantDetails.supercategoryId})');
          debugPrint('   - Is food store: ${restaurantDetails.isFoodStore}');
          
          return restaurantDetails;
        } else {
          debugPrint('❌ RestaurantDetailsService: API returned error: ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('❌ RestaurantDetailsService: HTTP error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ RestaurantDetailsService: Error fetching restaurant details: $e');
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
    _lastCacheTime = null;
    debugPrint('🔄 RestaurantDetailsService: Cache cleared');
  }
} 