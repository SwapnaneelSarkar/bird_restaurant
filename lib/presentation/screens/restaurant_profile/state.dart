import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../resturant_details_2/state.dart';
import 'event.dart';

class RestaurantProfileState extends Equatable {
  // Image
  final String? imagePath;
  final String? restaurantImageUrl; // For loading from API

  // Owner
  final String ownerName;
  final String ownerMobile;
  final String ownerEmail;
  final String ownerAddress;

  // Restaurant
  final String restaurantName;
  final String description;
  final String cookingTime;

  // Location
  final String latitude;
  final String longitude;

  // Restaurant Type
  final List<Map<String, dynamic>> restaurantTypes;
  final Map<String, dynamic>? selectedRestaurantType;
  final bool isLoadingRestaurantTypes;

  // Type
  final RestaurantType type;

  // Working hours
  final List<OperationalDay> hours;

  // Load state
  final bool isLoading;

  // Submission state
  final bool isSubmitting;
  final bool submissionSuccess;
  final String? submissionMessage;
  final String? errorMessage;

  const RestaurantProfileState({
    this.imagePath,
    this.restaurantImageUrl,
    this.ownerName = '',
    this.ownerMobile = '',
    this.ownerEmail = '',
    this.ownerAddress = '',
    this.restaurantName = '',
    this.description = '',
    this.cookingTime = '',
    this.latitude = '',
    this.longitude = '',
    this.restaurantTypes = const [],
    this.selectedRestaurantType,
    this.isLoadingRestaurantTypes = false,
    this.type = RestaurantType.veg,
    required this.hours,
    this.isLoading = false,
    this.isSubmitting = false,
    this.submissionSuccess = false,
    this.submissionMessage,
    this.errorMessage,
  });

  RestaurantProfileState copyWith({
    String? imagePath,
    String? restaurantImageUrl,
    String? ownerName,
    String? ownerMobile,
    String? ownerEmail,
    String? ownerAddress,
    String? restaurantName,
    String? description,
    String? cookingTime,
    String? latitude,
    String? longitude,
    List<Map<String, dynamic>>? restaurantTypes,
    Map<String, dynamic>? selectedRestaurantType,
    bool? isLoadingRestaurantTypes,
    RestaurantType? type,
    List<OperationalDay>? hours,
    bool? isLoading,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? submissionMessage,
    String? errorMessage,
  }) =>
      RestaurantProfileState(
        imagePath: imagePath ?? this.imagePath,
        restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
        ownerName: ownerName ?? this.ownerName,
        ownerMobile: ownerMobile ?? this.ownerMobile,
        ownerEmail: ownerEmail ?? this.ownerEmail,
        ownerAddress: ownerAddress ?? this.ownerAddress,
        restaurantName: restaurantName ?? this.restaurantName,
        description: description ?? this.description,
        cookingTime: cookingTime ?? this.cookingTime,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        restaurantTypes: restaurantTypes ?? this.restaurantTypes,
        selectedRestaurantType: selectedRestaurantType ?? this.selectedRestaurantType,
        isLoadingRestaurantTypes: isLoadingRestaurantTypes ?? this.isLoadingRestaurantTypes,
        type: type ?? this.type,
        hours: hours ?? this.hours,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submissionSuccess: submissionSuccess ?? this.submissionSuccess,
        submissionMessage: submissionMessage ?? this.submissionMessage,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isValid {
    // Debug print for validation
    debugPrint('Validating state:');
    debugPrint('- restaurantName: "$restaurantName"');
    debugPrint('- ownerName: "$ownerName"');
    debugPrint('- ownerMobile: "$ownerMobile"');
    
    return true;
  }

  @override
  List<Object?> get props => [
        imagePath,
        restaurantImageUrl,
        ownerName,
        ownerMobile,
        ownerEmail,
        ownerAddress,
        restaurantName,
        description,
        cookingTime,
        latitude,
        longitude,
        restaurantTypes,
        selectedRestaurantType,
        isLoadingRestaurantTypes,
        type,
        hours,
        isLoading,
        isSubmitting,
        submissionSuccess,
        submissionMessage,
        errorMessage,
      ];
}