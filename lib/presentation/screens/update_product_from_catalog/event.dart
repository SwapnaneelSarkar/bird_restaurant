import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/product_selection_model.dart';

abstract class UpdateProductFromCatalogEvent extends Equatable {
  const UpdateProductFromCatalogEvent();

  @override
  List<Object?> get props => [];
}

class UpdateProductFromCatalogInitEvent extends UpdateProductFromCatalogEvent {
  const UpdateProductFromCatalogInitEvent();
}

class FetchCategoriesEvent extends UpdateProductFromCatalogEvent {
  const FetchCategoriesEvent();
}

class CategorySelectedEvent extends UpdateProductFromCatalogEvent {
  final CategoryModel category;

  const CategorySelectedEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class FetchSubcategoriesEvent extends UpdateProductFromCatalogEvent {
  final String categoryId;

  const FetchSubcategoriesEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SubcategorySelectedEvent extends UpdateProductFromCatalogEvent {
  final SubcategoryModel subcategory;

  const SubcategorySelectedEvent(this.subcategory);

  @override
  List<Object?> get props => [subcategory];
}

class FetchProductsEvent extends UpdateProductFromCatalogEvent {
  final String subcategoryId;

  const FetchProductsEvent(this.subcategoryId);

  @override
  List<Object?> get props => [subcategoryId];
}

class ProductSelectedEvent extends UpdateProductFromCatalogEvent {
  final ProductSelectionModel product;

  const ProductSelectedEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class QuantityChangedEvent extends UpdateProductFromCatalogEvent {
  final int quantity;

  const QuantityChangedEvent(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class PriceChangedEvent extends UpdateProductFromCatalogEvent {
  final double price;

  const PriceChangedEvent(this.price);

  @override
  List<Object?> get props => [price];
}

class ToggleAvailableEvent extends UpdateProductFromCatalogEvent {
  final bool available;

  const ToggleAvailableEvent(this.available);

  @override
  List<Object?> get props => [available];
}

class UpdateProductEvent extends UpdateProductFromCatalogEvent {
  const UpdateProductEvent();
}

class ResetFormEvent extends UpdateProductFromCatalogEvent {
  const ResetFormEvent();
}

class ValidateQuantityEvent extends UpdateProductFromCatalogEvent {
  final int quantity;

  const ValidateQuantityEvent(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class ValidatePriceEvent extends UpdateProductFromCatalogEvent {
  final double price;

  const ValidatePriceEvent(this.price);

  @override
  List<Object?> get props => [price];
}

class ValidateAllFieldsEvent extends UpdateProductFromCatalogEvent {
  const ValidateAllFieldsEvent();
} 