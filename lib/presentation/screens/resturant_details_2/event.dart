
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../constants/enums.dart';
import 'state.dart';

abstract class RestaurantCategoryEvent extends Equatable {
  const RestaurantCategoryEvent();
  @override
  List<Object?> get props => [];
}

class ToggleCuisineEvent extends RestaurantCategoryEvent {
  final CuisineType type;
  const ToggleCuisineEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class ToggleDayEnabledEvent extends RestaurantCategoryEvent {
  final int dayIndex;
  const ToggleDayEnabledEvent(this.dayIndex);
  @override
  List<Object?> get props => [dayIndex];
}

class UpdateStartTimeEvent extends RestaurantCategoryEvent {
  final int dayIndex;
  final TimeOfDay time;
  const UpdateStartTimeEvent(this.dayIndex, this.time);
  @override
  List<Object?> get props => [dayIndex, time];
}

class UpdateEndTimeEvent extends RestaurantCategoryEvent {
  final int dayIndex;
  final TimeOfDay time;
  const UpdateEndTimeEvent(this.dayIndex, this.time);
  @override
  List<Object?> get props => [dayIndex, time];
}

// Add this new event
class LoadSavedDataEvent extends RestaurantCategoryEvent {}