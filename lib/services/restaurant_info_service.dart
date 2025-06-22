import 'package:shared_preferences/shared_preferences.dart';
import 'profile_update_service.dart';
import 'package:flutter/foundation.dart';

class RestaurantInfoService {
  static final ProfileUpdateService _profileUpdateService = ProfileUpdateService();
  
  static Future<Map<String, String>> getRestaurantInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('restaurant_name') ?? '',
      'slogan': prefs.getString('restaurant_address') ?? '',
      'imageUrl': prefs.getString('restaurant_image_url') ?? '',
    };
  }
  
  /// Update restaurant info when profile is updated
  static void updateRestaurantInfo({
    String? name,
    String? slogan,
    String? imageUrl,
  }) async {
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
    
    debugPrint('🔄 RestaurantInfoService: Updated restaurant info');
  }
  
  /// Get the profile update service for listening to updates
  static ProfileUpdateService get profileUpdateService => _profileUpdateService;
} 