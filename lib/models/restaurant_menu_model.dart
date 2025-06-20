// lib/models/restaurant_menu_model.dart
class RestaurantMenuResponse {
  final String status;
  final String message;
  final RestaurantData? data;

  RestaurantMenuResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory RestaurantMenuResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? RestaurantData.fromJson(json['data']) : null,
    );
  }
}

class RestaurantData {
  final String partnerId;
  final String restaurantName;
  final String address;
  final String? description;
  final String ownerName;
  final String openTimings;
  final List<MenuItem> menuItems;

  RestaurantData({
    required this.partnerId,
    required this.restaurantName,
    required this.address,
    this.description,
    required this.ownerName,
    required this.openTimings,
    required this.menuItems,
  });

  factory RestaurantData.fromJson(Map<String, dynamic> json) {
    List<MenuItem> menuItems = [];
    
    // ✅ FIXED: Changed from 'menu_items' to 'menu' to match your API response
    if (json['menu'] != null) {
      menuItems = List<MenuItem>.from(
          json['menu'].map((item) => MenuItem.fromJson(item)));
    }
    // Fallback for old API responses that might still use 'menu_items'
    else if (json['menu_items'] != null) {
      menuItems = List<MenuItem>.from(
          json['menu_items'].map((item) => MenuItem.fromJson(item)));
    }

    return RestaurantData(
      partnerId: json['partner_id'] ?? '',
      restaurantName: json['restaurant_name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'],
      ownerName: json['owner_name'] ?? '',
      // ✅ FIXED: Handle both 'operational_hours' and 'open_timings'
      openTimings: json['operational_hours']?.toString() ?? json['open_timings'] ?? '{}',
      menuItems: menuItems,
    );
  }
}

class MenuItem {
  final String menuId;
  final String name;
  final String price;
  final bool available;
  final String? imageUrl;
  final String description;
  final String category;
  final bool isVeg;
  final bool isTaxIncluded;
  final bool isCancellable;
  final String? tags;

  MenuItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.available,
    this.imageUrl,
    required this.description,
    required this.category,
    required this.isVeg,
    required this.isTaxIncluded,
    required this.isCancellable,
    this.tags,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      
      // ✅ FIXED: Safe conversion from int/dynamic to bool
      available: _convertToBool(json['available']),
      
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      
      // ✅ FIXED: Safe conversion from int/dynamic to bool
      isVeg: _convertToBool(json['isVeg']),
      
      // ✅ NEW: Handle additional fields from API response
      isTaxIncluded: _convertToBool(json['isTaxIncluded']),
      isCancellable: _convertToBool(json['isCancellable']),
      tags: json['tags']?.toString(),
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

  // ✅ Helper getters for display purposes
  String get displayPrice => '₹$price';
  String get displayImageUrl => imageUrl ?? '';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Helper for display purposes
  static String formatPrice(String price, String currencySymbol) => '$currencySymbol$price';
}