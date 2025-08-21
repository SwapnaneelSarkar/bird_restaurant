import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';
import '../../../models/catagory_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/product_selection_model.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';

class UpdateProductFromCatalogBloc extends Bloc<UpdateProductFromCatalogEvent, UpdateProductFromCatalogState> {
  UpdateProductFromCatalogBloc() : super(UpdateProductFromCatalogInitial()) {
    on<UpdateProductFromCatalogInitEvent>(_onInitialize);
    on<FetchCategoriesEvent>(_onFetchCategories);
    on<CategorySelectedEvent>(_onCategorySelected);
    on<FetchSubcategoriesEvent>(_onFetchSubcategories);
    on<SubcategorySelectedEvent>(_onSubcategorySelected);
    on<FetchProductsEvent>(_onFetchProducts);
    on<ProductSelectedEvent>(_onProductSelected);
    on<QuantityChangedEvent>(_onQuantityChanged);
    on<PriceChangedEvent>(_onPriceChanged);
    on<ToggleAvailableEvent>(_onToggleAvailable);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<ResetFormEvent>(_onResetForm);
    on<ValidateQuantityEvent>(_onValidateQuantity);
    on<ValidatePriceEvent>(_onValidatePrice);
    on<ValidateAllFieldsEvent>(_onValidateAllFields);
  }

  void _onInitialize(UpdateProductFromCatalogInitEvent event, Emitter<UpdateProductFromCatalogState> emit) async {
    emit(const UpdateProductFromCatalogFormState());
    add(const FetchCategoriesEvent());
  }

  void _onFetchCategories(FetchCategoriesEvent event, Emitter<UpdateProductFromCatalogState> emit) async {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(isLoadingCategories: true));
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token == null) {
          throw Exception('Authentication information not found. Please login again.');
        }
        
        final selectedSupercategoryId = await TokenService.getSupercategoryId();
        debugPrint('🔍 Update Product From Catalog - Supercategory ID: $selectedSupercategoryId');
        
        String urlString = '${ApiConstants.baseUrl}/partner/categories';
        if (selectedSupercategoryId != null && selectedSupercategoryId.isNotEmpty) {
          urlString += '?supercategory=$selectedSupercategoryId';
        }
        final url = Uri.parse(urlString);
        
        debugPrint('🔍 Update Product From Catalog - Categories API URL: $urlString');
        
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
            debugPrint('🔍 Update Product From Catalog - Fetched ${categories.length} categories');
            
            emit(currentState.copyWith(
              categories: categories,
              isLoadingCategories: false,
            ));
          } else {
            throw Exception(responseData['message'] ?? 'Failed to fetch categories');
          }
        } else {
          throw Exception('Failed to fetch categories. Status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching categories: $e');
        emit(currentState.copyWith(
          isLoadingCategories: false,
          errorMessage: 'Failed to fetch categories: ${e.toString()}',
        ));
      }
    }
  }

  void _onCategorySelected(CategorySelectedEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        selectedSubcategory: null,
        selectedProduct: null,
        subcategories: [],
        products: [],
      ));
      
      // Fetch subcategories for the selected category
      add(FetchSubcategoriesEvent(event.category.id));
    }
  }

  void _onFetchSubcategories(FetchSubcategoriesEvent event, Emitter<UpdateProductFromCatalogState> emit) async {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(isLoadingSubcategories: true));
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token == null) {
          throw Exception('Authentication information not found. Please login again.');
        }
        
        final url = Uri.parse('${ApiConstants.baseUrl}/products/subcategories/category/${event.categoryId}');
        
        debugPrint('🔍 Update Product From Catalog - Subcategories API URL: $url');
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        
        debugPrint('Subcategories response status: ${response.statusCode}');
        debugPrint('Subcategories response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          if (responseData['status'] == 'SUCCESS') {
            final List<dynamic> subcategoriesJson = responseData['data'];
            final subcategories = subcategoriesJson.map((json) => SubcategoryModel.fromJson(json)).toList();
            debugPrint('🔍 Update Product From Catalog - Fetched ${subcategories.length} subcategories');
            
            emit(currentState.copyWith(
              subcategories: subcategories,
              isLoadingSubcategories: false,
            ));
          } else {
            throw Exception(responseData['message'] ?? 'Failed to fetch subcategories');
          }
        } else {
          throw Exception('Failed to fetch subcategories. Status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching subcategories: $e');
        emit(currentState.copyWith(
          isLoadingSubcategories: false,
          errorMessage: 'Failed to fetch subcategories: ${e.toString()}',
        ));
      }
    }
  }

  void _onSubcategorySelected(SubcategorySelectedEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(
        selectedSubcategory: event.subcategory,
        selectedProduct: null,
        products: [],
      ));
      
      // Fetch products for the selected subcategory
      add(FetchProductsEvent(event.subcategory.id));
    }
  }

  void _onFetchProducts(FetchProductsEvent event, Emitter<UpdateProductFromCatalogState> emit) async {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(isLoadingProducts: true));
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token == null) {
          throw Exception('Authentication information not found. Please login again.');
        }
        
        final url = Uri.parse('${ApiConstants.baseUrl}/partner/subcategory/${event.subcategoryId}/products');
        
        debugPrint('🔍 Update Product From Catalog - Products API URL: $url');
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        
        debugPrint('Products response status: ${response.statusCode}');
        debugPrint('Products response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          if (responseData['status'] == 'SUCCESS') {
            final List<dynamic> productsJson = responseData['data'];
            final products = productsJson.map((json) => ProductSelectionModel.fromJson(json)).toList();
            debugPrint('🔍 Update Product From Catalog - Fetched ${products.length} products');
            
            emit(currentState.copyWith(
              products: products,
              isLoadingProducts: false,
            ));
          } else {
            throw Exception(responseData['message'] ?? 'Failed to fetch products');
          }
        } else {
          throw Exception('Failed to fetch products. Status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching products: $e');
        emit(currentState.copyWith(
          isLoadingProducts: false,
          errorMessage: 'Failed to fetch products: ${e.toString()}',
        ));
      }
    }
  }

  void _onProductSelected(ProductSelectedEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(
        selectedProduct: event.product,
      ));
    }
  }

  void _onQuantityChanged(QuantityChangedEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      String? quantityError = currentState.quantityError;
      
      // Clear error if field becomes valid
      if (event.quantity > 0) {
        quantityError = null;
      }
      
      emit(currentState.copyWith(
        quantity: event.quantity,
        quantityError: quantityError,
      ));
    }
  }

  void _onPriceChanged(PriceChangedEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      String? priceError = currentState.priceError;
      
      // Clear error if field becomes valid
      if (event.price > 0) {
        priceError = null;
      }
      
      emit(currentState.copyWith(
        price: event.price,
        priceError: priceError,
      ));
    }
  }

  void _onToggleAvailable(ToggleAvailableEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(
        available: event.available,
      ));
    }
  }

  void _onUpdateProduct(UpdateProductEvent event, Emitter<UpdateProductFromCatalogState> emit) async {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      
      // Validation
      if (currentState.selectedProduct == null) {
        emit(currentState.copyWith(errorMessage: 'Please select a product'));
        return;
      }
      
      if (currentState.quantity <= 0) {
        emit(currentState.copyWith(errorMessage: 'Please enter a valid quantity'));
        return;
      }
      
      if (currentState.price <= 0) {
        emit(currentState.copyWith(errorMessage: 'Please enter a valid price'));
        return;
      }
      
      // Start submission
      emit(currentState.copyWith(isSubmitting: true, errorMessage: null));
      
      try {
        final result = await _updateProductToApi(
          currentState.selectedProduct!.productId,
          currentState.quantity,
          currentState.price,
          currentState.available,
        );
        
        if (result['status'] == 'SUCCESS') {
          // Success
          emit(currentState.copyWith(isSubmitting: false, isSuccess: true));
        } else {
          // API returned an error
          emit(currentState.copyWith(
            isSubmitting: false,
            errorMessage: result['message'] ?? 'Failed to update product',
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

  Future<Map<String, dynamic>> _updateProductToApi(
    String productId,
    int quantity,
    double price,
    bool available,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final partnerId = prefs.getString('user_id');
      
      if (token == null || partnerId == null) {
        throw Exception('Authentication information not found. Please login again.');
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/update-product');
      
      final body = {
        'partner_id': partnerId,
        'product_id': productId,
        'quantity': quantity,
        'price': price,
        'available': available,
      };
      
      debugPrint('Sending update product request to: $url');
      debugPrint('Request body: ${json.encode(body)}');
      
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'status': 'ERROR',
            'message': errorData['message'] ?? 'Failed to update product',
          };
        } catch (e) {
          return {
            'status': 'ERROR',
            'message': 'Failed to update product. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      return {
        'status': 'ERROR',
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  void _onResetForm(ResetFormEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      emit(currentState.copyWith(
        selectedCategory: null,
        selectedSubcategory: null,
        selectedProduct: null,
        subcategories: [],
        products: [],
        quantity: 1,
        price: 0.0,
        available: true,
        errorMessage: null,
        isSuccess: false,
        quantityError: null,
        priceError: null,
      ));
    }
  }

  void _onValidateQuantity(ValidateQuantityEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      String? quantityError;
      
      if (event.quantity <= 0) {
        quantityError = 'Quantity must be greater than 0';
      }
      
      emit(currentState.copyWith(quantityError: quantityError));
    }
  }

  void _onValidatePrice(ValidatePriceEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      String? priceError;
      
      if (event.price <= 0) {
        priceError = 'Price must be greater than 0';
      }
      
      emit(currentState.copyWith(priceError: priceError));
    }
  }

  void _onValidateAllFields(ValidateAllFieldsEvent event, Emitter<UpdateProductFromCatalogState> emit) {
    if (state is UpdateProductFromCatalogFormState) {
      final currentState = state as UpdateProductFromCatalogFormState;
      
      // Validate quantity
      String? quantityError;
      if (currentState.quantity <= 0) {
        quantityError = 'Quantity must be greater than 0';
      }
      
      // Validate price
      String? priceError;
      if (currentState.price <= 0) {
        priceError = 'Price must be greater than 0';
      }
      
      emit(currentState.copyWith(
        quantityError: quantityError,
        priceError: priceError,
      ));
    }
  }
} 