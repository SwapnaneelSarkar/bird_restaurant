import 'package:equatable/equatable.dart';
import '../../../models/supercategory_model.dart';

abstract class RestaurantDetailsEvent extends Equatable {
  const RestaurantDetailsEvent();
  @override
  List<Object?> get props => [];
}

class RestaurantNameChanged extends RestaurantDetailsEvent {
  final String name;
  const RestaurantNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class AddressChanged extends RestaurantDetailsEvent {
  final String address;
  const AddressChanged(this.address);
  @override
  List<Object?> get props => [address];
}

class PhoneNumberChanged extends RestaurantDetailsEvent {
  final String phoneNumber;
  const PhoneNumberChanged(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class EmailChanged extends RestaurantDetailsEvent {
  final String email;
  const EmailChanged(this.email);
  @override
  List<Object?> get props => [email];
}

class UseCurrentLocationPressed extends RestaurantDetailsEvent {}

// UI: reset enable-location prompt flag after dialog handled
class DismissEnableLocationPrompt extends RestaurantDetailsEvent {}

class LocationSelected extends RestaurantDetailsEvent {
  final String address;
  final double latitude;
  final double longitude;
  
  const LocationSelected({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [address, latitude, longitude];
}

class NextPressed extends RestaurantDetailsEvent {}

class LoadSavedDataEvent extends RestaurantDetailsEvent {}

// New events for supercategory
class FetchSupercategoriesEvent extends RestaurantDetailsEvent {}

class SupercategoryChanged extends RestaurantDetailsEvent {
  final SupercategoryModel supercategory;
  const SupercategoryChanged(this.supercategory);
  @override
  List<Object?> get props => [supercategory];
}

// New events for restaurant type
class FetchRestaurantTypesEvent extends RestaurantDetailsEvent {}

class RestaurantTypeChanged extends RestaurantDetailsEvent {
  final Map<String, dynamic> restaurantType;
  const RestaurantTypeChanged(this.restaurantType);
  @override
  List<Object?> get props => [restaurantType];
}

