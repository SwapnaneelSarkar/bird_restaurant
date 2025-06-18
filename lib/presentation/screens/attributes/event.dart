// lib/presentation/screens/attributes/event.dart
import 'package:equatable/equatable.dart';
import 'state.dart';

abstract class AttributeEvent extends Equatable {
  const AttributeEvent();

  @override
  List<Object?> get props => [];
}

// Load attributes for a specific menu item
class LoadAttributesEvent extends AttributeEvent {
  final String menuId;

  const LoadAttributesEvent({required this.menuId});

  @override
  List<Object?> get props => [menuId];
}

// Add a new attribute
class AddAttributeEvent extends AttributeEvent {
  final String menuId;
  final String name;
  final String type;
  final bool isRequired;
  final List<AttributeValueWithPrice> values;

  const AddAttributeEvent({
    required this.menuId,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.values,
  });

  @override
  List<Object?> get props => [menuId, name, type, isRequired, values];
}

// Add value to new attribute being created
class AddValueToNewAttributeEvent extends AttributeEvent {
  final String name;
  final int priceAdjustment;
  final bool isDefault;

  const AddValueToNewAttributeEvent({
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [name, priceAdjustment, isDefault];
}

// Clear new attribute values
class ClearNewAttributeValuesEvent extends AttributeEvent {}

// Toggle attribute active status
class ToggleAttributeActiveEvent extends AttributeEvent {
  final String menuId;
  final String attributeId;
  final bool isActive;

  const ToggleAttributeActiveEvent({
    required this.menuId,
    required this.attributeId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [menuId, attributeId, isActive];
}

// Edit attribute values
class EditAttributeValuesEvent extends AttributeEvent {
  final String menuId;
  final String attributeId;
  final List<AttributeValueWithPrice> newValues;

  const EditAttributeValuesEvent({
    required this.menuId,
    required this.attributeId,
    required this.newValues,
  });

  @override
  List<Object?> get props => [menuId, attributeId, newValues];
}

// Delete attribute value
class DeleteAttributeValueEvent extends AttributeEvent {
  final String menuId;
  final String attributeId;
  final String valueId;

  const DeleteAttributeValueEvent({
    required this.menuId,
    required this.attributeId,
    required this.valueId,
  });

  @override
  List<Object?> get props => [menuId, attributeId, valueId];
}

// Delete entire attribute
class DeleteAttributeEvent extends AttributeEvent {
  final String menuId;
  final String attributeId;

  const DeleteAttributeEvent({
    required this.menuId,
    required this.attributeId,
  });

  @override
  List<Object?> get props => [menuId, attributeId];
}

// Remove value from new attribute being created (local operation)
class RemoveValueFromNewAttributeEvent extends AttributeEvent {
  final String valueName;

  const RemoveValueFromNewAttributeEvent({required this.valueName});

  @override
  List<Object?> get props => [valueName];
}

// Set selected menu ID
class SetSelectedMenuIdEvent extends AttributeEvent {
  final String menuId;

  const SetSelectedMenuIdEvent({required this.menuId});

  @override
  List<Object?> get props => [menuId];
}