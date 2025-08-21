import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../models/catagory_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/product_selection_model.dart';

abstract class UpdateProductFromCatalogState extends Equatable {
  const UpdateProductFromCatalogState();
  
  @override
  List<Object?> get props => [];
}

class UpdateProductFromCatalogInitial extends UpdateProductFromCatalogState {}

class UpdateProductFromCatalogFormState extends UpdateProductFromCatalogState {
  final List<CategoryModel> categories;
  final List<SubcategoryModel> subcategories;
  final List<ProductSelectionModel> products;
  final CategoryModel? selectedCategory;
  final SubcategoryModel? selectedSubcategory;
  final ProductSelectionModel? selectedProduct;
  final int quantity;
  final double price;
  final bool available;
  final bool isLoadingCategories;
  final bool isLoadingSubcategories;
  final bool isLoadingProducts;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? quantityError;
  final String? priceError;

  const UpdateProductFromCatalogFormState({
    this.categories = const [],
    this.subcategories = const [],
    this.products = const [],
    this.selectedCategory,
    this.selectedSubcategory,
    this.selectedProduct,
    this.quantity = 1,
    this.price = 0.0,
    this.available = true,
    this.isLoadingCategories = false,
    this.isLoadingSubcategories = false,
    this.isLoadingProducts = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.quantityError,
    this.priceError,
  });

  UpdateProductFromCatalogFormState copyWith({
    List<CategoryModel>? categories,
    List<SubcategoryModel>? subcategories,
    List<ProductSelectionModel>? products,
    CategoryModel? selectedCategory,
    SubcategoryModel? selectedSubcategory,
    ProductSelectionModel? selectedProduct,
    int? quantity,
    double? price,
    bool? available,
    bool? isLoadingCategories,
    bool? isLoadingSubcategories,
    bool? isLoadingProducts,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? quantityError,
    String? priceError,
  }) {
    return UpdateProductFromCatalogFormState(
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
      products: products ?? this.products,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubcategory: selectedSubcategory ?? this.selectedSubcategory,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      available: available ?? this.available,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingSubcategories: isLoadingSubcategories ?? this.isLoadingSubcategories,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      quantityError: quantityError,
      priceError: priceError,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    subcategories,
    products,
    selectedCategory,
    selectedSubcategory,
    selectedProduct,
    quantity,
    price,
    available,
    isLoadingCategories,
    isLoadingSubcategories,
    isLoadingProducts,
    isSubmitting,
    isSuccess,
    errorMessage,
    quantityError,
    priceError,
  ];
} 