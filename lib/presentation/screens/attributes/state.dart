// lib/presentation/screens/attributes/state.dart
import 'package:equatable/equatable.dart';

class Attribute {
  final String name;
  final List<String> values;
  final bool isActive;

  Attribute({
    required this.name,
    required this.values,
    this.isActive = true,
  });

  Attribute copyWith({
    String? name,
    List<String>? values,
    bool? isActive,
  }) {
    return Attribute(
      name: name ?? this.name,
      values: values ?? this.values,
      isActive: isActive ?? this.isActive,
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
  final List<String> newAttributeValues;

  const AttributeLoaded({
    required this.attributes,
    this.newAttributeValues = const [],
  });

  @override
  List<Object?> get props => [attributes, newAttributeValues];

  AttributeLoaded copyWith({
    List<Attribute>? attributes,
    List<String>? newAttributeValues,
  }) {
    return AttributeLoaded(
      attributes: attributes ?? this.attributes,
      newAttributeValues: newAttributeValues ?? this.newAttributeValues,
    );
  }
}

class AttributeError extends AttributeState {
  final String message;

  const AttributeError({required this.message});

  @override
  List<Object?> get props => [message];
}