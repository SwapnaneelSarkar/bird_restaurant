// lib/presentation/screens/edit_product/edit_product_state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';

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
  final String price;
  final bool isVeg;
  final File? image;
  final String? imageUrl;
  final List<String> categories;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  
  const EditProductFormState({
    required this.menuId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.isVeg,
    this.image,
    this.imageUrl,
    this.categories = const ['Food', 'Beverages', 'Desserts', 'Snacks', 'Appetizers', 'Main Course'],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });
  
  @override
  List<Object?> get props => [
    menuId, name, description, category, price, isVeg, 
    image, imageUrl, categories, isSubmitting, isSuccess, errorMessage
  ];
  
  EditProductFormState copyWith({
    String? menuId,
    String? name,
    String? description,
    String? category,
    String? price,
    bool? isVeg,
    File? image,
    String? imageUrl,
    List<String>? categories,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return EditProductFormState(
      menuId: menuId ?? this.menuId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class EditProductError extends EditProductState {
  final String message;
  
  const EditProductError(this.message);
  
  @override
  List<Object?> get props => [message];
}