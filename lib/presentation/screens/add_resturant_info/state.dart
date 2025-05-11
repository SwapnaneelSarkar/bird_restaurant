class RestaurantDetailsState {
  final String name;
  final String address;
  final String phoneNumber;
  final String email;
  final bool isFormValid;
  final bool isLocationLoading;
  final bool isDataLoaded;
  final bool isAttemptedSubmit;
  
  // Add coordinates
  final double latitude;
  final double longitude;

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
    );
  }
}