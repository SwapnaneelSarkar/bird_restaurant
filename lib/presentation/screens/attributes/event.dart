// lib/presentation/screens/attributes/event.dart
import 'package:equatable/equatable.dart';

abstract class AttributeEvent extends Equatable {
  const AttributeEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttributesEvent extends AttributeEvent {}

class AddAttributeEvent extends AttributeEvent {
  final String name;
  final List<String> values;

  const AddAttributeEvent({
    required this.name,
    required this.values,
  });

  @override
  List<Object?> get props => [name, values];
}

class AddValueToNewAttributeEvent extends AttributeEvent {
  final String value;

  const AddValueToNewAttributeEvent({required this.value});

  @override
  List<Object?> get props => [value];
}

class ClearNewAttributeValuesEvent extends AttributeEvent {}

class ToggleAttributeActiveEvent extends AttributeEvent {
  final String attributeName;
  final bool isActive;

  const ToggleAttributeActiveEvent({
    required this.attributeName,
    required this.isActive,
  });

  @override
  List<Object?> get props => [attributeName, isActive];
}

class EditAttributeValuesEvent extends AttributeEvent {
  final String attributeName;
  final List<String> newValues;

  const EditAttributeValuesEvent({
    required this.attributeName,
    required this.newValues,
  });

  @override
  List<Object?> get props => [attributeName, newValues];
}