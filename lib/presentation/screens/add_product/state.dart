// lib/presentation/screens/add_product/state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';

class ProductModel {
  final String name;
  final String description;
  final String category;
  final int? categoryId;
  final double price;
  final String tags;
  final File? image;
  final bool codAllowed;
  final bool taxIncluded;
  final bool isCancellable;

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
  });

  ProductModel copyWith({
    String? name,
    String? description,
    String? category,
    int? categoryId,
    double? price,
    String? tags,
    File? image,
    bool? codAllowed,
    bool? taxIncluded,
    bool? isCancellable,
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
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  
  const AddProductFormState({
    required this.product,
    this.categories = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });
  
  @override
  List<Object?> get props => [product, categories, isSubmitting, isSuccess, errorMessage];
  
  AddProductFormState copyWith({
    ProductModel? product,
    List<CategoryModel>? categories,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddProductFormState(
      product: product ?? this.product,
      categories: categories ?? this.categories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}