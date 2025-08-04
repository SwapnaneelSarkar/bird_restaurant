// lib/presentation/screens/edit_product/edit_product_event.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/restaurant_menu_model.dart';
import '../../../models/food_type_model.dart';

abstract class EditProductEvent extends Equatable {
  const EditProductEvent();
  
  @override
  List<Object?> get props => [];
}

class EditProductInitEvent extends EditProductEvent {
  final MenuItem menuItem;
  
  const EditProductInitEvent(this.menuItem);
  
  @override
  List<Object?> get props => [menuItem];
}

class ProductNameChangedEvent extends EditProductEvent {
  final String name;
  const ProductNameChangedEvent(this.name);
  
  @override
  List<Object?> get props => [name];
}

class ProductDescriptionChangedEvent extends EditProductEvent {
  final String description;
  const ProductDescriptionChangedEvent(this.description);
  
  @override
  List<Object?> get props => [description];
}

class ProductCategoryChangedEvent extends EditProductEvent {
  final String categoryName;
  final String categoryId;
  const ProductCategoryChangedEvent(this.categoryName, this.categoryId);
  
  @override
  List<Object?> get props => [categoryName, categoryId];
}

class ProductPriceChangedEvent extends EditProductEvent {
  final String price;
  const ProductPriceChangedEvent(this.price);
  
  @override
  List<Object?> get props => [price];
}

class ProductIsVegChangedEvent extends EditProductEvent {
  final bool isVeg;
  const ProductIsVegChangedEvent(this.isVeg);
  
  @override
  List<Object?> get props => [isVeg];
}

class ProductImageSelectedEvent extends EditProductEvent {
  final File image;
  const ProductImageSelectedEvent(this.image);
  
  @override
  List<Object?> get props => [image];
}

class FetchFoodTypesEvent extends EditProductEvent {
  final MenuItem? menuItem;
  const FetchFoodTypesEvent({this.menuItem});
  
  @override
  List<Object?> get props => [menuItem];
}

class FoodTypeChangedEvent extends EditProductEvent {
  final FoodTypeModel foodType;
  const FoodTypeChangedEvent(this.foodType);
  
  @override
  List<Object?> get props => [foodType];
}

// New timing schedule events
class ToggleTimingEnabledEvent extends EditProductEvent {
  final bool enabled;
  const ToggleTimingEnabledEvent(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

class UpdateDayScheduleEvent extends EditProductEvent {
  final String day;
  final bool enabled;
  final String start;
  final String end;
  
  const UpdateDayScheduleEvent({
    required this.day,
    required this.enabled,
    required this.start,
    required this.end,
  });
  
  @override
  List<Object?> get props => [day, enabled, start, end];
}

class UpdateTimezoneEvent extends EditProductEvent {
  final String timezone;
  const UpdateTimezoneEvent(this.timezone);
  
  @override
  List<Object?> get props => [timezone];
}

class SubmitEditProductEvent extends EditProductEvent {
  const SubmitEditProductEvent();
}