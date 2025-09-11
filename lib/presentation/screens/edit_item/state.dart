// lib/presentation/screens/edit_product/edit_product_state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';
import '../../../models/restaurant_menu_model.dart';
import '../../../models/food_type_model.dart';
import '../add_product/state.dart'; // Import timing schedule models

abstract class EditProductState extends Equatable {
  const EditProductState();
  
  @override
  List<Object?> get props => [];
}

class EditProductInitial extends EditProductState {}

class EditProductLoading extends EditProductState {}

class EditProductFormState extends EditProductState {
  final String menuId;
  final String name;
  final String description;
  final String category;
  final String? categoryId;
  final String price;
  final bool isVeg;
  final File? image;
  final String? imageUrl;
  final List<CategoryModel> categories;
  final List<FoodTypeModel> foodTypes;
  final FoodTypeModel? selectedFoodType;
  final bool isLoadingFoodTypes;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? timingError;
  final String? descriptionError;
  // New timing fields
  final bool timingEnabled;
  final TimingSchedule timingSchedule;
  final String timezone;
  
  EditProductFormState({
    required this.menuId,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId,
    required this.price,
    required this.isVeg,
    this.image,
    this.imageUrl,
    this.categories = const [],
    this.foodTypes = const [],
    this.selectedFoodType,
    this.isLoadingFoodTypes = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.timingEnabled = true,
    TimingSchedule? timingSchedule,
    this.timezone = 'Asia/Kolkata',
    this.timingError,
    this.descriptionError,
  }) : timingSchedule = timingSchedule ?? TimingSchedule.defaultSchedule();
  
  @override
  List<Object?> get props => [
    menuId,
    name,
    description,
    category,
    categoryId,
    price,
    isVeg,
    image,
    imageUrl,
    categories,
    foodTypes,
    selectedFoodType,
    isLoadingFoodTypes,
    isSubmitting,
    isSuccess,
    errorMessage,
    timingEnabled,
    timingSchedule,
    timezone,
    timingError,
    descriptionError,
  ];
  
  EditProductFormState copyWith({
    String? menuId,
    String? name,
    String? description,
    String? category,
    String? categoryId,
    String? price,
    bool? isVeg,
    File? image,
    String? imageUrl,
    List<CategoryModel>? categories,
    List<FoodTypeModel>? foodTypes,
    FoodTypeModel? selectedFoodType,
    bool? isLoadingFoodTypes,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool? timingEnabled,
    TimingSchedule? timingSchedule,
    String? timezone,
    String? timingError,
    String? descriptionError,
  }) {
    return EditProductFormState(
      menuId: menuId ?? this.menuId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      foodTypes: foodTypes ?? this.foodTypes,
      selectedFoodType: selectedFoodType ?? this.selectedFoodType,
      isLoadingFoodTypes: isLoadingFoodTypes ?? this.isLoadingFoodTypes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      timingEnabled: timingEnabled ?? this.timingEnabled,
      timingSchedule: timingSchedule ?? this.timingSchedule,
      timezone: timezone ?? this.timezone,
      timingError: timingError ?? this.timingError,
      descriptionError: descriptionError ?? this.descriptionError,
    );
  }
}

class EditProductError extends EditProductState {
  final String message;
  
  const EditProductError(this.message);
  
  @override
  List<Object?> get props => [message];
}