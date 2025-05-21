class RestaurantDetailsState {
  final String name;
  final String address;
  final String phoneNumber;
  final String email;
  final bool isFormValid;
  final bool isLocationLoading;
  final bool isDataLoaded;
  final bool isAttemptedSubmit;
  final double latitude;
  final double longitude;
  
  // New fields for restaurant type
  final List<Map<String, dynamic>> restaurantTypes;
  final Map<String, dynamic>? selectedRestaurantType;
  final bool isLoadingRestaurantTypes;

  RestaurantDetailsState({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.isFormValid,
    required this.isLocationLoading,
    required this.isDataLoaded,
    required this.isAttemptedSubmit,
    required this.latitude,
    required this.longitude,
    required this.restaurantTypes,
    this.selectedRestaurantType,
    required this.isLoadingRestaurantTypes,
  });

  factory RestaurantDetailsState.initial() {
    return RestaurantDetailsState(
      name: '',
      address: '',
      phoneNumber: '',
      email: '',
      isFormValid: false,
      isLocationLoading: false,
      isDataLoaded: false,
      isAttemptedSubmit: false,
      latitude: 0.0,
      longitude: 0.0,
      restaurantTypes: [],
      selectedRestaurantType: null,
      isLoadingRestaurantTypes: false,
    );
  }

  RestaurantDetailsState copyWith({
    String? name,
    String? address,
    String? phoneNumber,
    String? email,
    bool? isFormValid,
    bool? isLocationLoading,
    bool? isDataLoaded,
    bool? isAttemptedSubmit,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? restaurantTypes,
    Map<String, dynamic>? selectedRestaurantType,
    bool? isLoadingRestaurantTypes,
  }) {
    return RestaurantDetailsState(
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isFormValid: isFormValid ?? this.isFormValid,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      isDataLoaded: isDataLoaded ?? this.isDataLoaded,
      isAttemptedSubmit: isAttemptedSubmit ?? this.isAttemptedSubmit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      restaurantTypes: restaurantTypes ?? this.restaurantTypes,
      selectedRestaurantType: selectedRestaurantType ?? this.selectedRestaurantType,
      isLoadingRestaurantTypes: isLoadingRestaurantTypes ?? this.isLoadingRestaurantTypes,
    );
  }
}