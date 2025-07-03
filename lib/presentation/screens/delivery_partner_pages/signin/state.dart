import 'package:bird_restaurant/models/country.dart';
import 'package:equatable/equatable.dart';

enum DeliveryPartnerSigninStatus {
  initial,
  loading,
  success,
  error,
}

class DeliveryPartnerSigninState extends Equatable {
  final String mobileNumber;
  final String? formattedPhoneNumber;
  final Country selectedCountry;
  final DeliveryPartnerSigninStatus status;
  final String? errorMessage;
  final bool isValid;

  const DeliveryPartnerSigninState({
    required this.mobileNumber,
    this.formattedPhoneNumber,
    required this.selectedCountry,
    required this.status,
    this.errorMessage,
    required this.isValid,
  });

  factory DeliveryPartnerSigninState.initial() {
    return DeliveryPartnerSigninState(
      mobileNumber: '',
      selectedCountry: CountryData.defaultCountry, // India as default
      status: DeliveryPartnerSigninStatus.initial,
      isValid: false,
    );
  }

  DeliveryPartnerSigninState copyWith({
    String? mobileNumber,
    String? formattedPhoneNumber,
    Country? selectedCountry,
    DeliveryPartnerSigninStatus? status,
    String? errorMessage,
    bool? isValid,
  }) {
    return DeliveryPartnerSigninState(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [
        mobileNumber,
        formattedPhoneNumber,
        selectedCountry,
        status,
        errorMessage,
        isValid,
      ];
} 