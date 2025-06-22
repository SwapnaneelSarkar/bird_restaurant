// lib/models/attribute_model.dart
import '../presentation/screens/attributes/state.dart';

class AttributeResponse {
  final String status;
  final String message;
  final List<AttributeGroup>? data;

  AttributeResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AttributeResponse.fromJson(Map<String, dynamic> json) {
    return AttributeResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? List<AttributeGroup>.from(
              json['data'].map((x) => AttributeGroup.fromJson(x))
            )
          : null,
    );
  }
}

class AttributeGroup {
  final String attributeId;
  final String menuId;
  final String name;
  final String type;
  final int isRequired;
  final String createdAt;
  final String updatedAt;
  final List<AttributeValue> attributeValues;

  AttributeGroup({
    required this.attributeId,
    required this.menuId,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.createdAt,
    required this.updatedAt,
    required this.attributeValues,
  });

  factory AttributeGroup.fromJson(Map<String, dynamic> json) {
    return AttributeGroup(
      attributeId: json['attribute_id'] ?? '',
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'radio',
      isRequired: json['is_required'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      attributeValues: json['attribute_values'] != null
          ? List<AttributeValue>.from(
              json['attribute_values'].map((x) => AttributeValue.fromJson(x))
            )
          : [],
    );
  }

  // Convert to local Attribute model for UI
  Attribute toAttribute() {
    return Attribute(
      name: name,
      values: attributeValues
          .where((v) => v.name != null && v.name!.isNotEmpty)
          .map((v) => v.name!)
          .toList(),
      isActive: true,
      attributeId: attributeId,
      type: type,
    );
  }
}

class AttributeValue {
  final String? name;
  final String? valueId;
  final int? isDefault;
  final int? priceAdjustment;

  AttributeValue({
    this.name,
    this.valueId,
    this.isDefault,
    this.priceAdjustment,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      name: json['name'],
      valueId: json['value_id'],
      isDefault: json['is_default'],
      priceAdjustment: json['price_adjustment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price_adjustment': priceAdjustment ?? 0,
      'is_default': isDefault ?? 0,
    };
  }

  AttributeValueWithPrice toValueWithPrice() {
    return AttributeValueWithPrice(
      name: name ?? '',
      priceAdjustment: priceAdjustment ?? 0,
      isDefault: (isDefault ?? 0) == 1,
      valueId: valueId,
    );
  }
}

// Request models for creating attributes
class CreateAttributeRequest {
  final String name;
  final String type;
  final bool isRequired;

  CreateAttributeRequest({
    required this.name,
    required this.type,
    required this.isRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'is_required': isRequired,
    };
  }
}

class CreateAttributeValueRequest {
  final String name;
  final int priceAdjustment;
  final bool isDefault;

  CreateAttributeValueRequest({
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price_adjustment': priceAdjustment,
      'is_default': isDefault,
    };
  }
}

class CreateAttributeResponse {
  final String status;
  final String message;
  final AttributeCreatedData? data;

  CreateAttributeResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CreateAttributeResponse.fromJson(Map<String, dynamic> json) {
    return CreateAttributeResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? AttributeCreatedData.fromJson(json['data'])
          : null,
    );
  }
}

class AttributeCreatedData {
  final String attributeId;
  final String menuId;
  final String name;
  final String type;
  final bool isRequired;

  AttributeCreatedData({
    required this.attributeId,
    required this.menuId,
    required this.name,
    required this.type,
    required this.isRequired,
  });

  factory AttributeCreatedData.fromJson(Map<String, dynamic> json) {
    return AttributeCreatedData(
      attributeId: json['attribute_id'] ?? '',
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      isRequired: json['is_required'] ?? false,
    );
  }
}

class CreateAttributeValueResponse {
  final String status;
  final String message;
  final AttributeValueCreatedData? data;

  CreateAttributeValueResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CreateAttributeValueResponse.fromJson(Map<String, dynamic> json) {
    return CreateAttributeValueResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? AttributeValueCreatedData.fromJson(json['data'])
          : null,
    );
  }
}

class AttributeValueCreatedData {
  final String valueId;
  final String attributeId;
  final String name;
  final int priceAdjustment;
  final bool isDefault;

  AttributeValueCreatedData({
    required this.valueId,
    required this.attributeId,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });

  factory AttributeValueCreatedData.fromJson(Map<String, dynamic> json) {
    return AttributeValueCreatedData(
      valueId: json['value_id'] ?? '',
      attributeId: json['attribute_id'] ?? '',
      name: json['name'] ?? '',
      priceAdjustment: json['price_adjustment'] ?? 0,
      isDefault: json['is_default'] ?? false,
    );
  }
}