import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../resturant_details_2/state.dart';
import 'event.dart';
import '../../../constants/enums.dart';
import '../../../models/country.dart';


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
  final String deliveryRadius; // 👈 NEW FIELD ADDED

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
  final String? ownerNameError; // Specific error for owner name validation
  final String? restaurantNameError; // Specific error for restaurant name validation

  final List<CuisineType> selectedCuisines;
  
  // Supercategory
  final String? selectedSupercategoryId;
  final String? selectedSupercategoryName;
  
  // Phone OTP Verification
  final bool isPhoneVerified;
  final bool isPhoneVerificationInProgress;
  final String? phoneVerificationError;
  final String? phoneVerificationId;
  final List<String> phoneOtpDigits;
  final int phoneOtpTimer;
  
  // Country Code Detection
  final Country selectedCountry;
  final bool isCountryDetectionInProgress;
  
  // Location Permission
  final bool hasLocationPermission;

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
    this.deliveryRadius = '', // 👈 NEW FIELD ADDED
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
    this.ownerNameError,
    this.restaurantNameError,
    this.selectedCuisines = const [],
    this.selectedSupercategoryId,
    this.selectedSupercategoryName,
    this.isPhoneVerified = false,
    this.isPhoneVerificationInProgress = false,
    this.phoneVerificationError,
    this.phoneVerificationId,
    this.phoneOtpDigits = const ['', '', '', '', '', ''],
    this.phoneOtpTimer = 0,
    this.selectedCountry = const Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    this.isCountryDetectionInProgress = false,
    this.hasLocationPermission = false,
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
    String? deliveryRadius, // 👈 NEW FIELD ADDED
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
    String? ownerNameError,
    String? restaurantNameError,
    bool clearOwnerNameError = false,
    bool clearRestaurantNameError = false,
    List<CuisineType>? selectedCuisines,
    String? selectedSupercategoryId,
    String? selectedSupercategoryName,
    bool? isPhoneVerified,
    bool? isPhoneVerificationInProgress,
    String? phoneVerificationError,
    String? phoneVerificationId,
    List<String>? phoneOtpDigits,
    int? phoneOtpTimer,
    Country? selectedCountry,
    bool? isCountryDetectionInProgress,
    bool? hasLocationPermission,
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
        deliveryRadius: deliveryRadius ?? this.deliveryRadius, // 👈 NEW FIELD ADDED
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
        ownerNameError: clearOwnerNameError ? null : (ownerNameError ?? this.ownerNameError),
        restaurantNameError: clearRestaurantNameError ? null : (restaurantNameError ?? this.restaurantNameError),
        selectedCuisines: selectedCuisines ?? this.selectedCuisines,
        selectedSupercategoryId: selectedSupercategoryId ?? this.selectedSupercategoryId,
        selectedSupercategoryName: selectedSupercategoryName ?? this.selectedSupercategoryName,
        isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
        isPhoneVerificationInProgress: isPhoneVerificationInProgress ?? this.isPhoneVerificationInProgress,
        phoneVerificationError: phoneVerificationError ?? this.phoneVerificationError,
        phoneVerificationId: phoneVerificationId ?? this.phoneVerificationId,
        phoneOtpDigits: phoneOtpDigits ?? this.phoneOtpDigits,
        phoneOtpTimer: phoneOtpTimer ?? this.phoneOtpTimer,
        selectedCountry: selectedCountry ?? this.selectedCountry,
        isCountryDetectionInProgress: isCountryDetectionInProgress ?? this.isCountryDetectionInProgress,
        hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,

      );

  bool get isValid {
    // Debug print for validation
    debugPrint('Validating state:');
    debugPrint('- restaurantName: "$restaurantName"');
    debugPrint('- ownerName: "$ownerName"');
    debugPrint('- ownerMobile: "$ownerMobile"');
    debugPrint('- deliveryRadius: "$deliveryRadius"'); // 👈 NEW DEBUG LOG
    
    return true;
  }
  
  // Helper method to check if supercategory is food
  bool get isFoodSupercategory {
    // Check if supercategory ID is the food supercategory ID
    return selectedSupercategoryId == "7acc47a2fa5a4eeb906a753b3" || 
           selectedSupercategoryName?.toLowerCase() == "food";
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
        deliveryRadius, // 👈 NEW FIELD ADDED TO PROPS
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
        ownerNameError,
        restaurantNameError,
        selectedCuisines,
        selectedSupercategoryId,
        selectedSupercategoryName,
        isPhoneVerified,
        isPhoneVerificationInProgress,
        phoneVerificationError,
        phoneVerificationId,
        phoneOtpDigits,
        phoneOtpTimer,
        selectedCountry,
        isCountryDetectionInProgress,
        hasLocationPermission,
      ];
}