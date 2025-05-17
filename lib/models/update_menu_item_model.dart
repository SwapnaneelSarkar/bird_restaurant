// lib/models/update_menu_item_model.dart
class UpdateMenuItemRequest {
  final String? name;
  final String? price;
  final bool? available;
  final String? description;
  final String? category;
  final bool? isVeg;

  UpdateMenuItemRequest({
    this.name,
    this.price,
    this.available,
    this.description,
    this.category,
    this.isVeg,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (available != null) data['available'] = available.toString();
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (isVeg != null) data['isVeg'] = isVeg.toString();
    
    return data;
  }
}

class UpdateMenuItemResponse {
  final String status;
  final String message;
  final dynamic data;

  UpdateMenuItemResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory UpdateMenuItemResponse.fromJson(Map<String, dynamic> json) {
    return UpdateMenuItemResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}