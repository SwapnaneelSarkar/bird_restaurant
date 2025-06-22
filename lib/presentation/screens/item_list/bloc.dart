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
  // Cache for menu items data
  RestaurantData? _cachedRestaurantData;
  
  MenuItemsBloc() : super(MenuItemsInitial()) {
    on<LoadMenuItemsEvent>(_onLoadMenuItems);
    on<RefreshMenuItemsEvent>(_onRefreshMenuItems);
    on<ToggleItemAvailabilityEvent>(_onToggleItemAvailability);
    on<DeleteMenuItemEvent>(_onDeleteMenuItem);
    on<EditMenuItemEvent>(_onEditMenuItem);
    on<AddNewMenuItemEvent>(_onAddNewMenuItem);
    on<FilterMenuItemsEvent>(_onFilterMenuItems);
    on<SearchMenuItemsEvent>(_onSearchMenuItems);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItemsEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    // If we're already in a loaded state, don't show loading indicator
    if (state is! MenuItemsLoaded) {
      emit(MenuItemsLoading());
    }
    
    try {
      // If we have cached data and force refresh is not requested, use the cache
      if (_cachedRestaurantData != null && !event.forceRefresh) {
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          restaurantData: _cachedRestaurantData!,
        ));
        return;
      }
      
      final response = await _fetchRestaurantMenu();
      if (response.status == 'SUCCESS' && response.data != null) {
        // Cache the data
        _cachedRestaurantData = response.data!;
        
        emit(MenuItemsLoaded(
          menuItems: response.data!.menuItems,
          restaurantData: response.data!,
        ));
      } else {
        // Only emit error if there is no cached data
        if (_cachedRestaurantData != null) {
          emit(MenuItemsLoaded(
            menuItems: _cachedRestaurantData!.menuItems,
            restaurantData: _cachedRestaurantData!,
          ));
          // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
        } else {
          emit(MenuItemsError(response.message));
        }
      }
    } catch (e) {
      // Only emit error if there is no cached data
      if (_cachedRestaurantData != null) {
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          restaurantData: _cachedRestaurantData!,
        ));
        // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
      } else {
        emit(MenuItemsError('Failed to load menu items: ${e.toString()}'));
      }
    }
  }
  
  Future<void> _onRefreshMenuItems(
    RefreshMenuItemsEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    try {
      final response = await _fetchRestaurantMenu();
      if (response.status == 'SUCCESS' && response.data != null) {
        // Cache the data
        _cachedRestaurantData = response.data!;
        
        emit(MenuItemsLoaded(
          menuItems: response.data!.menuItems,
          restaurantData: response.data!,
        ));
      } else {
        // Only emit error if there is no cached data
        if (_cachedRestaurantData != null) {
          emit(MenuItemsLoaded(
            menuItems: _cachedRestaurantData!.menuItems,
            restaurantData: _cachedRestaurantData!,
          ));
          // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
        } else {
          emit(MenuItemsError(response.message));
        }
      }
    } catch (e) {
      // Only emit error if there is no cached data
      if (_cachedRestaurantData != null) {
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          restaurantData: _cachedRestaurantData!,
        ));
        // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
      } else {
        emit(MenuItemsError('Failed to refresh menu items: ${e.toString()}'));
      }
    }
  }

  Future<void> _onToggleItemAvailability(
    ToggleItemAvailabilityEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      
      // OPTIMISTIC UPDATE: Immediately update the UI state
      final updatedItems = currentState.menuItems.map((item) {
        if (item.menuId == event.menuItem.menuId) {
          return MenuItem(
            menuId: item.menuId,
            name: item.name,
            price: item.price,
            available: event.isAvailable, // Update immediately
            imageUrl: item.imageUrl,
            description: item.description,
            category: item.category,
            isVeg: item.isVeg,
            isTaxIncluded: item.isTaxIncluded,
            isCancellable: item.isCancellable,
            tags: item.tags,
          );
        }
        return item;
      }).toList();
      
      // Emit the updated state immediately for smooth UI
      emit(MenuItemsLoaded(
        menuItems: updatedItems,
        restaurantData: currentState.restaurantData,
        isFiltered: currentState.isFiltered,
        filterType: currentState.filterType,
        searchQuery: currentState.searchQuery,
      ));
      
      // Now make the API call in the background
      try {
        final response = await _updateMenuItemAvailability(
          event.menuItem,
          event.isAvailable
        );
        
        if (response.status != 'SUCCESS') {
          // If API call failed, revert the optimistic update
          final revertedItems = currentState.menuItems.map((item) {
            if (item.menuId == event.menuItem.menuId) {
              return MenuItem(
                menuId: item.menuId,
                name: item.name,
                price: item.price,
                available: !event.isAvailable, // Revert to original state
                imageUrl: item.imageUrl,
                description: item.description,
                category: item.category,
                isVeg: item.isVeg,
                isTaxIncluded: item.isTaxIncluded,
                isCancellable: item.isCancellable,
                tags: item.tags,
              );
            }
            return item;
          }).toList();
          
          emit(MenuItemsLoaded(
            menuItems: revertedItems,
            restaurantData: currentState.restaurantData,
            isFiltered: currentState.isFiltered,
            filterType: currentState.filterType,
            searchQuery: currentState.searchQuery,
          ));
          
          // Optionally: handle error notification elsewhere (e.g., Snackbar in UI)
          debugPrint('Failed to update availability: ${response.message}');
        } else {
          // API call successful, update cached data
          if (_cachedRestaurantData != null) {
            _cachedRestaurantData = null;
          }
          debugPrint('Successfully updated availability to: ${event.isAvailable}');
        }
      } catch (e) {
        // If API call failed, revert the optimistic update
        final revertedItems = currentState.menuItems.map((item) {
          if (item.menuId == event.menuItem.menuId) {
            return MenuItem(
              menuId: item.menuId,
              name: item.name,
              price: item.price,
              available: !event.isAvailable, // Revert to original state
              imageUrl: item.imageUrl,
              description: item.description,
              category: item.category,
              isVeg: item.isVeg,
              isTaxIncluded: item.isTaxIncluded,
              isCancellable: item.isCancellable,
              tags: item.tags,
            );
          }
          return item;
        }).toList();
        
        emit(MenuItemsLoaded(
          menuItems: revertedItems,
          restaurantData: currentState.restaurantData,
          isFiltered: currentState.isFiltered,
          filterType: currentState.filterType,
          searchQuery: currentState.searchQuery,
        ));
        
        // Optionally: handle error notification elsewhere (e.g., Snackbar in UI)
        debugPrint('Error updating availability: $e');
      }
    }
  }

  Future<UpdateMenuItemResponse> _updateMenuItemAvailability(MenuItem menuItem, bool isAvailable) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item/${menuItem.menuId}');
      
      debugPrint('Updating menu item availability: $url');
      
      // ✅ FIXED: Include all required fields from the menu item including new ones
      final requestBody = jsonEncode({
        'name': menuItem.name,
        'price': menuItem.price,
        'available': isAvailable.toString(),
        'description': menuItem.description,
        'category': menuItem.category,
        'isVeg': menuItem.isVeg.toString(),
        // ✅ NEW: Include the new fields in the API request
        'isTaxIncluded': menuItem.isTaxIncluded.toString(),
        'isCancellable': menuItem.isCancellable.toString(),
        if (menuItem.tags != null) 'tags': menuItem.tags,
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
        // Call the API to delete the menu item
        final response = await _deleteMenuItem(event.menuId);
        
        if (response.status == 'SUCCESS') {
          // Update the local state after successful deletion
          final updatedItems = currentState.menuItems
              .where((item) => item.menuId != event.menuId)
              .toList();
          
          // Invalidate the cache after a delete operation
          _cachedRestaurantData = null;
          
          emit(MenuItemsLoaded(
            menuItems: updatedItems,
            restaurantData: currentState.restaurantData,
            isFiltered: currentState.isFiltered,
            filterType: currentState.filterType,
            searchQuery: currentState.searchQuery,
          ));
        } else {
          // Show error message but maintain current state
          emit(MenuItemsError(response.message));
          emit(currentState);
        }
      } catch (e) {
        emit(MenuItemsError('Failed to delete menu item: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  // Add this new method to make the API call for menu item deletion
  Future<UpdateMenuItemResponse> _deleteMenuItem(String menuId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/admin/deleteMenuItem');
      
      debugPrint('Deleting menu item: $url with menu_id: $menuId');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'menu_id': menuId,
        }),
      );
      
      debugPrint('Delete response status: ${response.statusCode}');
      debugPrint('Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateMenuItemResponse.fromJson(data);
      } else {
        try {
          final errorData = json.decode(response.body);
          return UpdateMenuItemResponse(
            status: 'ERROR',
            message: errorData['message'] ?? 'Failed to delete menu item',
          );
        } catch (e) {
          return UpdateMenuItemResponse(
            status: 'ERROR',
            message: 'Failed to delete menu item. Status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      return UpdateMenuItemResponse(
        status: 'ERROR',
        message: 'Error: ${e.toString()}',
      );
    }
  }
  
  void _onEditMenuItem(
    EditMenuItemEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      emit(NavigateToEditItem(event.menuItem));
      // Immediately return to the loaded state to prevent errors when coming back
      emit(currentState);
    }
  }

  void _onAddNewMenuItem(
    AddNewMenuItemEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      emit(NavigateToAddItem());
      // Immediately return to the loaded state to prevent errors when coming back
      emit(currentState);
    } else {
      emit(NavigateToAddItem());
    }
  }
  
  void _onFilterMenuItems(
    FilterMenuItemsEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      List<MenuItem> filteredItems = List.from(currentState.menuItems);

      switch (event.filterType) {
        case FilterType.priceLowToHigh:
          filteredItems.sort((a, b) => (a.price).compareTo(b.price));
          break;
        case FilterType.priceHighToLow:
          filteredItems.sort((a, b) => (b.price).compareTo(a.price));
          break;
        case FilterType.nameAZ:
          filteredItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case FilterType.nameZA:
          filteredItems.sort((a, b) => b.name.compareTo(a.name));
          break;
      }

      emit(MenuItemsLoaded(
        menuItems: filteredItems,
        restaurantData: currentState.restaurantData,
        isFiltered: true,
        filterType: event.filterType,
      ));
    }
  }

  void _onSearchMenuItems(
    SearchMenuItemsEvent event,
    Emitter<MenuItemsState> emit,
  ) {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        // If query is empty, return all items
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData?.menuItems ?? currentState.restaurantData.menuItems,
          restaurantData: currentState.restaurantData,
          isFiltered: false,
        ));
      } else {
        // Filter items based on the search query
        final filteredItems = (_cachedRestaurantData?.menuItems ?? currentState.restaurantData.menuItems)
            .where((item) =>
                item.name.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query))
            .toList();

        emit(MenuItemsLoaded(
          menuItems: filteredItems,
          restaurantData: currentState.restaurantData,
          isFiltered: true,
          searchQuery: query,
        ));
      }
    }
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