// lib/models/restaurant_menu_model.dart
import '../presentation/screens/add_product/state.dart'; // Import timing schedule models

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
  final List<Product> products; // Add products field
  final String? supercategory; // Add supercategory field

  RestaurantData({
    required this.partnerId,
    required this.restaurantName,
    required this.address,
    this.description,
    required this.ownerName,
    required this.openTimings,
    required this.menuItems,
    required this.products, // Add products parameter
    this.supercategory, // Add supercategory parameter
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

    // Parse products from API response
    List<Product> products = [];
    if (json['products'] != null) {
      products = List<Product>.from(
          json['products'].map((item) => Product.fromJson(item)));
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
      products: products, // Add products
      supercategory: json['supercategory'], // Add supercategory
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
  final String? restaurantFoodTypeId;
  final String? supercategory; // Add supercategory field
  // New timing fields
  final bool timingEnabled;
  final TimingSchedule? timingSchedule;
  final String? timezone;

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
    this.restaurantFoodTypeId,
    this.supercategory, // Add supercategory parameter
    this.timingEnabled = true,
    this.timingSchedule,
    this.timezone,
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
      restaurantFoodTypeId: json['restaurant_food_type_id'],
      supercategory: json['supercategory'], // Add supercategory parsing
      // New timing fields
      timingEnabled: _convertToBool(json['timing_enabled']),
      timingSchedule: json['timing_schedule'] != null 
          ? TimingSchedule.fromJson(json['timing_schedule']) 
          : null,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
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

// Product model for non-food items
class Product {
  final String sellerProductId;
  final String productId;
  final String name;
  final String? description;
  final String brand;
  final String weight;
  final String unit;
  final String? imageUrl;
  final String price;
  final int quantity;
  final bool available;
  final SubcategoryInfo subcategory;
  final CategoryInfo category;
  final SupercategoryInfo supercategory;

  Product({
    required this.sellerProductId,
    required this.productId,
    required this.name,
    this.description,
    required this.brand,
    required this.weight,
    required this.unit,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.available,
    required this.subcategory,
    required this.category,
    required this.supercategory,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sellerProductId: json['seller_product_id'] ?? '',
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      brand: json['brand'] ?? '',
      weight: json['weight'] ?? '',
      unit: json['unit'] ?? '',
      imageUrl: json['image_url'],
      price: json['price'] ?? '0.00',
      quantity: json['quantity'] ?? 0,
      available: _convertToBool(json['available']),
      subcategory: SubcategoryInfo.fromJson(json['subcategory'] ?? {}),
      category: CategoryInfo.fromJson(json['category'] ?? {}),
      supercategory: SupercategoryInfo.fromJson(json['supercategory'] ?? {}),
    );
  }

  // Helper method to safely convert various types to bool
  static bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue != 0;
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1';
    }
    return false;
  }

  // Helper getters for display purposes
  String get displayPrice => '₹$price';
  String get displayImageUrl => imageUrl ?? '';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  String get displayWeight => '$weight $unit';
  bool get isLowStock => quantity < 5;
}

class SubcategoryInfo {
  final String name;

  SubcategoryInfo({
    required this.name,
  });

  factory SubcategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubcategoryInfo(
      name: json['name'] ?? '',
    );
  }
}

class CategoryInfo {
  final String name;

  CategoryInfo({
    required this.name,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      name: json['name'] ?? '',
    );
  }
}

class SupercategoryInfo {
  final String name;

  SupercategoryInfo({
    required this.name,
  });

  factory SupercategoryInfo.fromJson(Map<String, dynamic> json) {
    return SupercategoryInfo(
      name: json['name'] ?? '',
    );
  }
}