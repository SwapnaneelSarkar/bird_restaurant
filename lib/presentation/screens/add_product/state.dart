// lib/presentation/screens/add_product/state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';
import '../../../models/food_type_model.dart';

class ProductModel {
  final String name;
  final String description;
  final String category;
  final String? categoryId;
  final double price;
  final String tags;
  final File? image;
  final bool codAllowed;
  final bool taxIncluded;
  final bool isCancellable;
  final String? restaurantFoodTypeId;

  ProductModel({
    this.name = '',
    this.description = '',
    this.category = '',
    this.categoryId,
    this.price = 0.0,
    this.tags = '',
    this.image,
    this.codAllowed = false,
    this.taxIncluded = false,
    this.isCancellable = false,
    this.restaurantFoodTypeId,
  });

  ProductModel copyWith({
    String? name,
    String? description,
    String? category,
    String? categoryId,
    double? price,
    String? tags,
    File? image,
    bool? codAllowed,
    bool? taxIncluded,
    bool? isCancellable,
    String? restaurantFoodTypeId,
  }) {
    return ProductModel(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      image: image ?? this.image,
      codAllowed: codAllowed ?? this.codAllowed,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      isCancellable: isCancellable ?? this.isCancellable,
      restaurantFoodTypeId: restaurantFoodTypeId ?? this.restaurantFoodTypeId,
    );
  }
}

abstract class AddProductState extends Equatable {
  const AddProductState();
  
  @override
  List<Object?> get props => [];
}

class AddProductInitial extends AddProductState {}

class AddProductFormState extends AddProductState {
  final ProductModel product;
  final List<CategoryModel> categories;
  final List<FoodTypeModel> foodTypes;
  final FoodTypeModel? selectedFoodType;
  final bool isLoadingFoodTypes;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  
  const AddProductFormState({
    required this.product,
    this.categories = const [],
    this.foodTypes = const [],
    this.selectedFoodType,
    this.isLoadingFoodTypes = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });
  
  @override
  List<Object?> get props => [product, categories, foodTypes, selectedFoodType, isLoadingFoodTypes, isSubmitting, isSuccess, errorMessage];
  
  AddProductFormState copyWith({
    ProductModel? product,
    List<CategoryModel>? categories,
    List<FoodTypeModel>? foodTypes,
    FoodTypeModel? selectedFoodType,
    bool? isLoadingFoodTypes,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddProductFormState(
      product: product ?? this.product,
      categories: categories ?? this.categories,
      foodTypes: foodTypes ?? this.foodTypes,
      selectedFoodType: selectedFoodType ?? this.selectedFoodType,
      isLoadingFoodTypes: isLoadingFoodTypes ?? this.isLoadingFoodTypes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}