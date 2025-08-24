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
    on<ToggleVegFilterEvent>(_onToggleVegFilter);
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
        final isFoodSupercategory = _isFoodSupercategory(_cachedRestaurantData!);
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          products: _cachedRestaurantData!.products,
          restaurantData: _cachedRestaurantData!,
          showVegOnly: false,
          showNonVegOnly: false,
          isFoodSupercategory: isFoodSupercategory,
        ));
        return;
      }
      
      final response = await _fetchRestaurantMenu();
      if (response.status == 'SUCCESS' && response.data != null) {
        // Cache the data
        _cachedRestaurantData = response.data!;
        
        final isFoodSupercategory = _isFoodSupercategory(response.data!);
        emit(MenuItemsLoaded(
          menuItems: response.data!.menuItems,
          products: response.data!.products,
          restaurantData: response.data!,
          showVegOnly: false,
          showNonVegOnly: false,
          isFoodSupercategory: isFoodSupercategory,
        ));
      } else {
        // Only emit error if there is no cached data
        if (_cachedRestaurantData != null) {
          final isFoodSupercategory = _isFoodSupercategory(_cachedRestaurantData!);
          emit(MenuItemsLoaded(
            menuItems: _cachedRestaurantData!.menuItems,
            products: _cachedRestaurantData!.products,
            restaurantData: _cachedRestaurantData!,
            isFoodSupercategory: isFoodSupercategory,
          ));
          // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
        } else {
          emit(MenuItemsError(response.message));
        }
      }
    } catch (e) {
      // Only emit error if there is no cached data
      if (_cachedRestaurantData != null) {
        final isFoodSupercategory = _isFoodSupercategory(_cachedRestaurantData!);
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          products: _cachedRestaurantData!.products,
          restaurantData: _cachedRestaurantData!,
          isFoodSupercategory: isFoodSupercategory,
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
        
        final isFoodSupercategory = _isFoodSupercategory(response.data!);
        emit(MenuItemsLoaded(
          menuItems: response.data!.menuItems,
          products: response.data!.products,
          restaurantData: response.data!,
          showVegOnly: false,
          showNonVegOnly: false,
          isFoodSupercategory: isFoodSupercategory,
        ));
      } else {
        // Only emit error if there is no cached data
        if (_cachedRestaurantData != null) {
          final isFoodSupercategory = _isFoodSupercategory(_cachedRestaurantData!);
          emit(MenuItemsLoaded(
            menuItems: _cachedRestaurantData!.menuItems,
            products: _cachedRestaurantData!.products,
            restaurantData: _cachedRestaurantData!,
            isFoodSupercategory: isFoodSupercategory,
          ));
          // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
        } else {
          emit(MenuItemsError(response.message));
        }
      }
    } catch (e) {
      // Only emit error if there is no cached data
      if (_cachedRestaurantData != null) {
        final isFoodSupercategory = _isFoodSupercategory(_cachedRestaurantData!);
        emit(MenuItemsLoaded(
          menuItems: _cachedRestaurantData!.menuItems,
          products: _cachedRestaurantData!.products,
          restaurantData: _cachedRestaurantData!,
          isFoodSupercategory: isFoodSupercategory,
        ));
        // Optionally: show error as a Snackbar via a side effect, but do NOT emit MenuItemsError
      } else {
        emit(MenuItemsError('Failed to refresh menu items: ${e.toString()}'));
      }
    }
  }

  // Helper method to determine if it's a food supercategory
  bool _isFoodSupercategory(RestaurantData data) {
    debugPrint('🔍 Checking supercategory: ${data.supercategory}');
    debugPrint('🔍 Menu items count: ${data.menuItems.length}');
    debugPrint('🔍 Products count: ${data.products.length}');
    
    // New logic: Prioritize products over menu items if products exist
    // This handles hybrid stores that have both food and non-food items
    if (data.products.isNotEmpty) {
      debugPrint('🔍 Products found - checking product supercategories');
      for (final product in data.products) {
        debugPrint('🔍 Product "${product.name}" supercategory: ${product.supercategory.name}');
      }
      debugPrint('🔍 Products exist - showing products (non-food supercategory)');
      return false;
    }
    
    // If no products, check if any menu item has supercategory "food"
    for (final menuItem in data.menuItems) {
      debugPrint('🔍 Menu item supercategory: ${menuItem.supercategory}');
      if (menuItem.supercategory != null && menuItem.supercategory!.toLowerCase() == 'food') {
        debugPrint('🔍 Found food supercategory in menu item - showing menu items');
        return true;
      }
    }
    
    // If no menu items or products found, default to food
    debugPrint('🔍 No menu items or products found, defaulting to food');
    return true;
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
              tags: item.tags?.toString(),
            );
        }
        return item;
      }).toList();
      
      // Emit the updated state immediately for smooth UI
      emit(MenuItemsLoaded(
        menuItems: updatedItems,
        products: currentState.products,
        restaurantData: currentState.restaurantData,
        isFiltered: currentState.isFiltered,
        filterType: currentState.filterType,
        searchQuery: currentState.searchQuery,
        showVegOnly: currentState.showVegOnly,
        showNonVegOnly: currentState.showNonVegOnly,
        isFoodSupercategory: currentState.isFoodSupercategory,
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
                tags: item.tags?.toString(),
              );
            }
            return item;
          }).toList();
          
          emit(MenuItemsLoaded(
            menuItems: revertedItems,
            products: currentState.products,
            restaurantData: currentState.restaurantData,
            isFiltered: currentState.isFiltered,
            filterType: currentState.filterType,
            searchQuery: currentState.searchQuery,
            showVegOnly: currentState.showVegOnly,
            showNonVegOnly: currentState.showNonVegOnly,
            isFoodSupercategory: currentState.isFoodSupercategory,
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
              tags: item.tags?.toString(),
            );
          }
          return item;
        }).toList();
        
        emit(MenuItemsLoaded(
          menuItems: revertedItems,
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: currentState.isFiltered,
          filterType: currentState.filterType,
          searchQuery: currentState.searchQuery,
          showVegOnly: currentState.showVegOnly,
          showNonVegOnly: currentState.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
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
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: currentState.isFiltered,
          filterType: currentState.filterType,
          searchQuery: currentState.searchQuery,
          showVegOnly: currentState.showVegOnly,
          showNonVegOnly: currentState.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
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
      
      if (currentState.isFoodSupercategory) {
        List<MenuItem> filteredItems = List.from(currentState.menuItems);

        switch (event.filterType) {
          case FilterType.priceLowToHigh:
            filteredItems.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
            break;
          case FilterType.priceHighToLow:
            filteredItems.sort((a, b) => double.parse(b.price).compareTo(double.parse(a.price)));
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
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: true,
          filterType: event.filterType,
          showVegOnly: currentState.showVegOnly,
          showNonVegOnly: currentState.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
        ));
      } else {
        List<Product> filteredProducts = List.from(currentState.products);

        switch (event.filterType) {
          case FilterType.priceLowToHigh:
            filteredProducts.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
            break;
          case FilterType.priceHighToLow:
            filteredProducts.sort((a, b) => double.parse(b.price).compareTo(double.parse(a.price)));
            break;
          case FilterType.nameAZ:
            filteredProducts.sort((a, b) => a.name.compareTo(b.name));
            break;
          case FilterType.nameZA:
            filteredProducts.sort((a, b) => b.name.compareTo(a.name));
            break;
        }

        emit(MenuItemsLoaded(
          menuItems: currentState.menuItems,
          products: filteredProducts,
          restaurantData: currentState.restaurantData,
          isFiltered: true,
          filterType: event.filterType,
          showVegOnly: currentState.showVegOnly,
          showNonVegOnly: currentState.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
        ));
      }
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
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: false,
          showVegOnly: false,
          showNonVegOnly: false,
          isFoodSupercategory: currentState.isFoodSupercategory,
        ));
      } else {
        if (currentState.isFoodSupercategory) {
          // Filter menu items based on the search query
          final filteredItems = (_cachedRestaurantData?.menuItems ?? currentState.restaurantData.menuItems)
              .where((item) =>
                  item.name.toLowerCase().contains(query) ||
                  item.description.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query))
              .toList();

          emit(MenuItemsLoaded(
            menuItems: filteredItems,
            products: currentState.products,
            restaurantData: currentState.restaurantData,
            isFiltered: true,
            searchQuery: query,
            showVegOnly: currentState.showVegOnly,
            showNonVegOnly: currentState.showNonVegOnly,
            isFoodSupercategory: currentState.isFoodSupercategory,
          ));
        } else {
          // Filter products based on the search query
          final filteredProducts = currentState.products
              .where((product) =>
                  product.name.toLowerCase().contains(query) ||
                  (product.description?.toLowerCase().contains(query) ?? false) ||
                  product.brand.toLowerCase().contains(query) ||
                  product.category.name.toLowerCase().contains(query) ||
                  product.subcategory.name.toLowerCase().contains(query))
              .toList();

          emit(MenuItemsLoaded(
            menuItems: currentState.menuItems,
            products: filteredProducts,
            restaurantData: currentState.restaurantData,
            isFiltered: true,
            searchQuery: query,
            showVegOnly: currentState.showVegOnly,
            showNonVegOnly: currentState.showNonVegOnly,
            isFoodSupercategory: currentState.isFoodSupercategory,
          ));
        }
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
        debugPrint('🔍 Parsed API response:');
        debugPrint('🔍 - Status: ${data['status']}');
        debugPrint('🔍 - Has data: ${data['data'] != null}');
        if (data['data'] != null) {
          final responseData = data['data'];
          debugPrint('🔍 - Supercategory: ${responseData['supercategory']}');
          debugPrint('🔍 - Menu items count: ${responseData['menu']?.length ?? 0}');
          debugPrint('🔍 - Products count: ${responseData['products']?.length ?? 0}');
        }
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

  Future<void> _onToggleVegFilter(
    ToggleVegFilterEvent event,
    Emitter<MenuItemsState> emit,
  ) async {
    if (state is MenuItemsLoaded) {
      final currentState = state as MenuItemsLoaded;
      
      // Only apply veg/nonveg filter for food supercategories
      if (currentState.isFoodSupercategory) {
        // Apply veg/nonveg filter to the original data
        List<MenuItem> filteredItems = _cachedRestaurantData?.menuItems ?? currentState.restaurantData.menuItems;
        
        // Apply veg/nonveg filter
        if (event.showVegOnly && !event.showNonVegOnly) {
          // Show only veg items
          filteredItems = filteredItems.where((item) => item.isVeg).toList();
        } else if (!event.showVegOnly && event.showNonVegOnly) {
          // Show only non-veg items
          filteredItems = filteredItems.where((item) => !item.isVeg).toList();
        }
        // If both true or both false, show all items (no additional filtering needed)
        
        // Apply search filter if there's a search query
        if (currentState.searchQuery != null && currentState.searchQuery!.isNotEmpty) {
          final query = currentState.searchQuery!.toLowerCase();
          filteredItems = filteredItems
              .where((item) =>
                  item.name.toLowerCase().contains(query) ||
                  item.description.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query))
              .toList();
        }
        
        // Apply sorting filter if there's one
        if (currentState.filterType != null) {
          switch (currentState.filterType!) {
            case FilterType.priceLowToHigh:
              filteredItems.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
              break;
            case FilterType.priceHighToLow:
              filteredItems.sort((a, b) => double.parse(b.price).compareTo(double.parse(a.price)));
              break;
            case FilterType.nameAZ:
              filteredItems.sort((a, b) => a.name.compareTo(b.name));
              break;
            case FilterType.nameZA:
              filteredItems.sort((a, b) => b.name.compareTo(a.name));
              break;
          }
        }

        emit(MenuItemsLoaded(
          menuItems: filteredItems,
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: event.showVegOnly || event.showNonVegOnly || currentState.isFiltered,
          filterType: currentState.filterType,
          searchQuery: currentState.searchQuery,
          showVegOnly: event.showVegOnly,
          showNonVegOnly: event.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
        ));
      } else {
        // For non-food supercategories, just update the veg filter state without filtering
        emit(MenuItemsLoaded(
          menuItems: currentState.menuItems,
          products: currentState.products,
          restaurantData: currentState.restaurantData,
          isFiltered: currentState.isFiltered,
          filterType: currentState.filterType,
          searchQuery: currentState.searchQuery,
          showVegOnly: event.showVegOnly,
          showNonVegOnly: event.showNonVegOnly,
          isFoodSupercategory: currentState.isFoodSupercategory,
        ));
      }
    }
  }
}