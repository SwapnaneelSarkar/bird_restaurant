class FoodTypeModel {
  final String restaurantFoodTypeId;
  final String name;
  final int active;

  FoodTypeModel({
    required this.restaurantFoodTypeId,
    required this.name,
    required this.active,
  });

  factory FoodTypeModel.fromJson(Map<String, dynamic> json) {
    return FoodTypeModel(
      restaurantFoodTypeId: json['restaurant_food_type_id'] ?? '',
      name: json['name'] ?? '',
      active: json['active'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_food_type_id': restaurantFoodTypeId,
      'name': name,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'FoodTypeModel(restaurantFoodTypeId: $restaurantFoodTypeId, name: $name, active: $active)';
  }
}

class FoodTypesResponse {
  final String status;
  final String message;
  final List<FoodTypeModel> data;

  FoodTypesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory FoodTypesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final foodTypes = dataList
        .map((item) => FoodTypeModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return FoodTypesResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: foodTypes,
    );
  }

  @override
  String toString() {
    return 'FoodTypesResponse(status: $status, message: $message, data: ${data.length} items)';
  }
} 