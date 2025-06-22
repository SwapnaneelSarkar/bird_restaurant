import 'package:shared_preferences/shared_preferences.dart';
import 'profile_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'token_service.dart';

class RestaurantInfoService {
  static final ProfileUpdateService _profileUpdateService = ProfileUpdateService();
  
  // Cache for restaurant info to avoid multiple async calls
  static Map<String, String>? _cachedInfo;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  static Future<Map<String, String>> getRestaurantInfo() async {
    // Check if we have valid cached data
    if (_cachedInfo != null && _lastCacheTime != null) {
      final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
      if (timeSinceCache < _cacheValidDuration) {
        debugPrint('🔄 RestaurantInfoService: Using cached data');
        return _cachedInfo!;
      }
    }
    
    try {
      // First try to get from API
      final apiInfo = await _fetchFromAPI();
      if (apiInfo.isNotEmpty) {
        // Update cache with API data
        _cachedInfo = apiInfo;
        _lastCacheTime = DateTime.now();
        
        // Also save to SharedPreferences for offline access
        await _saveToSharedPreferences(apiInfo);
        
        debugPrint('🔄 RestaurantInfoService: Updated cache with API data');
        return apiInfo;
      }
      
      // Fallback to SharedPreferences if API fails
      final prefs = await SharedPreferences.getInstance();
      final prefsInfo = {
        'name': prefs.getString('restaurant_name') ?? '',
        'slogan': prefs.getString('restaurant_address') ?? '',
        'imageUrl': prefs.getString('restaurant_image_url') ?? '',
      };
      
      // Update cache
      _cachedInfo = prefsInfo;
      _lastCacheTime = DateTime.now();
      
      debugPrint('🔄 RestaurantInfoService: Updated cache with SharedPreferences data');
      return prefsInfo;
    } catch (e) {
      debugPrint('❌ RestaurantInfoService: Error getting restaurant info: $e');
      // Return cached data if available, otherwise empty map
      return _cachedInfo ?? {'name': '', 'slogan': '', 'imageUrl': ''};
    }
  }
  
  static Future<Map<String, String>> _fetchFromAPI() async {
    try {
      // Get user ID and token
      final userId = await TokenService.getUserId();
      final token = await TokenService.getToken();
      
      if (userId == null || token == null) {
        debugPrint('❌ RestaurantInfoService: No user ID or token available');
        return {};
      }
      
      // Call the restaurant API
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/restaurant/$userId');
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
          
          // Extract restaurant info
          String name = data['restaurant_name'] ?? '';
          String slogan = data['address'] ?? '';
          String imageUrl = '';
          
          // Handle restaurant photos
          if (data['restaurant_photos'] != null) {
            if (data['restaurant_photos'] is List && data['restaurant_photos'].isNotEmpty) {
              imageUrl = data['restaurant_photos'][0];
            } else if (data['restaurant_photos'] is String && data['restaurant_photos'].isNotEmpty) {
              try {
                final decoded = jsonDecode(data['restaurant_photos']);
                if (decoded is List && decoded.isNotEmpty) {
                  imageUrl = decoded[0];
                } else if (decoded is String) {
                  imageUrl = decoded;
                } else {
                  imageUrl = data['restaurant_photos'];
                }
              } catch (e) {
                imageUrl = data['restaurant_photos'];
              }
            }
          }
          
          // Clean up the image URL if it has malformed prefix
          if (imageUrl.isNotEmpty) {
            if (imageUrl.contains('https://api.bird.delivery/api/%5B%22')) {
              imageUrl = imageUrl.replaceAll('https://api.bird.delivery/api/%5B%22', '');
            }
            if (imageUrl.contains('%22%5D')) {
              imageUrl = imageUrl.replaceAll('%22%5D', '');
            }
            imageUrl = Uri.decodeFull(imageUrl);
          }
          
          final apiInfo = {
            'name': name,
            'slogan': slogan,
            'imageUrl': imageUrl,
          };
          
          debugPrint('🔄 RestaurantInfoService: Fetched from API - Name: $name, Slogan: $slogan, Image: $imageUrl');
          return apiInfo;
        }
      }
      
      debugPrint('❌ RestaurantInfoService: API call failed or returned no data');
      return {};
    } catch (e) {
      debugPrint('❌ RestaurantInfoService: Error fetching from API: $e');
      return {};
    }
  }
  
  static Future<void> _saveToSharedPreferences(Map<String, String> info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_name', info['name'] ?? '');
      await prefs.setString('restaurant_address', info['slogan'] ?? '');
      await prefs.setString('restaurant_image_url', info['imageUrl'] ?? '');
      debugPrint('🔄 RestaurantInfoService: Saved to SharedPreferences');
    } catch (e) {
      debugPrint('❌ RestaurantInfoService: Error saving to SharedPreferences: $e');
    }
  }
  
  /// Update restaurant info when profile is updated
  static void updateRestaurantInfo({
    String? name,
    String? slogan,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (name != null) {
        await prefs.setString('restaurant_name', name);
      }
      
      if (slogan != null) {
        await prefs.setString('restaurant_address', slogan);
      }
      
      if (imageUrl != null) {
        await prefs.setString('restaurant_image_url', imageUrl);
      }
      
      // Update cache immediately with new values
      if (_cachedInfo != null) {
        _cachedInfo = {
          'name': name ?? _cachedInfo!['name'] ?? '',
          'slogan': slogan ?? _cachedInfo!['slogan'] ?? '',
          'imageUrl': imageUrl ?? _cachedInfo!['imageUrl'] ?? '',
        };
        _lastCacheTime = DateTime.now();
      }
      
      debugPrint('🔄 RestaurantInfoService: Updated restaurant info and cache');
    } catch (e) {
      debugPrint('❌ RestaurantInfoService: Error updating restaurant info: $e');
    }
  }
  
  /// Force refresh restaurant info from API
  static Future<Map<String, String>> refreshRestaurantInfo() async {
    debugPrint('🔄 RestaurantInfoService: Force refreshing restaurant info');
    clearCache();
    return await getRestaurantInfo();
  }
  
  /// Clear cache (useful for logout or when data becomes stale)
  static void clearCache() {
    _cachedInfo = null;
    _lastCacheTime = null;
    debugPrint('🔄 RestaurantInfoService: Cache cleared');
  }
  
  /// Get the profile update service for listening to updates
  static ProfileUpdateService get profileUpdateService => _profileUpdateService;
} 