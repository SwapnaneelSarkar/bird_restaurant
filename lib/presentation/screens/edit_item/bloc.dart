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

  // lib/presentation/screens/edit_product/edit_product_bloc.dart
// Update the _onInitialize method

void _onInitialize(EditProductInitEvent event, Emitter<EditProductState> emit) {
  final menuItem = event.menuItem;
  
  // Create a list of predefined categories
  List<String> categories = [
    'Food',
    'Beverages',
    'Desserts',
    'Snacks',
    'Appetizers',
    'Main Course'
  ];
  
  // Add the item's category if it doesn't already exist in the list
  final normalizedCategory = menuItem.category.toLowerCase().replaceAll('-', ' ');
  final categoryExists = categories.any((cat) => 
    cat.toLowerCase().replaceAll(' ', '-') == normalizedCategory ||
    cat.toLowerCase() == normalizedCategory
  );
  
  if (!categoryExists && menuItem.category.isNotEmpty) {
    // Add the current category to the list if it's not already there
    categories.add(_formatCategoryForDisplay(menuItem.category));
  }
  
  emit(EditProductFormState(
    menuId: menuItem.menuId,
    name: menuItem.name,
    description: menuItem.description,
    category: menuItem.category,
    price: menuItem.price,
    isVeg: menuItem.isVeg,
    imageUrl: menuItem.imageUrl,
    categories: categories, // Pass the updated categories list
  ));
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
      emit(currentState.copyWith(category: event.category));
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
    
    if (currentState.category.isEmpty) {
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
        category: currentState.category,
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

// Define the _updateMenuItem method
Future<UpdateMenuItemResponse> _updateMenuItem({
  required String menuId,
  required String name,
  required String description,
  required String category,
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
    
    // Make sure to include available:true explicitly
    Map<String, dynamic> requestData = {
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'isVeg': isVeg.toString(),
      'available': 'true',  // Include this explicitly
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