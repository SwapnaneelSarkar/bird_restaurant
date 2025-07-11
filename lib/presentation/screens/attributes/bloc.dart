// lib/presentation/screens/attributes/bloc.dart
import 'package:bird_restaurant/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../../services/attribute_service.dart';
import '../../../services/api_exception.dart';
import 'event.dart';
import 'state.dart';

class AttributeBloc extends Bloc<AttributeEvent, AttributeState> {
  AttributeBloc() : super(AttributeInitial()) {
    on<LoadAttributesEvent>(_onLoadAttributes);
    on<AddAttributeEvent>(_onAddAttribute);
    on<AddValueToNewAttributeEvent>(_onAddValueToNewAttribute);
    on<ClearNewAttributeValuesEvent>(_onClearNewAttributeValues);
    on<EditAttributeValuesEvent>(_onEditAttributeValues);
    on<BulkUpdateAttributeValuesEvent>(_onBulkUpdateAttributeValues);
    on<DeleteAttributeValueEvent>(_onDeleteAttributeValue);
    on<DeleteAttributeEvent>(_onDeleteAttribute);
    on<RemoveValueFromNewAttributeEvent>(_onRemoveValueFromNewAttribute);
    on<SetSelectedMenuIdEvent>(_onSetSelectedMenuId);
    on<UpdateAttributeValueEvent>(_onUpdateAttributeValue);
  }

  void _onLoadAttributes(LoadAttributesEvent event, Emitter<AttributeState> emit) async {
    emit(AttributeLoading());
    
    try {
      final response = await AttributeService.getAttributes(event.menuId);
      
      if (response.status == 'SUCCESS') {
        final attributes = response.data != null
            ? response.data!.map((attributeGroup) => attributeGroup.toAttribute()).toList()
            : <Attribute>[];
        
        emit(AttributeLoaded(
          attributes: attributes,
          selectedMenuId: event.menuId,
        ));
      } else {
        emit(AttributeError(message: response.message));
      }
    } catch (e) {
      debugPrint('Error loading attributes: $e');
      if (e is UnauthorizedException) {
        emit(const AttributeError(message: 'Please login again'));
      } else if (e is ApiException) {
        emit(AttributeError(message: e.message));
      } else {
        emit(const AttributeError(message: 'Failed to load attributes'));
      }
    }
  }

  void _onAddAttribute(AddAttributeEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Creating attribute...'));
      
      try {
        // Create the attribute group first
        final createResponse = await AttributeService.createAttribute(
          menuId: event.menuId,
          name: event.name,
          type: event.type,
          isRequired: event.isRequired,
        );
        
        if (createResponse.status == 'SUCCESS' && createResponse.data != null) {
          final attributeId = createResponse.data!.attributeId;
          
          // Add all values to the created attribute
          for (final value in event.values) {
            await AttributeService.addAttributeValue(
              menuId: event.menuId,
              attributeId: attributeId,
              name: value.name,
              priceAdjustment: value.priceAdjustment,
              isDefault: value.isDefault,
            );
          }
          
          // Clear the new attribute values after successful creation
          emit(currentState.copyWith(newAttributeValues: []));
          
          // Show success message
          emit(const AttributeCreationSuccess(message: 'Attribute created successfully!'));
          
          // Add a small delay to ensure the API has processed the changes
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Reload attributes to get the updated list
          add(LoadAttributesEvent(menuId: event.menuId));
        } else {
          emit(AttributeError(message: createResponse.message));
        }
      } catch (e) {
        debugPrint('Error creating attribute: $e');
        if (e is UnauthorizedException) {
          emit(const AttributeError(message: 'Please login again'));
        } else if (e is ApiException) {
          emit(AttributeError(message: e.message));
        } else {
          emit(const AttributeError(message: 'Failed to create attribute'));
        }
      }
    }
  }

  void _onAddValueToNewAttribute(AddValueToNewAttributeEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      try {
        final newValue = AttributeValueWithPrice(
          name: event.name,
          priceAdjustment: event.priceAdjustment,
          isDefault: event.isDefault,
        );
        
        final updatedValues = [...currentState.newAttributeValues, newValue];
        emit(currentState.copyWith(newAttributeValues: updatedValues));
      } catch (e) {
        emit(AttributeError(message: e.toString()));
      }
    }
  }

  void _onClearNewAttributeValues(ClearNewAttributeValuesEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(currentState.copyWith(newAttributeValues: const []));
    }
  }

  void _onEditAttributeValues(EditAttributeValuesEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Updating attribute values...'));
      
      try {
        // For now, we'll reload the attributes after editing
        // In a full implementation, you might want to handle individual value updates
        add(LoadAttributesEvent(menuId: event.menuId));
      } catch (e) {
        debugPrint('Error editing attribute values: $e');
        emit(const AttributeError(message: 'Failed to update attribute values'));
      }
    }
  }

  void _onDeleteAttributeValue(DeleteAttributeValueEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Deleting attribute value...'));
      
      try {
        final success = await AttributeService.deleteAttributeValue(
          menuId: event.menuId,
          attributeId: event.attributeId,
          valueId: event.valueId,
        );
        
        if (success) {
          // Reload attributes to get the updated list
          add(LoadAttributesEvent(menuId: event.menuId));
        } else {
          emit(const AttributeError(message: 'Failed to delete attribute value'));
        }
      } catch (e) {
        debugPrint('Error deleting attribute value: $e');
        if (e is UnauthorizedException) {
          emit(const AttributeError(message: 'Please login again'));
        } else if (e is ApiException) {
          emit(AttributeError(message: e.message));
        } else {
          emit(const AttributeError(message: 'Failed to delete attribute value'));
        }
      }
    }
  }

  void _onDeleteAttribute(DeleteAttributeEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Deleting attribute...'));
      
      try {
        final success = await AttributeService.deleteAttribute(
          menuId: event.menuId,
          attributeId: event.attributeId,
        );
        
        if (success) {
          // Remove the attribute from local state
          final updatedAttributes = currentState.attributes
              .where((attr) => attr.attributeId != event.attributeId)
              .toList();
          
          emit(currentState.copyWith(attributes: updatedAttributes));
        } else {
          emit(const AttributeError(message: 'Failed to delete attribute'));
        }
      } catch (e) {
        debugPrint('Error deleting attribute: $e');
        if (e is UnauthorizedException) {
          emit(const AttributeError(message: 'Please login again'));
        } else if (e is ApiException) {
          emit(AttributeError(message: e.message));
        } else {
          emit(const AttributeError(message: 'Failed to delete attribute'));
        }
      }
    }
  }

  void _onRemoveValueFromNewAttribute(RemoveValueFromNewAttributeEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      final updatedValues = currentState.newAttributeValues
          .where((value) => value.name != event.valueName)
          .toList();
      emit(currentState.copyWith(newAttributeValues: updatedValues));
    }
  }

  void _onSetSelectedMenuId(SetSelectedMenuIdEvent event, Emitter<AttributeState> emit) {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(currentState.copyWith(selectedMenuId: event.menuId));
    } else {
      emit(AttributeLoaded(
        attributes: const [],
        selectedMenuId: event.menuId,
      ));
    }
  }

  void _onBulkUpdateAttributeValues(BulkUpdateAttributeValuesEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Saving all changes...'));
      
      try {
        bool allSuccess = true;
        
        // First, delete the values that need to be deleted
        for (final valueId in event.deletedValueIds) {
          final success = await AttributeService.deleteAttributeValue(
            menuId: event.menuId,
            attributeId: event.attributeId,
            valueId: valueId,
          );
          if (!success) {
            allSuccess = false;
            break;
          }
        }
        
        // Then, update the values that need to be updated
        if (allSuccess) {
          for (final value in event.updatedValues) {
            if (value.valueId != null) {
              final success = await AttributeService.updateAttributeValue(
                menuId: event.menuId,
                attributeId: event.attributeId,
                valueId: value.valueId!,
                name: value.name,
                priceAdjustment: value.priceAdjustment,
                isDefault: value.isDefault,
              );
              if (!success) {
                allSuccess = false;
                break;
              }
            }
          }
        }
        
        if (allSuccess) {
          // Show success message
          emit(const AttributeCreationSuccess(message: 'All changes saved successfully!'));
          
          // Add a small delay to ensure the API has processed the changes
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Reload attributes to get the updated list
          add(LoadAttributesEvent(menuId: event.menuId));
        } else {
          emit(const AttributeError(message: 'Failed to save some changes'));
        }
      } catch (e) {
        debugPrint('Error bulk updating attribute values: $e');
        if (e is UnauthorizedException) {
          emit(const AttributeError(message: 'Please login again'));
        } else if (e is ApiException) {
          emit(AttributeError(message: e.message));
        } else {
          emit(const AttributeError(message: 'Failed to save changes'));
        }
      }
    }
  }

  void _onUpdateAttributeValue(UpdateAttributeValueEvent event, Emitter<AttributeState> emit) async {
    final currentState = state;
    if (currentState is AttributeLoaded) {
      emit(const AttributeOperationInProgress(operation: 'Updating attribute value...'));
      try {
        final success = await AttributeService.updateAttributeValue(
          menuId: event.menuId,
          attributeId: event.attributeId,
          valueId: event.valueId,
          name: event.name,
          priceAdjustment: event.priceAdjustment,
          isDefault: event.isDefault,
        );
        if (success) {
          add(LoadAttributesEvent(menuId: event.menuId));
        } else {
          emit(const AttributeError(message: 'Failed to update attribute value'));
        }
      } catch (e) {
        debugPrint('Error updating attribute value: $e');
        emit(const AttributeError(message: 'Failed to update attribute value'));
      }
    }
  }
}