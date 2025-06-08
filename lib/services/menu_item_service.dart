// lib/services/menu_item_service.dart

import 'dart:convert';
import 'package:bird_restaurant/constants/api_constants.dart';
import 'package:http/http.dart' as http;
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
      isAvailable: json['isAvailable'] ?? json['available'] ?? true,
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
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