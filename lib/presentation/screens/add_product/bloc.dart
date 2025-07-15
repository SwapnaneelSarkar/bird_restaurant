// lib/presentation/screens/add_product/bloc.dart
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
import '../../../models/menu_item_model.dart';
import 'event.dart';
import 'state.dart';

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
    on<SubmitProductEvent>(_onSubmitProduct);
    on<ResetFormEvent>(_onResetForm);
  }

  void _onInitialize(AddProductInitEvent event, Emitter<AddProductState> emit) async {
    // Initially emit a state with an empty categories list
    debugPrint('BLoC: Emitting initial AddProductFormState (empty categories)');
    emit(AddProductFormState(
      product: ProductModel(),
      categories: [],
    ));
    
    try {
      // Fetch categories from API
      final categories = await _fetchCategories();
      debugPrint('BLoC: Emitting AddProductFormState (categories loaded, count: [32m${categories.length}[0m)');
      emit(AddProductFormState(
        product: ProductModel(),
        categories: categories,
      ));
    } catch (e) {
      debugPrint('BLoC: Emitting AddProductFormState (error: $e)');
      emit(AddProductFormState(
        product: ProductModel(),
        categories: [],
        errorMessage: 'Failed to load categories: ${e.toString()}',
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
    final url = Uri.parse('${ApiConstants.baseUrl}/partner/categories');
    
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

  void _onNameChanged(ProductNameChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(name: event.name),
      ));
    }
  }

  void _onDescriptionChanged(ProductDescriptionChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(description: event.description),
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
      emit(currentState.copyWith(
        product: currentState.product.copyWith(price: event.price),
      ));
    }
  }

  void _onTagsChanged(ProductTagsChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(tags: event.tags),
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

  void _onSubmitProduct(SubmitProductEvent event, Emitter<AddProductState> emit) async {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      
      // Validation
      if (currentState.product.name.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Product name is required'));
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
      
      if (currentState.product.image == null) {
        emit(currentState.copyWith(errorMessage: 'Please select a product image'));
        return;
      }
      
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
      ));
    }
  }
  
  Future<MenuItemResponse> _submitMenuItemToApi(ProductModel product) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      // Prepare API endpoint
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/menu_item');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields - include all required fields from the image
      request.fields['partner_id'] = partnerId;
      request.fields['name'] = product.name;
      request.fields['price'] = product.price.toString();
      request.fields['available'] = 'true'; // Default to true as requested
      request.fields['description'] = product.description;
      request.fields['category'] = product.categoryId ?? '';
      request.fields['isVeg'] = product.codAllowed.toString(); // Using codAllowed as isVeg for demo
      
      // Add new fields from the image
      request.fields['isTaxIncluded'] = product.taxIncluded.toString();
      request.fields['isCancellable'] = product.isCancellable.toString();
      
      // Add tags if available
      if (product.tags.isNotEmpty) {
        try {
          // Check if tags are in JSON format (like {"shahi", "paneer"})
          if (product.tags.startsWith('{') && product.tags.endsWith('}')) {
            request.fields['tags'] = product.tags;
          } else {
            // Convert comma-separated tags to JSON format
            final tagsList = product.tags.split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();
                
            // Format as {"tag1", "tag2"}
            request.fields['tags'] = '{${tagsList.map((tag) => '"$tag"').join(', ')}}';
          }
        } catch (e) {
          debugPrint('Error formatting tags: $e');
          // In case of error, send tags as is
          request.fields['tags'] = product.tags;
        }
      }
      
      // Add image file
      if (product.image != null && await product.image!.exists()) {
        final fileName = path.basename(product.image!.path);
        final extension = path.extension(fileName).toLowerCase();
        
        // Determine content type based on file extension
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
            product.image!.readAsBytes().asStream(),
            await product.image!.length(),
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
      }
      
      // Send request
      debugPrint('Sending menu item request to: $url');
      debugPrint('Request fields: ${request.fields}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return MenuItemResponse.fromJson(responseData);
      } else {
        // Handle error responses
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
    } catch (e) {
      debugPrint('Error submitting menu item: $e');
      return MenuItemResponse(
        status: 'ERROR',
        message: 'Error: ${e.toString()}',
      );
    }
  }
}