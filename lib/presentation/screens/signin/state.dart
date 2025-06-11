// lib/presentation/screens/login/state.dart

import '../../../models/country.dart';

class LoginState {
  final String mobileNumber;
  final String? formattedPhoneNumber;
  final Country selectedCountry;
  
  LoginState({
    required this.mobileNumber,
    this.formattedPhoneNumber,
    required this.selectedCountry,
  });
  
  factory LoginState.initial() {
    return LoginState(
      mobileNumber: '',
      selectedCountry: CountryData.defaultCountry, // India as default
    );
  }
  
  LoginState copyWith({
    String? mobileNumber,
    String? formattedPhoneNumber,
    Country? selectedCountry,
  }) {
    return LoginState(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      selectedCountry: selectedCountry ?? this.selectedCountry,
    );
  }
}