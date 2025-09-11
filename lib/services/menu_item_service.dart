// lib/services/menu_item_service.dart

import 'dart:convert';
import 'package:bird_restaurant/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'token_service.dart';

class MenuItemService {
  static const String baseUrl = ApiConstants.baseUrl;
  
  static Future<MenuItem?> getMenuItem(String menuId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/partner/menu_item/$menuId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('MenuItemService: GET $url');
      print('MenuItemService: Response status: ${response.statusCode}');
      print('MenuItemService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        
        if (responseBody['status'] == 'SUCCESS' && responseBody['data'] != null) {
          return MenuItem.fromJson(responseBody['data']);
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to get menu item details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch menu item details');
      }
    } catch (e) {
      print('MenuItemService: Error fetching menu item details: $e');
      return null; // Return null instead of rethrowing for graceful error handling
    }
  }

  // Batch fetch multiple menu items with better error handling
  static Future<Map<String, MenuItem>> getMenuItems(List<String> menuIds) async {
    final Map<String, MenuItem> menuItems = {};
    
    if (menuIds.isEmpty) {
      print('MenuItemService: No menu IDs provided');
      return menuItems;
    }
    
    print('MenuItemService: Fetching ${menuIds.length} menu items: $menuIds');
    
    // First, try to get all menu items from restaurant menu API (more reliable)
    try {
      final restaurantMenuItems = await _getMenuItemsFromRestaurantMenu(menuIds);
      if (restaurantMenuItems.isNotEmpty) {
        print('MenuItemService: ✅ Found ${restaurantMenuItems.length} items from restaurant menu');
        return restaurantMenuItems;
      }
    } catch (e) {
      print('MenuItemService: ⚠️ Failed to get from restaurant menu: $e');
    }
    
    // Fallback to individual API calls
    print('MenuItemService: 🔄 Falling back to individual API calls');
    
    // Use Future.wait to make concurrent API calls for better performance
    final futures = menuIds.map((menuId) async {
      try {
        final menuItem = await getMenuItem(menuId);
        if (menuItem != null) {
          menuItems[menuId] = menuItem;
          print('MenuItemService: ✅ Successfully loaded item: ${menuItem.name}');
        } else {
          print('MenuItemService: ❌ Failed to load menu item with ID: $menuId');
        }
      } catch (e) {
        print('MenuItemService: ❌ Error loading menu item $menuId: $e');
      }
    });
    
    await Future.wait(futures);
    
    print('MenuItemService: 📊 Loaded ${menuItems.length} out of ${menuIds.length} menu items');
    return menuItems;
  }

  // Helper method to get menu items from restaurant menu API
  static Future<Map<String, MenuItem>> _getMenuItemsFromRestaurantMenu(List<String> menuIds) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Get partner ID from token or shared preferences
      final prefs = await SharedPreferences.getInstance();
      final partnerId = prefs.getString('user_id');
      
      if (partnerId == null) {
        throw Exception('No partner ID found');
      }

      final url = Uri.parse('$baseUrl/partner/restaurant/$partnerId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('MenuItemService: GET restaurant menu from $url');
      print('MenuItemService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        
        if (responseBody['status'] == 'SUCCESS' && responseBody['data'] != null) {
          final restaurantData = responseBody['data'];
          final menuData = restaurantData['menu'] ?? restaurantData['menu_items'] ?? [];
          
          if (menuData is List) {
            final Map<String, MenuItem> foundItems = {};
            
            for (final menuItemData in menuData) {
              final menuId = menuItemData['menu_id'] ?? menuItemData['_id'] ?? '';
              if (menuIds.contains(menuId)) {
                try {
                  // Convert restaurant menu item format to MenuItem format
                  final menuItem = MenuItem(
                    id: menuId,
                    name: menuItemData['name'] ?? 'Unknown Item',
                    description: menuItemData['description'] ?? '',
                    price: MenuItem._parsePrice(menuItemData['price']),
                    imageUrl: menuItemData['image_url'] ?? menuItemData['image'] ?? '',
                    isAvailable: MenuItem._convertToBool(menuItemData['available'] ?? menuItemData['isAvailable'] ?? '1'),
                    category: menuItemData['category'] ?? '',
                    tags: menuItemData['tags'] != null 
                        ? (menuItemData['tags'] is String 
                            ? menuItemData['tags'].split(',').map((e) => e.trim()).toList()
                            : List<String>.from(menuItemData['tags']))
                        : [],
                  );
                  foundItems[menuId] = menuItem;
                  print('MenuItemService: ✅ Found in restaurant menu: ${menuItem.name} (ID: $menuId)');
                } catch (e) {
                  print('MenuItemService: ❌ Error parsing menu item $menuId: $e');
                }
              }
            }
            
            print('MenuItemService: 📊 Found ${foundItems.length} items in restaurant menu');
            return foundItems;
          }
        }
      }
      
      throw Exception('Failed to get restaurant menu data');
    } catch (e) {
      print('MenuItemService: Error getting menu items from restaurant menu: $e');
      rethrow;
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category;
  final List<String> tags;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.category,
    required this.tags,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Item',
      description: json['description'] ?? '',
      price: _parsePrice(json['price']), // FIXED: Handle string prices
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      isAvailable: _convertToBool(json['isAvailable'] ?? json['available'] ?? '1'),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Helper method to safely convert various types to bool
  static bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0; // 0 = false, any other int = true
    if (value is String) {
      // Try parsing as int first
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue != 0;
      
      // Try parsing as bool string
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1';
    }
    return false; // Default to false for unexpected types
  }

  // FIXED: Helper method to parse price from string or number
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        return double.parse(price);
      } catch (e) {
        print('MenuItemService: Error parsing price "$price": $e');
        return 0.0;
      }
    }
    
    print('MenuItemService: Unknown price type: ${price.runtimeType}');
    return 0.0;
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  
  // FIXED: Get a display image URL with fallback
  String get displayImageUrl {
    if (imageUrl.isNotEmpty) {
      // If the imageUrl is already a complete URL, return as is
      if (imageUrl.startsWith('http')) {
        return imageUrl;
      }
      // If it's a relative path, prepend the base URL
      return '${ApiConstants.baseUrl}/$imageUrl';
    }
    // Return a placeholder image URL
    return 'https://via.placeholder.com/100x100/E17A47/FFFFFF?text=Food';
  }

  // Additional helper to check if image is available
  bool get hasImage => imageUrl.isNotEmpty;
}