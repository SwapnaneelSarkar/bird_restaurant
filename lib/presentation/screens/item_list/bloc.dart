// lib/presentation/screens/menu_items/menu_items_bloc.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../models/restaurant_menu_model.dart';
import '../../../models/update_menu_item_model.dart';
import 'event.dart';
import 'state.dart';

class MenuItemsBloc extends Bloc<MenuItemsEvent, MenuItemsState> {
  MenuItemsBloc() : super(MenuItemsInitial()) {
    on<LoadMenuItemsEvent>(_onLoadMenuItems);
    on<ToggleItemAvailabilityEvent>(_onToggleItemAvailability);
    on<DeleteMenuItemEvent>(_onDeleteMenuItem);
    on<EditMenuItemEvent>(_onEditMenuItem);
    on<AddNewMenuItemEvent>(_onAddNewMenuItem);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItemsEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    emit(MenuItemsLoading());
    try {
      final response = await _fetchRestaurantMenu();
      if (response.status == 'SUCCESS' && response.data != null) {
        emit(MenuItemsLoaded(
          menuItems: response.data!.menuItems,
          restaurantData: response.data!,
        ));
      } else {
        emit(MenuItemsError(response.message));
      }
    } catch (e) {
      emit(MenuItemsError('Failed to load menu items: ${e.toString()}'));
    }
  }

  // lib/presentation/screens/menu_items/menu_items_bloc.dart

// Update this method
Future<void> _onToggleItemAvailability(
  ToggleItemAvailabilityEvent event,
  Emitter<MenuItemsState> emit,
) async {
  if (state is MenuItemsLoaded) {
    final currentState = state as MenuItemsLoaded;
    
    // Emit a state indicating that availability is being updated
    emit(ItemAvailabilityUpdating(event.menuItem));
    
    try {
      // Call the API to update availability - pass the complete menu item
      final response = await _updateMenuItemAvailability(
        event.menuItem,
        event.isAvailable
      );
      
      if (response.status == 'SUCCESS') {
        // Update the local state with the new availability
        final updatedItems = currentState.menuItems.map((item) {
          if (item.menuId == event.menuItem.menuId) {
            return MenuItem(
              menuId: item.menuId,
              name: item.name,
              price: item.price,
              available: event.isAvailable,
              imageUrl: item.imageUrl,
              description: item.description,
              category: item.category,
              isVeg: item.isVeg,
            );
          }
          return item;
        }).toList();
        
        emit(MenuItemsLoaded(
          menuItems: updatedItems,
          restaurantData: currentState.restaurantData,
        ));
      } else {
        // Show error but don't change the UI state
        emit(MenuItemsError(response.message));
        emit(currentState); // Revert to previous state
      }
    } catch (e) {
      emit(MenuItemsError('Failed to update item availability: ${e.toString()}'));
      // Revert back to the previous state after the error
      emit(currentState);
    }
  }
}

// Update this method to take the complete menu item
Future<UpdateMenuItemResponse> _updateMenuItemAvailability(MenuItem menuItem, bool isAvailable) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication information not found. Please login again.');
    }
    
    final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item/${menuItem.menuId}');
    
    debugPrint('Updating menu item availability: $url');
    
    // Include all required fields from the menu item
    final requestBody = jsonEncode({
      'name': menuItem.name,
      'price': menuItem.price,
      'available': isAvailable.toString(),
      'description': menuItem.description,
      'category': menuItem.category,
      'isVeg': menuItem.isVeg.toString(),
    });
    
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );
    
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UpdateMenuItemResponse.fromJson(data);
    } else {
      try {
        final errorData = json.decode(response.body);
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: errorData['message'] ?? 'Failed to update menu item',
        );
      } catch (e) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Failed to update menu item. Status: ${response.statusCode}',
        );
      }
    }
  } catch (e) {
    debugPrint('Error updating menu item: $e');
    return UpdateMenuItemResponse(
      status: 'ERROR',
      message: 'Error: ${e.toString()}',
    );
  }
}
  Future<void> _onDeleteMenuItem(
    DeleteMenuItemEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      
      emit(ItemDeleting(event.menuId));
      
      try {
        // API call would go here
        // Since we're not implementing the API yet, just update locally
        
        final updatedItems = currentState.menuItems
            .where((item) => item.menuId != event.menuId)
            .toList();
        
        emit(MenuItemsLoaded(
          menuItems: updatedItems,
          restaurantData: currentState.restaurantData,
        ));
      } catch (e) {
        emit(MenuItemsError('Failed to delete menu item: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  void _onEditMenuItem(
    EditMenuItemEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    emit(NavigateToEditItem(event.menuItem));
  }

  void _onAddNewMenuItem(
    AddNewMenuItemEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    emit(NavigateToAddItem());
  }

  Future<RestaurantMenuResponse> _fetchRestaurantMenu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/restaurant/$partnerId');
      
      debugPrint('Fetching menu from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RestaurantMenuResponse.fromJson(data);
      } else {
        try {
          final errorData = json.decode(response.body);
          return RestaurantMenuResponse(
            status: 'ERROR',
            message: errorData['message'] ?? 'Failed to fetch menu items',
          );
        } catch (e) {
          return RestaurantMenuResponse(
            status: 'ERROR',
            message: 'Failed to fetch menu items. Status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching menu items: $e');
      return RestaurantMenuResponse(
        status: 'ERROR',
        message: 'Error: ${e.toString()}',
      );
    }
  }
}