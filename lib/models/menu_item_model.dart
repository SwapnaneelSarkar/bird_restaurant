

// lib/models/menu_item_model.dart
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
      status: json['status'],
      message: json['message'],
      data: json['data'],
    );
  }
}

