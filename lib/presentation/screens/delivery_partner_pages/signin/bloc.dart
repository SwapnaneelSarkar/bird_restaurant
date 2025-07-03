import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class DeliveryPartnerSigninBloc extends Bloc<DeliveryPartnerSigninEvent, DeliveryPartnerSigninState> {
  DeliveryPartnerSigninBloc() : super(DeliveryPartnerSigninState.initial()) {
    on<DeliveryPartnerMobileNumberChanged>(_onMobileChanged);
    on<DeliveryPartnerCountryChanged>(_onCountryChanged);
    on<DeliveryPartnerSendOtpPressed>(_onSendOtpPressed);
  }

  void _onMobileChanged(
      DeliveryPartnerMobileNumberChanged event, Emitter<DeliveryPartnerSigninState> emit) {
    // Store the mobile number without spaces
    final cleanNumber = event.mobileNumber.replaceAll(' ', '');
    emit(state.copyWith(
      mobileNumber: cleanNumber,
      isValid: cleanNumber.length >= 5,
    ));
  }

  void _onCountryChanged(
      DeliveryPartnerCountryChanged event, Emitter<DeliveryPartnerSigninState> emit) {
    // Update the selected country
    debugPrint('>> Country changed to: ${event.country.name} (${event.country.dialCode})');
    emit(state.copyWith(selectedCountry: event.country));
  }

  Future<void> _onSendOtpPressed(
      DeliveryPartnerSendOtpPressed event, Emitter<DeliveryPartnerSigninState> emit) async {
    // Format the phone number using the selected country's dial code
    String formattedNumber = '${state.selectedCountry.dialCode}${state.mobileNumber}';
    debugPrint('>> SEND OTP for $formattedNumber');
    
    // Update the state with the formatted number
    emit(state.copyWith(
      mobileNumber: state.mobileNumber,
      formattedPhoneNumber: formattedNumber,
    ));
  }
} 