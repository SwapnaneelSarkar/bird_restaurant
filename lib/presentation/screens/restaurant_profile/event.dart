import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// ─── EVENTS ─────────────────────────────────────────────────────────────
abstract class RestaurantProfileEvent extends Equatable {
  const RestaurantProfileEvent();
  @override
  List<Object?> get props => [];
}

// image
class SelectImagePressed extends RestaurantProfileEvent {}

// owner
class OwnerNameChanged extends RestaurantProfileEvent {
  final String value;
  const OwnerNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class OwnerMobileChanged   extends RestaurantProfileEvent { final String v; const OwnerMobileChanged(this.v); @override List<Object?> get props => [v]; }
class OwnerEmailChanged    extends RestaurantProfileEvent { final String v; const OwnerEmailChanged(this.v); @override List<Object?> get props => [v]; }
class OwnerAddressChanged  extends RestaurantProfileEvent { final String v; const OwnerAddressChanged(this.v); @override List<Object?> get props => [v]; }

// restaurant
class RestaurantNameChanged extends RestaurantProfileEvent {
  final String value;
  const RestaurantNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class DescriptionChanged   extends RestaurantProfileEvent { final String v; const DescriptionChanged(this.v); @override List<Object?> get props => [v]; }
class CookingTimeChanged   extends RestaurantProfileEvent { final String v; const CookingTimeChanged(this.v); @override List<Object?> get props => [v]; }
class DeliveryRadiusChanged extends RestaurantProfileEvent { final String v; const DeliveryRadiusChanged(this.v); @override List<Object?> get props => [v]; }

// location
class LatitudeChanged   extends RestaurantProfileEvent { final String v; const LatitudeChanged(this.v); @override List<Object?> get props => [v]; }
class LongitudeChanged  extends RestaurantProfileEvent { final String v; const LongitudeChanged(this.v); @override List<Object?> get props => [v]; }

// restaurant type
class LoadRestaurantTypesEvent extends RestaurantProfileEvent {}
class RestaurantTypeChanged extends RestaurantProfileEvent {
  final Map<String, dynamic> restaurantType;
  const RestaurantTypeChanged(this.restaurantType);
  @override
  List<Object?> get props => [restaurantType];
}

// type
enum RestaurantType { veg, nonVeg }
class TypeChanged extends RestaurantProfileEvent {
  final RestaurantType type;
  const TypeChanged(this.type);
  @override
  List<Object?> get props => [type];
}

// working hours
class ToggleDayEnabledEvent extends RestaurantProfileEvent {
  final int index;
  const ToggleDayEnabledEvent(this.index);
  @override
  List<Object?> get props => [index];
}
class UpdateStartTimeEvent extends RestaurantProfileEvent {
  final int index;
  final TimeOfDay time;
  const UpdateStartTimeEvent(this.index, this.time);
  @override
  List<Object?> get props => [index, time];
}
class UpdateEndTimeEvent extends RestaurantProfileEvent {
  final int index;
  final TimeOfDay time;
  const UpdateEndTimeEvent(this.index, this.time);
  @override
  List<Object?> get props => [index, time];
}

// buttons
class ChangePasswordPressed extends RestaurantProfileEvent {
  const ChangePasswordPressed();
}
class UpdateProfilePressed extends RestaurantProfileEvent {
  const UpdateProfilePressed();
}
class LoadInitialData extends RestaurantProfileEvent {}

// Add at the end of the file, after all other event classes
class ClearSubmissionMessage extends RestaurantProfileEvent {}