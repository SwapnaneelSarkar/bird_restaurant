// lib/presentation/screens/add_product/state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/catagory_model.dart';
import '../../../models/food_type_model.dart';

// Timing schedule model for each day
class DaySchedule {
  final bool enabled;
  final String start;
  final String end;

  DaySchedule({
    required this.enabled,
    required this.start,
    required this.end,
  });

  DaySchedule copyWith({
    bool? enabled,
    String? start,
    String? end,
  }) {
    return DaySchedule(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'start': start,
      'end': end,
    };
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      enabled: _convertToBool(json['enabled']),
      start: json['start'] ?? '09:00',
      end: json['end'] ?? '22:00',
    );
  }

  // Helper method to safely convert various types to bool
  static bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0; // 0 = false, any other int = true
    if (value is String) {
      // Try parsing as int first
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue != 0;
      
      // Try parsing as bool string
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1';
    }
    return false; // Default to false for unexpected types
  }
}

// Weekly timing schedule
class TimingSchedule {
  final DaySchedule monday;
  final DaySchedule tuesday;
  final DaySchedule wednesday;
  final DaySchedule thursday;
  final DaySchedule friday;
  final DaySchedule saturday;
  final DaySchedule sunday;

  TimingSchedule({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  TimingSchedule copyWith({
    DaySchedule? monday,
    DaySchedule? tuesday,
    DaySchedule? wednesday,
    DaySchedule? thursday,
    DaySchedule? friday,
    DaySchedule? saturday,
    DaySchedule? sunday,
  }) {
    return TimingSchedule(
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }

  factory TimingSchedule.fromJson(Map<String, dynamic> json) {
    return TimingSchedule(
      monday: DaySchedule.fromJson(json['monday'] ?? {}),
      tuesday: DaySchedule.fromJson(json['tuesday'] ?? {}),
      wednesday: DaySchedule.fromJson(json['wednesday'] ?? {}),
      thursday: DaySchedule.fromJson(json['thursday'] ?? {}),
      friday: DaySchedule.fromJson(json['friday'] ?? {}),
      saturday: DaySchedule.fromJson(json['saturday'] ?? {}),
      sunday: DaySchedule.fromJson(json['sunday'] ?? {}),
    );
  }

  // Default timing schedule
  factory TimingSchedule.defaultSchedule() {
    final defaultDay = DaySchedule(enabled: true, start: '09:00', end: '22:00');
    return TimingSchedule(
      monday: defaultDay,
      tuesday: defaultDay,
      wednesday: defaultDay,
      thursday: defaultDay,
      friday: defaultDay,
      saturday: defaultDay,
      sunday: DaySchedule(enabled: false, start: '09:00', end: '22:00'),
    );
  }
}

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
  final String? availableFromTime;
  final String? availableToTime;
  final bool isAvailableAllDay;
  // New timing fields
  final bool timingEnabled;
  final TimingSchedule timingSchedule;
  final String timezone;

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
    this.availableFromTime,
    this.availableToTime,
    this.isAvailableAllDay = true,
    this.timingEnabled = true,
    TimingSchedule? timingSchedule,
    this.timezone = 'Asia/Kolkata',
  }) : timingSchedule = timingSchedule ?? TimingSchedule.defaultSchedule();

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
    String? availableFromTime,
    String? availableToTime,
    bool? isAvailableAllDay,
    bool? timingEnabled,
    TimingSchedule? timingSchedule,
    String? timezone,
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
      availableFromTime: availableFromTime ?? this.availableFromTime,
      availableToTime: availableToTime ?? this.availableToTime,
      isAvailableAllDay: isAvailableAllDay ?? this.isAvailableAllDay,
      timingEnabled: timingEnabled ?? this.timingEnabled,
      timingSchedule: timingSchedule ?? this.timingSchedule,
      timezone: timezone ?? this.timezone,
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
  // Validation error fields
  final String? nameError;
  final String? descriptionError;
  final String? priceError;
  final String? tagsError;
  
  const AddProductFormState({
    required this.product,
    this.categories = const [],
    this.foodTypes = const [],
    this.selectedFoodType,
    this.isLoadingFoodTypes = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.nameError,
    this.descriptionError,
    this.priceError,
    this.tagsError,
  });
  
  @override
  List<Object?> get props => [product, categories, foodTypes, selectedFoodType, isLoadingFoodTypes, isSubmitting, isSuccess, errorMessage, nameError, descriptionError, priceError, tagsError];
  
  AddProductFormState copyWith({
    ProductModel? product,
    List<CategoryModel>? categories,
    List<FoodTypeModel>? foodTypes,
    FoodTypeModel? selectedFoodType,
    bool? isLoadingFoodTypes,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? nameError,
    String? descriptionError,
    String? priceError,
    String? tagsError,
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
      nameError: nameError,
      descriptionError: descriptionError,
      priceError: priceError,
      tagsError: tagsError,
    );
  }
}