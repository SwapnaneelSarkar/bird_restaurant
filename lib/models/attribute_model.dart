// lib/models/attribute_model.dart
import '../presentation/screens/attributes/state.dart';
import 'package:flutter/foundation.dart';

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
    List<AttributeGroup>? attributeGroups;
    
    if (json['data'] != null) {
      final rawGroups = List<AttributeGroup>.from(
        json['data'].map((x) => AttributeGroup.fromJson(x))
      );
      
      // Filter out groups with no valid data
      final validGroups = rawGroups.where((group) => group.hasValidData).toList();
      
      // Handle duplicate attribute groups by merging them
      final Map<String, AttributeGroup> uniqueGroups = {};
      
      for (final group in validGroups) {
        if (uniqueGroups.containsKey(group.name)) {
          // Merge duplicate groups - combine their values
          final existingGroup = uniqueGroups[group.name]!;
          final mergedValues = [
            ...existingGroup.attributeValues,
            ...group.attributeValues,
          ];
          
          // Create a new group with merged values
          final mergedGroup = AttributeGroup(
            attributeId: group.attributeId, // Use the newer group's ID
            menuId: group.menuId,
            name: group.name,
            type: group.type,
            isRequired: group.isRequired,
            createdAt: group.createdAt,
            updatedAt: group.updatedAt,
            attributeValues: mergedValues,
          );
          
          uniqueGroups[group.name] = mergedGroup;
          debugPrint('🔄 Merged duplicate attribute group: ${group.name}');
        } else {
          uniqueGroups[group.name] = group;
        }
      }
      
      attributeGroups = uniqueGroups.values.toList();
      debugPrint('📊 Processed ${rawGroups.length} raw groups -> ${validGroups.length} valid groups -> ${attributeGroups.length} unique groups');
    }
    
    return AttributeResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: attributeGroups,
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
    debugPrint('Parsing AttributeGroup from JSON: $json');
    final group = AttributeGroup(
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
    debugPrint('Parsed AttributeGroup: name="${group.name}", type="${group.type}", valuesCount=${group.attributeValues.length}');
    return group;
  }

  // Convert to local Attribute model for UI
  Attribute toAttribute() {
    debugPrint('Converting AttributeGroup to Attribute:');
    debugPrint('  Name: $name');
    debugPrint('  Type: $type');
    debugPrint('  AttributeValues count: ${attributeValues.length}');
    
    // More robust filtering - check for null, empty, and whitespace-only names
    final validValues = <String>[];
    for (final value in attributeValues) {
      debugPrint('  Processing value: name="${value.name}", valueId="${value.valueId}"');
      if (value.name != null && value.name!.trim().isNotEmpty) {
        validValues.add(value.name!.trim());
        debugPrint('    -> Added: "${value.name!.trim()}"');
      } else {
        debugPrint('    -> Skipped: name is null or empty');
      }
    }
    
    debugPrint('  Final valid values count: ${validValues.length}');
    debugPrint('  Final valid values: $validValues');
    
    return Attribute(
      name: name,
      values: validValues,
      isActive: true,
      attributeId: attributeId,
      type: type,
    );
  }
  
  // Check if this attribute group has valid data
  bool get hasValidData {
    // Check if we have at least one valid attribute value
    return attributeValues.any((value) => 
      value.name != null && 
      value.name!.trim().isNotEmpty
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
    debugPrint('Parsing AttributeValue from JSON: $json');
    
    // Handle potential type conversion issues
    final name = json['name'];
    final valueId = json['value_id']?.toString();
    final isDefault = json['is_default'];
    final priceAdjustment = json['price_adjustment'];
    
    // Convert name to string, but preserve null
    String? nameString;
    if (name != null) {
      final nameStr = name.toString();
      // Only use the string if it's not the literal "null" string and not empty
      if (nameStr != 'null' && nameStr.trim().isNotEmpty) {
        nameString = nameStr.trim();
      }
    }
    
    // Convert isDefault to int, handling both string and int inputs
    int? isDefaultInt;
    if (isDefault != null) {
      if (isDefault is int) {
        isDefaultInt = isDefault;
      } else if (isDefault is String) {
        isDefaultInt = int.tryParse(isDefault);
      } else if (isDefault is bool) {
        isDefaultInt = isDefault ? 1 : 0;
      }
    }
    
    // Convert priceAdjustment to int, handling both string and int inputs
    int? priceAdjustmentInt;
    if (priceAdjustment != null) {
      if (priceAdjustment is int) {
        priceAdjustmentInt = priceAdjustment;
      } else if (priceAdjustment is String) {
        priceAdjustmentInt = int.tryParse(priceAdjustment);
      }
    }
    
    final value = AttributeValue(
      name: nameString,
      valueId: valueId,
      isDefault: isDefaultInt,
      priceAdjustment: priceAdjustmentInt,
    );
    debugPrint('Parsed AttributeValue: name="$nameString", valueId="$valueId", isDefault=$isDefaultInt, priceAdjustment=$priceAdjustmentInt');
    return value;
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