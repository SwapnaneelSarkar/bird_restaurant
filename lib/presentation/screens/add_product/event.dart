
// lib/presentation/screens/add_product/event.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/food_type_model.dart';

abstract class AddProductEvent extends Equatable {
  const AddProductEvent();
  
  @override
  List<Object?> get props => [];
}

class AddProductInitEvent extends AddProductEvent {}

class ProductNameChangedEvent extends AddProductEvent {
  final String name;
  const ProductNameChangedEvent(this.name);
  
  @override
  List<Object?> get props => [name];
}

class ProductDescriptionChangedEvent extends AddProductEvent {
  final String description;
  const ProductDescriptionChangedEvent(this.description);
  
  @override
  List<Object?> get props => [description];
}

class ProductCategoryChangedEvent extends AddProductEvent {
  final String categoryName;
  final String categoryId;
  
  const ProductCategoryChangedEvent(this.categoryName, this.categoryId);
  
  @override
  List<Object?> get props => [categoryName, categoryId];
}

class ProductPriceChangedEvent extends AddProductEvent {
  final double price;
  const ProductPriceChangedEvent(this.price);
  
  @override
  List<Object?> get props => [price];
}

class ProductTagsChangedEvent extends AddProductEvent {
  final String tags;
  const ProductTagsChangedEvent(this.tags);
  
  @override
  List<Object?> get props => [tags];
}

class ProductImageSelectedEvent extends AddProductEvent {
  final File image;
  const ProductImageSelectedEvent(this.image);
  
  @override
  List<Object?> get props => [image];
}

class ToggleCodAllowedEvent extends AddProductEvent {
  final bool isAllowed;
  const ToggleCodAllowedEvent(this.isAllowed);
  
  @override
  List<Object?> get props => [isAllowed];
}

class ToggleTaxIncludedEvent extends AddProductEvent {
  final bool isIncluded;
  const ToggleTaxIncludedEvent(this.isIncluded);
  
  @override
  List<Object?> get props => [isIncluded];
}

class ToggleCancellableEvent extends AddProductEvent {
  final bool isCancellable;
  const ToggleCancellableEvent(this.isCancellable);
  
  @override
  List<Object?> get props => [isCancellable];
}

class FetchFoodTypesEvent extends AddProductEvent {
  const FetchFoodTypesEvent();
}

class FoodTypeChangedEvent extends AddProductEvent {
  final FoodTypeModel foodType;
  const FoodTypeChangedEvent(this.foodType);
  
  @override
  List<Object?> get props => [foodType];
}

class ToggleAvailableAllDayEvent extends AddProductEvent {
  final bool isAvailableAllDay;
  const ToggleAvailableAllDayEvent(this.isAvailableAllDay);
  
  @override
  List<Object?> get props => [isAvailableAllDay];
}

class AvailableFromTimeChangedEvent extends AddProductEvent {
  final String time;
  const AvailableFromTimeChangedEvent(this.time);
  
  @override
  List<Object?> get props => [time];
}

class AvailableToTimeChangedEvent extends AddProductEvent {
  final String time;
  const AvailableToTimeChangedEvent(this.time);
  
  @override
  List<Object?> get props => [time];
}

// New timing schedule events
class ToggleTimingEnabledEvent extends AddProductEvent {
  final bool enabled;
  const ToggleTimingEnabledEvent(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

class UpdateDayScheduleEvent extends AddProductEvent {
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

class UpdateTimezoneEvent extends AddProductEvent {
  final String timezone;
  const UpdateTimezoneEvent(this.timezone);
  
  @override
  List<Object?> get props => [timezone];
}

class SubmitProductEvent extends AddProductEvent {
  const SubmitProductEvent();
}

class ResetFormEvent extends AddProductEvent {
  const ResetFormEvent();
}
