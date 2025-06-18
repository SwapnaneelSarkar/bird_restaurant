// lib/presentation/screens/attributes/state.dart
import 'package:equatable/equatable.dart';

class Attribute {
  final String name;
  final List<String> values;
  final bool isActive;
  final String? attributeId; // Added for API integration
  final String? type; // Added for API integration

  Attribute({
    required this.name,
    required this.values,
    this.isActive = true,
    this.attributeId,
    this.type = 'radio',
  });

  Attribute copyWith({
    String? name,
    List<String>? values,
    bool? isActive,
    String? attributeId,
    String? type,
  }) {
    return Attribute(
      name: name ?? this.name,
      values: values ?? this.values,
      isActive: isActive ?? this.isActive,
      attributeId: attributeId ?? this.attributeId,
      type: type ?? this.type,
    );
  }
}

// New class to hold attribute value with additional properties
class AttributeValueWithPrice {
  final String name;
  final int priceAdjustment;
  final bool isDefault;
  final String? valueId; // For API operations

  AttributeValueWithPrice({
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
    this.valueId,
  });

  AttributeValueWithPrice copyWith({
    String? name,
    int? priceAdjustment,
    bool? isDefault,
    String? valueId,
  }) {
    return AttributeValueWithPrice(
      name: name ?? this.name,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      isDefault: isDefault ?? this.isDefault,
      valueId: valueId ?? this.valueId,
    );
  }
}

abstract class AttributeState extends Equatable {
  const AttributeState();

  @override
  List<Object?> get props => [];
}

class AttributeInitial extends AttributeState {}

class AttributeLoading extends AttributeState {}

class AttributeLoaded extends AttributeState {
  final List<Attribute> attributes;
  final List<AttributeValueWithPrice> newAttributeValues; // Updated type
  final String? selectedMenuId; // Added for API integration

  const AttributeLoaded({
    required this.attributes,
    this.newAttributeValues = const [],
    this.selectedMenuId,
  });

  @override
  List<Object?> get props => [attributes, newAttributeValues, selectedMenuId];

  AttributeLoaded copyWith({
    List<Attribute>? attributes,
    List<AttributeValueWithPrice>? newAttributeValues,
    String? selectedMenuId,
  }) {
    return AttributeLoaded(
      attributes: attributes ?? this.attributes,
      newAttributeValues: newAttributeValues ?? this.newAttributeValues,
      selectedMenuId: selectedMenuId ?? this.selectedMenuId,
    );
  }
}

class AttributeError extends AttributeState {
  final String message;

  const AttributeError({required this.message});

  @override
  List<Object?> get props => [message];
}

// New state for creation success
class AttributeCreationSuccess extends AttributeState {
  final String message;

  const AttributeCreationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// New state for ongoing operations
class AttributeOperationInProgress extends AttributeState {
  final String operation; // e.g., "Creating attribute", "Adding value", etc.

  const AttributeOperationInProgress({required this.operation});

  @override
  List<Object?> get props => [operation];
}