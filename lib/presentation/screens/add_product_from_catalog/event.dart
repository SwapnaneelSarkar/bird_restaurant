import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';
import '../../../models/subcategory_model.dart';
import '../../../models/product_selection_model.dart';

abstract class AddProductFromCatalogEvent extends Equatable {
  const AddProductFromCatalogEvent();

  @override
  List<Object?> get props => [];
}

class AddProductFromCatalogInitEvent extends AddProductFromCatalogEvent {
  const AddProductFromCatalogInitEvent();
}

class FetchCategoriesEvent extends AddProductFromCatalogEvent {
  const FetchCategoriesEvent();
}

class CategorySelectedEvent extends AddProductFromCatalogEvent {
  final CategoryModel category;

  const CategorySelectedEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class FetchSubcategoriesEvent extends AddProductFromCatalogEvent {
  final String categoryId;

  const FetchSubcategoriesEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SubcategorySelectedEvent extends AddProductFromCatalogEvent {
  final SubcategoryModel subcategory;

  const SubcategorySelectedEvent(this.subcategory);

  @override
  List<Object?> get props => [subcategory];
}

class FetchProductsEvent extends AddProductFromCatalogEvent {
  final String subcategoryId;

  const FetchProductsEvent(this.subcategoryId);

  @override
  List<Object?> get props => [subcategoryId];
}

class ProductSelectedEvent extends AddProductFromCatalogEvent {
  final ProductSelectionModel product;

  const ProductSelectedEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class QuantityChangedEvent extends AddProductFromCatalogEvent {
  final int quantity;

  const QuantityChangedEvent(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class PriceChangedEvent extends AddProductFromCatalogEvent {
  final double price;

  const PriceChangedEvent(this.price);

  @override
  List<Object?> get props => [price];
}

class ToggleAvailableEvent extends AddProductFromCatalogEvent {
  final bool available;

  const ToggleAvailableEvent(this.available);

  @override
  List<Object?> get props => [available];
}

class SubmitProductEvent extends AddProductFromCatalogEvent {
  const SubmitProductEvent();
}

class ResetFormEvent extends AddProductFromCatalogEvent {
  const ResetFormEvent();
}

class ValidateQuantityEvent extends AddProductFromCatalogEvent {
  final int quantity;

  const ValidateQuantityEvent(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class ValidatePriceEvent extends AddProductFromCatalogEvent {
  final double price;

  const ValidatePriceEvent(this.price);

  @override
  List<Object?> get props => [price];
}

class ValidateAllFieldsEvent extends AddProductFromCatalogEvent {
  const ValidateAllFieldsEvent();
} 