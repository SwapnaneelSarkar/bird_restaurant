// lib/presentation/screens/edit_item/edit_product_bloc.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../models/catagory_model.dart';
import '../../../models/update_menu_item_model.dart';
import '../../../services/token_service.dart';
import '../add_product/state.dart'; // Import timing schedule models
import 'event.dart';
import 'state.dart';
import '../../../utils/time_validation.dart';
import '../../../utils/validation_utils.dart';

class EditProductBloc extends Bloc<EditProductEvent, EditProductState> {
  EditProductBloc() : super(EditProductInitial()) {
    on<EditProductInitEvent>(_onInitialize);
    on<ProductNameChangedEvent>(_onNameChanged);
    on<ProductDescriptionChangedEvent>(_onDescriptionChanged);
    on<ProductCategoryChangedEvent>(_onCategoryChanged);
    on<ProductPriceChangedEvent>(_onPriceChanged);
    on<ProductIsVegChangedEvent>(_onIsVegChanged);
    on<ProductImageSelectedEvent>(_onImageSelected);
    // New timing schedule events
    on<ToggleTimingEnabledEvent>(_onToggleTimingEnabled);
    on<UpdateDayScheduleEvent>(_onUpdateDaySchedule);
    on<UpdateTimezoneEvent>(_onUpdateTimezone);
    on<SubmitEditProductEvent>(_onSubmitProduct);
    on<ValidateTimingScheduleEvent>(_onValidateTimingSchedule);
    on<ValidateDescriptionEvent>(_onValidateDescription);
  }

  void _onInitialize(EditProductInitEvent event, Emitter<EditProductState> emit) async {
    if (isClosed) return;
    try {
      final menuItem = event.menuItem;
      // Initially emit a state with current product data and empty categories list
      if (!isClosed) {
        emit(EditProductFormState(
          menuId: menuItem.menuId,
          name: menuItem.name,
          description: menuItem.description,
          category: menuItem.category,
          categoryId: null,
          price: menuItem.price.toString(),
          isVeg: menuItem.isVeg,
          imageUrl: menuItem.imageUrl,
          categories: [],
          timingEnabled: menuItem.timingEnabled,
          timingSchedule: menuItem.timingSchedule ?? TimingSchedule.defaultSchedule(),
          timezone: menuItem.timezone ?? 'Asia/Kolkata',
        ));
      }
      
      // Fetch categories from API
      final categories = await _fetchCategories();
      // Find the category id for the current menu item
      String? selectedCategoryId;
      bool found = false;
      for (final cat in categories) {
        if (cat.name.toLowerCase() == menuItem.category.toLowerCase() || cat.id == menuItem.category) {
          selectedCategoryId = cat.id;
          found = true;
          break;
        }
      }
      // If not found and menuItem.category is not empty, add a temporary category
      List<CategoryModel> finalCategories = List.from(categories);
      if (!found && menuItem.category.isNotEmpty) {
        finalCategories.add(CategoryModel(
          id: menuItem.category,
          name: 'Unknown (id: ${menuItem.category})',
        ));
        selectedCategoryId = menuItem.category;
      }
      // If menuItem.category is empty or not found, set selectedCategoryId to ''
      if (selectedCategoryId == null) {
        selectedCategoryId = '';
      }
      if (!isClosed) {
        emit(EditProductFormState(
          menuId: menuItem.menuId,
          name: menuItem.name,
          description: menuItem.description,
          category: menuItem.category,
          categoryId: selectedCategoryId,
          price: menuItem.price.toString(),
          isVeg: menuItem.isVeg,
          imageUrl: menuItem.imageUrl,
          categories: finalCategories,
          timingEnabled: menuItem.timingEnabled,
          timingSchedule: menuItem.timingSchedule ?? TimingSchedule.defaultSchedule(),
          timezone: menuItem.timezone ?? 'Asia/Kolkata',
        ));
      }
    } catch (e) {
      // If there's an error, emit a state with error message
      if (!isClosed) {
        final menuItem = event.menuItem;
        emit(EditProductFormState(
          menuId: menuItem.menuId,
          name: menuItem.name,
          description: menuItem.description,
          category: menuItem.category,
          categoryId: null,
          price: menuItem.price.toString(),
          isVeg: menuItem.isVeg,
          imageUrl: menuItem.imageUrl,
          categories: [],
          errorMessage: 'Failed to load categories: ${e.toString()}',
          timingEnabled: menuItem.timingEnabled,
          timingSchedule: menuItem.timingSchedule ?? TimingSchedule.defaultSchedule(),
          timezone: menuItem.timezone ?? 'Asia/Kolkata',
        ));
      }
    }
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    // Get token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication information not found. Please login again.');
    }
    
    // Prepare API endpoint - use TokenService for consistency
    final selectedSupercategoryId = await TokenService.getSupercategoryId();
    debugPrint('🔍 Edit Product - Supercategory ID: $selectedSupercategoryId');
    
    String urlString = '${ApiConstants.baseUrl}/partner/categories';
    if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
      urlString += '?supercategory=$selectedSupercategoryId';
    }
    final url = Uri.parse(urlString);
    
    debugPrint('🔍 Edit Product - Categories API URL: $urlString');
    
    try {
      // Make GET request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      debugPrint('Categories response status: ${response.statusCode}');
      debugPrint('Categories response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          final List<dynamic> categoriesJson = responseData['data'];
          final categories = categoriesJson.map((json) => CategoryModel.fromJson(json)).toList();
          debugPrint('🔍 Edit Product - Fetched ${categories.length} categories');
          
          // Log category names for debugging
          for (int i = 0; i < categories.length; i++) {
            debugPrint('🔍 Edit Product - Category ${i + 1}: ${categories[i].name} (ID: ${categories[i].id})');
          }
          
          return categories;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Failed to fetch categories. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  // Helper method to format category for display
  String _formatCategoryForDisplay(String category) {
    // Handle hyphenated categories like "main-course" -> "Main Course"
    if (category.contains('-')) {
      return category.split('-')
          .map((part) => part.isNotEmpty 
              ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}'
              : '')
          .join(' ');
    }
    
    // Handle already formatted categories
    return category.isNotEmpty 
        ? '${category[0].toUpperCase()}${category.substring(1).toLowerCase()}'
        : '';
  }

  void _onNameChanged(ProductNameChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(name: event.name));
    }
  }

  void _onDescriptionChanged(ProductDescriptionChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(description: event.description));
    }
  }

  void _onCategoryChanged(ProductCategoryChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(category: event.categoryName, categoryId: event.categoryId));
    }
  }

  void _onPriceChanged(ProductPriceChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(price: event.price));
    }
  }

  void _onIsVegChanged(ProductIsVegChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(isVeg: event.isVeg));
    }
  }

  void _onImageSelected(ProductImageSelectedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(image: event.image));
    }
  }

  Future<void> _onSubmitProduct(SubmitEditProductEvent event, Emitter<EditProductState> emit) async {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      // Validation
      if (currentState.name.trim().isEmpty) {
        if (!isClosed) {
          emit(currentState.copyWith(errorMessage: 'Product name is required'));
        }
        return;
      }
      
      final descriptionError = ValidationUtils.validateDescription(currentState.description);
      if (descriptionError != null) {
        if (!isClosed) {
          emit(currentState.copyWith(errorMessage: descriptionError));
        }
        return;
      }
      if (currentState.categoryId == null || currentState.categoryId!.isEmpty) {
        if (!isClosed) {
          emit(currentState.copyWith(errorMessage: 'Please select a category'));
        }
        return;
      }
      if (currentState.price.trim().isEmpty) {
        if (!isClosed) {
          emit(currentState.copyWith(errorMessage: 'Please enter a price'));
        }
        return;
      }
      final priceValue = double.tryParse(currentState.price);
      if (priceValue == null || priceValue <= 0) {
        if (!isClosed) {
          emit(currentState.copyWith(errorMessage: 'Please enter a valid price greater than 0'));
        }
        return;
      }
      
      // Validate timing schedule if enabled
      if (currentState.timingEnabled) {
        final timingError = TimeValidationUtils.validateTimingSchedule(currentState.timingSchedule);
        if (timingError != null) {
          if (!isClosed) {
            emit(currentState.copyWith(errorMessage: timingError));
          }
          return;
        }
      }
      
      // Start submission
      if (!isClosed) {
        emit(currentState.copyWith(isSubmitting: true, errorMessage: null));
      }
      try {
        final response = await _updateMenuItem(
          menuId: currentState.menuId,
          name: currentState.name,
          description: currentState.description,
          categoryId: currentState.categoryId!,
          price: currentState.price,
          isVeg: currentState.isVeg,
          image: currentState.image,
          timingEnabled: currentState.timingEnabled,
          timingSchedule: currentState.timingSchedule,
          timezone: currentState.timezone,
        );
        if (response.status == 'SUCCESS') {
          // Success
          if (!isClosed) {
            emit(currentState.copyWith(isSubmitting: false, isSuccess: true));
          }
        } else {
          // API returned an error
          if (!isClosed) {
            emit(currentState.copyWith(
              isSubmitting: false,
              errorMessage: response.message,
            ));
          }
        }
      } catch (e) {
        // Error
        if (!isClosed) {
          emit(currentState.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to update product: ${e.toString()}',
          ));
        }
      }
    }
  }

  // Updated _updateMenuItem method with timing schedule support
  Future<UpdateMenuItemResponse> _updateMenuItem({
    required String menuId,
    required String name,
    required String description,
    required String categoryId,
    required String price,
    required bool isVeg,
    File? image,
    // String? restaurantFoodTypeId, // Not supported by API
    bool timingEnabled = false,
    TimingSchedule? timingSchedule,
    String? timezone,
  }) async {
    return _updateMenuItemWithRetry(
      menuId: menuId,
      name: name,
      description: description,
      categoryId: categoryId,
      price: price,
      isVeg: isVeg,
      image: image,
      timingEnabled: timingEnabled,
      timingSchedule: timingSchedule,
      timezone: timezone,
      retryCount: 0,
    );
  }

  Future<UpdateMenuItemResponse> _updateMenuItemWithRetry({
    required String menuId,
    required String name,
    required String description,
    required String categoryId,
    required String price,
    required bool isVeg,
    File? image,
    bool timingEnabled = false,
    TimingSchedule? timingSchedule,
    String? timezone,
    int retryCount = 0,
  }) async {
    debugPrint('🔄 _updateMenuItem: Method called with menuId: $menuId');
    debugPrint('🔄 _updateMenuItem: timingEnabled: $timingEnabled');
    debugPrint('🔄 _updateMenuItem: timezone: $timezone');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item/$menuId');
      
      // Convert price to double for API
      final double priceValue = double.tryParse(price) ?? 0.0;
      
      http.Response response;
      
      if (image != null) {
        // Use multipart request for image upload
        final request = http.MultipartRequest('PUT', url);
        request.headers['Authorization'] = 'Bearer $token';
        
        // Add text fields
        request.fields['name'] = name;
        request.fields['price'] = priceValue.toString();
        request.fields['category'] = categoryId;
        request.fields['description'] = description;
        request.fields['isVeg'] = isVeg.toString();
        request.fields['isTaxIncluded'] = 'true';
        request.fields['isCancellable'] = 'true';
        request.fields['available'] = 'true';
        request.fields['timing_enabled'] = timingEnabled.toString();
        request.fields['timezone'] = timezone ?? 'Asia/Kolkata';
        
        // Only add timing_schedule if timing is enabled
        if (timingEnabled && timingSchedule != null) {
          try {
            final timingJson = timingSchedule.toJson();
            debugPrint('🔄 Timing schedule JSON: ${json.encode(timingJson)}');
            request.fields['timing_schedule'] = json.encode(timingJson);
          } catch (e) {
            debugPrint('🔄 Error serializing timing schedule: $e');
            // Continue without timing schedule if there's an error
          }
        }
        
        // Add image field
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
        ));
        
        debugPrint('🔄 Updating menu item with image: $url');
        debugPrint('🔄 Request fields: ${request.fields}');
        debugPrint('🔄 Request files: ${request.files.map((f) => f.field).toList()}');
        debugPrint('🔄 Retry attempt: $retryCount');
        
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30), // Add timeout to prevent hanging
          onTimeout: () {
            throw Exception('Request timeout. Please try again.');
          },
        );
        response = await http.Response.fromStream(streamedResponse);
        
      } else {
        // Use JSON PUT when no image
        final body = {
          'name': name,
          'price': priceValue,
          'category': categoryId,
          'description': description,
          'isVeg': isVeg,
          'isTaxIncluded': true,
          'isCancellable': true,
          'available': true,
          'timing_enabled': timingEnabled,
          'timezone': timezone ?? 'Asia/Kolkata',
        };
        
        // Only add timing_schedule if timing is enabled
        if (timingEnabled && timingSchedule != null) {
          try {
            final timingJson = timingSchedule.toJson();
            debugPrint('🔄 Timing schedule JSON: ${json.encode(timingJson)}');
            body['timing_schedule'] = timingJson;
          } catch (e) {
            debugPrint('🔄 Error serializing timing schedule: $e');
            // Continue without timing schedule if there's an error
          }
        }
        
        debugPrint('🔄 Updating menu item: $url');
        debugPrint('🔄 Request body: ${json.encode(body)}');
        debugPrint('🔄 Retry attempt: $retryCount');
        
        response = await http.put(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        ).timeout(
          const Duration(seconds: 30), // Add timeout to prevent hanging
          onTimeout: () {
            throw Exception('Request timeout. Please try again.');
          },
        );
      }
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateMenuItemResponse.fromJson(data);
      } else if (response.statusCode == 504) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Gateway timeout. Please check your connection and try again.',
        );
      } else if (response.statusCode == 401) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Authentication failed. Please login again.',
        );
      } else if (response.statusCode == 403) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Access denied. You do not have permission to update this item.',
        );
      } else if (response.statusCode == 404) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Menu item not found. It may have been deleted.',
        );
      } else if (response.statusCode >= 500) {
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Server error. Please try again later.',
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          return UpdateMenuItemResponse(
            status: 'ERROR',
            message: errorData['message'] ?? 'Failed to update menu item. Status: ${response.statusCode}',
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
        
        // Retry logic for network errors
        if (retryCount < 2 && (
          e.toString().contains('timeout') ||
          e.toString().contains('504') ||
          e.toString().contains('502') ||
          e.toString().contains('503') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Socket')
        )) {
          debugPrint('Retrying update menu item. Attempt ${retryCount + 1}');
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2)); // Exponential backoff
          return _updateMenuItemWithRetry(
            menuId: menuId,
            name: name,
            description: description,
            categoryId: categoryId,
            price: price,
            isVeg: isVeg,
            image: image,
            timingEnabled: timingEnabled,
            timingSchedule: timingSchedule,
            timezone: timezone,
            retryCount: retryCount + 1,
          );
        }
        
        if (e.toString().contains('timeout')) {
          return UpdateMenuItemResponse(
            status: 'ERROR',
            message: 'Request timeout. Please check your connection and try again.',
          );
        }
        return UpdateMenuItemResponse(
          status: 'ERROR',
          message: 'Error: ${e.toString()}',
        );
      }
  }

  // Timing schedule event handlers
  void _onToggleTimingEnabled(ToggleTimingEnabledEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(timingEnabled: event.enabled));
    }
  }

  void _onUpdateDaySchedule(UpdateDayScheduleEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      final updatedSchedule = currentState.timingSchedule.copyWith(
        monday: event.day == 'monday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.monday,
        tuesday: event.day == 'tuesday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.tuesday,
        wednesday: event.day == 'wednesday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.wednesday,
        thursday: event.day == 'thursday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.thursday,
        friday: event.day == 'friday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.friday,
        saturday: event.day == 'saturday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.saturday,
        sunday: event.day == 'sunday' ? DaySchedule(enabled: event.enabled, start: event.start, end: event.end) : currentState.timingSchedule.sunday,
      );
      emit(currentState.copyWith(timingSchedule: updatedSchedule));
    }
  }

  void _onUpdateTimezone(UpdateTimezoneEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(timezone: event.timezone));
    }
  }

  void _onValidateTimingSchedule(ValidateTimingScheduleEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      String? timingError;
      
      if (currentState.timingEnabled) {
        timingError = TimeValidationUtils.validateTimingSchedule(currentState.timingSchedule);
      }
      
      emit(currentState.copyWith(timingError: timingError));
    }
  }

  void _onValidateDescription(ValidateDescriptionEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState && !isClosed) {
      final currentState = state as EditProductFormState;
      String? descriptionError = ValidationUtils.validateDescription(event.description);
      
      emit(currentState.copyWith(descriptionError: descriptionError));
    }
  }
}