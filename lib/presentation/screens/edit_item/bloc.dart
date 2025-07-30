// lib/presentation/screens/edit_product/edit_product_bloc.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../models/catagory_model.dart';
import '../../../models/restaurant_menu_model.dart';
import '../../../models/update_menu_item_model.dart';
import 'event.dart';
import 'state.dart';

class EditProductBloc extends Bloc<EditProductEvent, EditProductState> {
  EditProductBloc() : super(EditProductInitial()) {
    on<EditProductInitEvent>(_onInitialize);
    on<ProductNameChangedEvent>(_onNameChanged);
    on<ProductDescriptionChangedEvent>(_onDescriptionChanged);
    on<ProductCategoryChangedEvent>(_onCategoryChanged);
    on<ProductPriceChangedEvent>(_onPriceChanged);
    on<ProductIsVegChangedEvent>(_onIsVegChanged);
    on<ProductImageSelectedEvent>(_onImageSelected);
    on<SubmitEditProductEvent>(_onSubmitProduct);
  }

  void _onInitialize(EditProductInitEvent event, Emitter<EditProductState> emit) async {
    final menuItem = event.menuItem;
    // Initially emit a state with current product data and empty categories list
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
    ));
    try {
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
      ));
    } catch (e) {
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
        errorMessage: 'Failed to load categories:  [31m${e.toString()} [0m',
      ));
    }
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    // Get token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication information not found. Please login again.');
    }
    
    // Prepare API endpoint
    final sharedPrefs = await SharedPreferences.getInstance();
    final selectedSupercategoryId = sharedPrefs.getString('selected_supercategory_id');
    
    String urlString = '${ApiConstants.baseUrl}/partner/categories';
    if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
      urlString += '?supercategory=$selectedSupercategoryId';
    }
    final url = Uri.parse(urlString);
    
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
          return categoriesJson.map((json) => CategoryModel.fromJson(json)).toList();
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
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(name: event.name));
    }
  }

  void _onDescriptionChanged(ProductDescriptionChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(description: event.description));
    }
  }

  void _onCategoryChanged(ProductCategoryChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(category: event.categoryName, categoryId: event.categoryId));
    }
  }

  void _onPriceChanged(ProductPriceChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(price: event.price));
    }
  }

  void _onIsVegChanged(ProductIsVegChangedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(isVeg: event.isVeg));
    }
  }

  void _onImageSelected(ProductImageSelectedEvent event, Emitter<EditProductState> emit) {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      emit(currentState.copyWith(image: event.image));
    }
  }

  Future<void> _onSubmitProduct(SubmitEditProductEvent event, Emitter<EditProductState> emit) async {
    if (state is EditProductFormState) {
      final currentState = state as EditProductFormState;
      // Validation
      if (currentState.name.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Product name is required'));
        return;
      }
      if (currentState.categoryId == null || currentState.categoryId!.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Please select a category'));
        return;
      }
      if (currentState.price.isEmpty || double.tryParse(currentState.price) == null) {
        emit(currentState.copyWith(errorMessage: 'Please enter a valid price'));
        return;
      }
      // Start submission
      emit(currentState.copyWith(isSubmitting: true, errorMessage: null));
      try {
        final response = await _updateMenuItem(
          menuId: currentState.menuId,
          name: currentState.name,
          description: currentState.description,
          categoryId: currentState.categoryId!,
          price: currentState.price,
          isVeg: currentState.isVeg,
          image: currentState.image,
        );
        if (response.status == 'SUCCESS') {
          // Success
          emit(currentState.copyWith(isSubmitting: false, isSuccess: true));
        } else {
          // API returned an error
          emit(currentState.copyWith(
            isSubmitting: false,
            errorMessage: response.message,
          ));
        }
      } catch (e) {
        // Error
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to update product: ${e.toString()}',
        ));
      }
    }
  }

  // Updated _updateMenuItem method
  Future<UpdateMenuItemResponse> _updateMenuItem({
    required String menuId,
    required String name,
    required String description,
    required String categoryId,
    required String price,
    required bool isVeg,
    File? image,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item/$menuId');
      
      // Include all the required fields
      Map<String, dynamic> requestData = {
        'name': name,
        'price': price,
        'available': 'true',
        'description': description,
        'category': categoryId,
        'isVeg': isVeg.toString(),
        'isTaxIncluded': 'true',
        'isCancellable': 'false',
        'tags': '{"AB", "CD", "DE"}',
      };
      
      debugPrint('Updating menu item: $url');
      debugPrint('Request data: $requestData');
      
      if (image != null && await image.exists()) {
        // Multipart request for updating with image
        var request = http.MultipartRequest('PUT', url);
        
        // Add authorization header
        request.headers['Authorization'] = 'Bearer $token';
        
        // Add all fields
        requestData.forEach((key, value) {
          request.fields[key] = value;
        });
        
        // Add image file
        final fileName = path.basename(image.path);
        final extension = path.extension(fileName).toLowerCase();
        String contentType;
        
        if (extension == '.jpg' || extension == '.jpeg') {
          contentType = 'image/jpeg';
        } else if (extension == '.png') {
          contentType = 'image/png';
        } else {
          contentType = 'application/octet-stream';
        }
        
        request.files.add(
          http.MultipartFile(
            'image',
            image.readAsBytes().asStream(),
            await image.length(),
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
        
        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
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
      } else {
        // Regular JSON request without image
        final response = await http.put(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
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
      }
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      return UpdateMenuItemResponse(
        status: 'ERROR',
        message: 'Error: ${e.toString()}',
      );
    }
  }
}