// lib/presentation/screens/restaurant_details/category/state.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../constants/enums.dart';


extension CuisineTypeExtension on CuisineType {
  String get label {
    switch (this) {
      case CuisineType.bakery:
        return 'Bakery';
      case CuisineType.italian:
        return 'Italian';
      case CuisineType.chinese:
        return 'Chinese';
      case CuisineType.indian:
        return 'Indian';
      case CuisineType.mexican:
        return 'Mexican';
      case CuisineType.japanese:
        return 'Japanese';
      case CuisineType.thai:
        return 'Thai';
      case CuisineType.american:
        return 'American';
      case CuisineType.french:
        return 'French';
      case CuisineType.mediterranean:
        return 'Mediterranean';
      case CuisineType.korean:
        return 'Korean';
      case CuisineType.vietnamese:
        return 'Vietnamese';
    }
  }

  // Add the icon getter
  IconData get icon {
    switch (this) {
      case CuisineType.bakery:
        return Icons.bakery_dining;
      case CuisineType.italian:
        return Icons.local_pizza;
      case CuisineType.chinese:
        return Icons.rice_bowl;
      case CuisineType.indian:
        return Icons.restaurant;
      case CuisineType.mexican:
        return Icons.local_dining;
      case CuisineType.japanese:
        return Icons.ramen_dining;
      case CuisineType.thai:
        return Icons.soup_kitchen;
      case CuisineType.american:
        return Icons.fastfood;
      case CuisineType.french:
        return Icons.wine_bar;
      case CuisineType.mediterranean:
        return Icons.kebab_dining;
      case CuisineType.korean:
        return Icons.set_meal;
      case CuisineType.vietnamese:
        return Icons.dinner_dining;
    }
  }

  String get imagePath {
    // Add appropriate image paths for each cuisine type
    switch (this) {
      case CuisineType.bakery:
        return 'assets/images/bakery.png';
      case CuisineType.italian:
        return 'assets/images/italian.png';
      // ... add paths for other cuisine types
      default:
        return 'assets/images/default_cuisine.png';
    }
  }
}

class OperationalDay extends Equatable {
  final String label;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const OperationalDay({
    required this.label,
    required this.enabled,
    required this.start,
    required this.end,
  });

  OperationalDay copyWith({
    String? label,
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return OperationalDay(
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  List<Object?> get props => [label, enabled, start, end];
}

class RestaurantCategoryState extends Equatable {
  final List<CuisineType> selected;
  final List<OperationalDay> days;
  final String? selectedSupercategoryId;
  final String? selectedSupercategoryName;

  const RestaurantCategoryState({
    this.selected = const [],
    required this.days,
    this.selectedSupercategoryId,
    this.selectedSupercategoryName,
  });

  factory RestaurantCategoryState.initial() {
    return RestaurantCategoryState(
      selected: [],
      days: [
        const OperationalDay(
          label: 'Sunday', 
          enabled: false,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Monday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Tuesday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Wednesday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Thursday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Friday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
        const OperationalDay(
          label: 'Saturday', 
          enabled: true,
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
      ],
      selectedSupercategoryId: null,
      selectedSupercategoryName: null,
    );
  }

  bool get canProceed {
    // Require at least one operational day enabled for all supercategories
    final hasAtLeastOneEnabledDay = days.any((day) => day.enabled);

    // If supercategory is Food (ID: "7acc47a2fa5a4eeb906a753b3"), also require at least one cuisine
    if (selectedSupercategoryId == "7acc47a2fa5a4eeb906a753b3") {
      return selected.isNotEmpty && hasAtLeastOneEnabledDay;
    }

    // For other supercategories, only require at least one operational day
    return hasAtLeastOneEnabledDay;
  }

  bool get shouldShowCuisineTypes {
    return selectedSupercategoryId == "7acc47a2fa5a4eeb906a753b3";
  }

  RestaurantCategoryState copyWith({
    List<CuisineType>? selected,
    List<OperationalDay>? days,
    String? selectedSupercategoryId,
    String? selectedSupercategoryName,
  }) {
    return RestaurantCategoryState(
      selected: selected ?? this.selected,
      days: days ?? this.days,
      selectedSupercategoryId: selectedSupercategoryId ?? this.selectedSupercategoryId,
      selectedSupercategoryName: selectedSupercategoryName ?? this.selectedSupercategoryName,
    );
  }

  @override
  List<Object?> get props => [selected, days, selectedSupercategoryId, selectedSupercategoryName];
}