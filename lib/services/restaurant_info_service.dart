import 'package:shared_preferences/shared_preferences.dart';

class RestaurantInfoService {
  static Future<Map<String, String>> getRestaurantInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('restaurant_name') ?? '',
      'slogan': prefs.getString('restaurant_address') ?? '',
      'imageUrl': prefs.getString('restaurant_image_url') ?? '',
    };
  }
} 