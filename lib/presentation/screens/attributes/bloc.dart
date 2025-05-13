// lib/presentation/screens/attributes/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class AttributeBloc extends Bloc<AttributeEvent, AttributeState> {
  AttributeBloc() : super(AttributeInitial()) {
    on<LoadAttributesEvent>(_onLoadAttributes);
    on<AddAttributeEvent>(_onAddAttribute);
    on<AddValueToNewAttributeEvent>(_onAddValueToNewAttribute);
    on<ClearNewAttributeValuesEvent>(_onClearNewAttributeValues);
    on<ToggleAttributeActiveEvent>(_onToggleAttributeActive);
    on<EditAttributeValuesEvent>(_onEditAttributeValues);
  }

  void _onLoadAttributes(LoadAttributesEvent event, Emitter<AttributeState> emit) {
    emit(AttributeLoading());
    
    try {
      // In a real app, this would be loaded from an API or local database
      final attributes = [
        Attribute(
          name: "Spiciness Levels",
          values: ["Mild", "Medium", "Hot", "Extra Hot"],
          isActive: true,
        ),
        Attribute(
          name: "Dietary Preferences",
          values: ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free"],
          isActive: true,
        ),
        Attribute(
          name: "Portion Size",
          values: ["Small", "Regular", "Large", "Family Size"],
          isActive: false,
        ),
        Attribute(
          name: "Cooking Preference",
          values: ["Rare", "Medium Rare", "Medium", "Well Done"],
          isActive: true,
        ),
      ];
      
      emit(AttributeLoaded(attributes: attributes));
    } catch (e) {
      emit(AttributeError(message: e.toString()));
    }
  }

  void _onAddAttribute(AddAttributeEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      try {
        final newAttribute = Attribute(
          name: event.name,
          values: event.values,
        );
        
        final updatedAttributes = [...currentState.attributes, newAttribute];
        
        emit(AttributeLoaded(
          attributes: updatedAttributes,
          newAttributeValues: [],
        ));
      } catch (e) {
        emit(AttributeError(message: e.toString()));
      }
    }
  }

  void _onAddValueToNewAttribute(AddValueToNewAttributeEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      try {
        final updatedValues = [...currentState.newAttributeValues, event.value];
        emit(currentState.copyWith(newAttributeValues: updatedValues));
      } catch (e) {
        emit(AttributeError(message: e.toString()));
      }
    }
  }

  void _onClearNewAttributeValues(ClearNewAttributeValuesEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(currentState.copyWith(newAttributeValues: []));
    }
  }

  void _onToggleAttributeActive(ToggleAttributeActiveEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      try {
        final updatedAttributes = currentState.attributes.map((attribute) {
          if (attribute.name == event.attributeName) {
            return attribute.copyWith(isActive: event.isActive);
          }
          return attribute;
        }).toList();
        
        emit(currentState.copyWith(attributes: updatedAttributes));
      } catch (e) {
        emit(AttributeError(message: e.toString()));
      }
    }
  }

  void _onEditAttributeValues(EditAttributeValuesEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      try {
        final updatedAttributes = currentState.attributes.map((attribute) {
          if (attribute.name == event.attributeName) {
            return attribute.copyWith(values: event.newValues);
          }
          return attribute;
        }).toList();
        
        emit(currentState.copyWith(attributes: updatedAttributes));
      } catch (e) {
        emit(AttributeError(message: e.toString()));
      }
    }
  }
}