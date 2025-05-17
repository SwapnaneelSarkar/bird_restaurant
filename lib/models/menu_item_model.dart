// lib/models/menu_item_model.dart
import 'dart:io';

class MenuItemRequest {
  final String partnerId;
  final String name;
  final String description;
  final String category;
  final String price;
  final bool available;
  final File? image;
  final bool isVeg;

  MenuItemRequest({
    required this.partnerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.available = true,
    this.image,
    this.isVeg = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'partner_id': partnerId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'available': available.toString(),
      'isVeg': isVeg.toString(),
    };
  }
}

class MenuItemResponse {
  final String status;
  final String message;
  final dynamic data;

  MenuItemResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory MenuItemResponse.fromJson(Map<String, dynamic> json) {
    return MenuItemResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}