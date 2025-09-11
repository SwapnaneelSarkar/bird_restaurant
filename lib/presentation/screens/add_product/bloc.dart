// lib/presentation/screens/add_product/bloc.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../models/catagory_model.dart';
import '../../../models/menu_item_model.dart';
import '../../../models/food_type_model.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';
import '../../../utils/time_validation.dart';
import '../../../utils/validation_utils.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  AddProductBloc() : super(AddProductInitial()) {
    on<AddProductInitEvent>(_onInitialize);
    on<ProductNameChangedEvent>(_onNameChanged);
    on<ProductDescriptionChangedEvent>(_onDescriptionChanged);
    on<ProductCategoryChangedEvent>(_onCategoryChanged);
    on<ProductPriceChangedEvent>(_onPriceChanged);
    on<ProductTagsChangedEvent>(_onTagsChanged);
    on<ProductImageSelectedEvent>(_onImageSelected);
    on<ToggleCodAllowedEvent>(_onToggleCodAllowed);
    on<ToggleTaxIncludedEvent>(_onToggleTaxIncluded);
    on<ToggleCancellableEvent>(_onToggleCancellable);
    on<FetchFoodTypesEvent>(_onFetchFoodTypes);
    on<FoodTypeChangedEvent>(_onFoodTypeChanged);
    on<ToggleAvailableAllDayEvent>(_onToggleAvailableAllDay);
    on<AvailableFromTimeChangedEvent>(_onAvailableFromTimeChanged);
    on<AvailableToTimeChangedEvent>(_onAvailableToTimeChanged);
    // New timing schedule events
    on<ToggleTimingEnabledEvent>(_onToggleTimingEnabled);
    on<UpdateDayScheduleEvent>(_onUpdateDaySchedule);
    on<UpdateTimezoneEvent>(_onUpdateTimezone);
    on<SubmitProductEvent>(_onSubmitProduct);
    on<ResetFormEvent>(_onResetForm);
    // Validation events
    on<ValidateNameEvent>(_onValidateName);
    on<ValidateDescriptionEvent>(_onValidateDescription);
    on<ValidatePriceEvent>(_onValidatePrice);
    on<ValidateTagsEvent>(_onValidateTags);
    on<ValidateAllFieldsEvent>(_onValidateAllFields);
    on<ValidateTimingScheduleEvent>(_onValidateTimingSchedule);
  }

  void _onInitialize(AddProductInitEvent event, Emitter<AddProductState> emit) async {
    emit(AddProductFormState(product: ProductModel()));
    
    // Fetch categories
    await _fetchCategories(emit);
    
    // Fetch food types
    add(const FetchFoodTypesEvent());
  }

  Future<List<CategoryModel>> _fetchCategories(Emitter<AddProductState> emit) async {
    // Get token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication information not found. Please login again.');
    }
    
    // Prepare API endpoint
    final selectedSupercategoryId = await TokenService.getSupercategoryId();
    debugPrint('🔍 Add Product - Supercategory ID: $selectedSupercategoryId');
    
    String urlString = '${ApiConstants.baseUrl}/partner/categories';
    if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
      urlString += '?supercategory=$selectedSupercategoryId';
    }
    final url = Uri.parse(urlString);
    
    debugPrint('🔍 Add Product - Categories API URL: $urlString');
    
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
          debugPrint('🔍 Add Product - Fetched ${categories.length} categories');
          
          // Log category names for debugging
          for (int i = 0; i < categories.length; i++) {
            debugPrint('🔍 Add Product - Category ${i + 1}: ${categories[i].name} (ID: ${categories[i].id})');
          }
          
          emit(AddProductFormState(
            product: ProductModel(),
            categories: categories,
          ));
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

  void _onNameChanged(ProductNameChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? nameError = currentState.nameError;
      
      // Clear error if field becomes valid
      if (event.name.isNotEmpty && event.name.length <= 30) {
        nameError = null;
      }
      
      emit(currentState.copyWith(
        product: currentState.product.copyWith(name: event.name),
        nameError: nameError,
      ));
    }
  }

  void _onDescriptionChanged(ProductDescriptionChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? descriptionError = ValidationUtils.validateDescription(event.description);
      
      emit(currentState.copyWith(
        product: currentState.product.copyWith(description: event.description),
        descriptionError: descriptionError,
      ));
    }
  }

  void _onCategoryChanged(ProductCategoryChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          category: event.categoryName,
          categoryId: event.categoryId,
        ),
      ));
    }
  }

  void _onPriceChanged(ProductPriceChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? priceError = currentState.priceError;
      
      // Clear error if field becomes valid
      if (event.price > 0 && event.price <= 9999.99) {
        priceError = null;
      }
      
      emit(currentState.copyWith(
        product: currentState.product.copyWith(price: event.price),
        priceError: priceError,
      ));
    }
  }

  void _onTagsChanged(ProductTagsChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? tagsError = currentState.tagsError;
      
      // Clear error if field becomes valid
      if (event.tags.length <= 100) {
        tagsError = null;
      }
      
      emit(currentState.copyWith(
        product: currentState.product.copyWith(tags: event.tags),
        tagsError: tagsError,
      ));
    }
  }

  void _onImageSelected(ProductImageSelectedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(image: event.image),
      ));
    }
  }

  void _onToggleCodAllowed(ToggleCodAllowedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(codAllowed: event.isAllowed),
      ));
    }
  }

  void _onToggleTaxIncluded(ToggleTaxIncludedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(taxIncluded: event.isIncluded),
      ));
    }
  }

  void _onToggleCancellable(ToggleCancellableEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(isCancellable: event.isCancellable),
      ));
    }
  }

  void _onFetchFoodTypes(FetchFoodTypesEvent event, Emitter<AddProductState> emit) async {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(isLoadingFoodTypes: true));
      
      try {
        final apiService = ApiServices();
        final response = await apiService.getRestaurantFoodTypes();
        
        if (response.status == 'SUCCESS') {
          // Load selected food type from shared preferences if available
          final prefs = await SharedPreferences.getInstance();
          final savedFoodTypeId = prefs.getString('restaurant_food_type_id');
          
          FoodTypeModel? selectedFoodType;
          if (savedFoodTypeId != null && response.data.isNotEmpty) {
            selectedFoodType = response.data.firstWhere(
              (type) => type.restaurantFoodTypeId == savedFoodTypeId,
              orElse: () => response.data.first,
            );
          }
          
          emit(currentState.copyWith(
            foodTypes: response.data,
            selectedFoodType: selectedFoodType,
            isLoadingFoodTypes: false,
            product: currentState.product.copyWith(
              restaurantFoodTypeId: selectedFoodType?.restaurantFoodTypeId,
            ),
          ));
        } else {
          emit(currentState.copyWith(isLoadingFoodTypes: false));
        }
      } catch (e) {
        debugPrint('Error fetching food types: $e');
        emit(currentState.copyWith(isLoadingFoodTypes: false));
      }
    }
  }

  void _onFoodTypeChanged(FoodTypeChangedEvent event, Emitter<AddProductState> emit) async {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      
      emit(currentState.copyWith(
        selectedFoodType: event.foodType,
        product: currentState.product.copyWith(
          restaurantFoodTypeId: event.foodType.restaurantFoodTypeId,
        ),
      ));
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_food_type_id', event.foodType.restaurantFoodTypeId);
      await prefs.setString('restaurant_food_type_name', event.foodType.name);
    }
  }

  void _onToggleAvailableAllDay(ToggleAvailableAllDayEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          isAvailableAllDay: event.isAvailableAllDay,
        ),
      ));
    }
  }

  void _onAvailableFromTimeChanged(AvailableFromTimeChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          availableFromTime: event.time,
        ),
      ));
    }
  }

  void _onAvailableToTimeChanged(AvailableToTimeChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          availableToTime: event.time,
        ),
      ));
    }
  }

  void _onToggleTimingEnabled(ToggleTimingEnabledEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          timingEnabled: event.enabled,
        ),
      ));
    }
  }

  void _onUpdateDaySchedule(UpdateDayScheduleEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      final newDaySchedule = DaySchedule(
        enabled: event.enabled,
        start: event.start,
        end: event.end,
      );
      
      TimingSchedule newTimingSchedule;
      switch (event.day.toLowerCase()) {
        case 'monday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(monday: newDaySchedule);
          break;
        case 'tuesday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(tuesday: newDaySchedule);
          break;
        case 'wednesday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(wednesday: newDaySchedule);
          break;
        case 'thursday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(thursday: newDaySchedule);
          break;
        case 'friday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(friday: newDaySchedule);
          break;
        case 'saturday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(saturday: newDaySchedule);
          break;
        case 'sunday':
          newTimingSchedule = currentState.product.timingSchedule.copyWith(sunday: newDaySchedule);
          break;
        default:
          return; // Invalid day
      }
      
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          timingSchedule: newTimingSchedule,
        ),
      ));
    }
  }

  void _onUpdateTimezone(UpdateTimezoneEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(
          timezone: event.timezone,
        ),
      ));
    }
  }

  void _onSubmitProduct(SubmitProductEvent event, Emitter<AddProductState> emit) async {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      
      // Validation
      if (currentState.product.name.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Product name is required'));
        return;
      }
      
      final descriptionError = ValidationUtils.validateDescription(currentState.product.description);
      if (descriptionError != null) {
        emit(currentState.copyWith(errorMessage: descriptionError));
        return;
      }
      
      if (currentState.product.categoryId == null) {
        emit(currentState.copyWith(errorMessage: 'Please select a category'));
        return;
      }
      
      if (currentState.product.price <= 0) {
        emit(currentState.copyWith(errorMessage: 'Please enter a valid price'));
        return;
      }
      
      // Validate timing schedule if enabled
      if (currentState.product.timingEnabled) {
        final timingError = TimeValidationUtils.validateTimingSchedule(currentState.product.timingSchedule);
        if (timingError != null) {
          emit(currentState.copyWith(errorMessage: timingError));
          return;
        }
      }
      
      // Image is optional - if no image, we'll use JSON POST, if image exists, we'll use MultipartRequest
      
      // Start submission
      emit(currentState.copyWith(isSubmitting: true, errorMessage: null));
      
      try {
        final result = await _submitMenuItemToApi(currentState.product);
        
        if (result.status == 'SUCCESS') {
          // Success
          emit(currentState.copyWith(isSubmitting: false, isSuccess: true));
        } else {
          // API returned an error
          emit(currentState.copyWith(
            isSubmitting: false,
            errorMessage: result.message,
          ));
        }
      } catch (e) {
        // Error
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to add product: ${e.toString()}',
              ));
    }
  }

}

  void _onResetForm(ResetFormEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: ProductModel(),
        errorMessage: null,
        isSuccess: false,
        nameError: null,
        descriptionError: null,
        priceError: null,
        tagsError: null,
        timingError: null,
      ));
    }
  }
  
Future<MenuItemResponse> _submitMenuItemToApi(ProductModel product) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final partnerId = prefs.getString('user_id');
    if (token == null || partnerId == null) {
      throw Exception('Authentication information not found. Please login again.');
    }
    
    final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item');
    debugPrint('Product image is null: ${product.image == null}');
    
    if (product.image != null) {
      // Use multipart request for image upload
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      request.fields['partner_id'] = partnerId;
      request.fields['name'] = product.name;
      request.fields['price'] = product.price.toString();
      request.fields['category'] = product.categoryId ?? '';
      request.fields['description'] = product.description;
      request.fields['isVeg'] = product.codAllowed.toString();
      request.fields['isTaxIncluded'] = product.taxIncluded.toString();
      request.fields['isCancellable'] = product.isCancellable.toString();
      request.fields['available'] = 'true';
      request.fields['timing_enabled'] = product.timingEnabled.toString();
      
      // FIXED: Add timing schedule as nested form fields instead of JSON string
      final schedule = product.timingSchedule;
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      
      for (final day in days) {
        DaySchedule daySchedule;
        switch (day) {
          case 'monday':
            daySchedule = schedule.monday;
            break;
          case 'tuesday':
            daySchedule = schedule.tuesday;
            break;
          case 'wednesday':
            daySchedule = schedule.wednesday;
            break;
          case 'thursday':
            daySchedule = schedule.thursday;
            break;
          case 'friday':
            daySchedule = schedule.friday;
            break;
          case 'saturday':
            daySchedule = schedule.saturday;
            break;
          case 'sunday':
            daySchedule = schedule.sunday;
            break;
          default:
            continue;
        }
        
        request.fields['timing_schedule[$day][enabled]'] = daySchedule.enabled.toString();
        request.fields['timing_schedule[$day][start]'] = daySchedule.start;
        request.fields['timing_schedule[$day][end]'] = daySchedule.end;
      }
      
      if (product.restaurantFoodTypeId != null) {
        request.fields['restaurant_food_type_id'] = product.restaurantFoodTypeId!;
      }
      request.fields['timezone'] = product.timezone;
      
      // Add image field
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        product.image!.path,
      ));
      
      debugPrint('Sending multipart menu item request to: $url');
      debugPrint('Request fields: ${request.fields}');
      debugPrint('Request files: ${request.files.map((f) => f.field).toList()}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return MenuItemResponse.fromJson(responseData);
      } else {
        try {
          final errorData = json.decode(response.body);
          return MenuItemResponse(
            status: 'ERROR',
            message: errorData['message'] ?? 'Failed to add menu item',
          );
        } catch (e) {
          return MenuItemResponse(
            status: 'ERROR',
            message: 'Failed to add menu item. Status: ${response.statusCode}',
          );
        }
      }
    } else {
      final body = {
        'partner_id': partnerId,
        'name': product.name,
        'price': product.price,
        'category': product.categoryId ?? '',
        'description': product.description,
        'isVeg': product.codAllowed,
        'isTaxIncluded': product.taxIncluded,
        'isCancellable': product.isCancellable,
        'available': true,
        'timing_enabled': product.timingEnabled,
        'timing_schedule': product.timingSchedule.toJson(), 
        'restaurant_food_type_id': product.restaurantFoodTypeId,
        'timezone': product.timezone,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      
      debugPrint('Sending JSON menu item request to: $url');
      debugPrint('Request body: ${json.encode(body)}');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return MenuItemResponse.fromJson(responseData);
      } else {
        try {
          final errorData = json.decode(response.body);
          return MenuItemResponse(
            status: 'ERROR',
            message: errorData['message'] ?? 'Failed to add menu item',
          );
        } catch (e) {
          return MenuItemResponse(
            status: 'ERROR',
            message: 'Failed to add menu item. Status: ${response.statusCode}',
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Error submitting menu item: $e');
    return MenuItemResponse(
      status: 'ERROR',
      message: 'Error: ${e.toString()}',
    );
  }
}

  // Validation handlers
  void _onValidateName(ValidateNameEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? nameError;
      
      if (event.name.isEmpty) {
        nameError = 'Product name is required';
      } else if (event.name.length > 30) {
        nameError = 'Maximum 30 characters allowed';
      }
      
      emit(currentState.copyWith(nameError: nameError));
    }
  }

  void _onValidateDescription(ValidateDescriptionEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? descriptionError = ValidationUtils.validateDescription(event.description);
      
      emit(currentState.copyWith(descriptionError: descriptionError));
    }
  }

  void _onValidatePrice(ValidatePriceEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? priceError;
      
      if (event.price.isEmpty) {
        priceError = 'Price is required';
      } else {
        final price = double.tryParse(event.price) ?? 0.0;
        if (price <= 0) {
          priceError = 'Price must be greater than 0';
        } else if (price > 9999.99) {
          priceError = 'Price cannot exceed \$9999.99';
        }
      }
      
      emit(currentState.copyWith(priceError: priceError));
    }
  }

  void _onValidateTags(ValidateTagsEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? tagsError;
      
      if (event.tags.length > 100) {
        tagsError = 'Maximum 100 characters allowed';
      }
      
      emit(currentState.copyWith(tagsError: tagsError));
    }
  }

  void _onValidateAllFields(ValidateAllFieldsEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      
      // Validate name
      String? nameError;
      if (currentState.product.name.isEmpty) {
        nameError = 'Product name is required';
      } else if (currentState.product.name.length > 30) {
        nameError = 'Maximum 30 characters allowed';
      }
      
      // Validate description
      String? descriptionError = ValidationUtils.validateDescription(currentState.product.description);
      
      // Validate price
      String? priceError;
      if (currentState.product.price <= 0) {
        priceError = 'Price is required';
      } else if (currentState.product.price > 9999.99) {
        priceError = 'Price cannot exceed \$9999.99';
      }
      
      // Validate tags
      String? tagsError;
      if (currentState.product.tags.length > 100) {
        tagsError = 'Maximum 100 characters allowed';
      }
      
      // Validate timing schedule if enabled
      String? timingError;
      if (currentState.product.timingEnabled) {
        timingError = TimeValidationUtils.validateTimingSchedule(currentState.product.timingSchedule);
      }
      
      emit(currentState.copyWith(
        nameError: nameError,
        descriptionError: descriptionError,
        priceError: priceError,
        tagsError: tagsError,
        timingError: timingError,
      ));
    }
  }

  void _onValidateTimingSchedule(ValidateTimingScheduleEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      String? timingError;
      
      if (currentState.product.timingEnabled) {
        timingError = TimeValidationUtils.validateTimingSchedule(currentState.product.timingSchedule);
      }
      
      emit(currentState.copyWith(timingError: timingError));
    }
  }
}