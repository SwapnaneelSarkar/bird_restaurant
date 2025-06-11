// lib/presentation/screens/signin/bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<MobileNumberChanged>(_onMobileChanged);
    on<CountryChanged>(_onCountryChanged);
    on<SendOtpPressed>(_onSendOtpPressed);
  }

  void _onMobileChanged(
      MobileNumberChanged event, Emitter<LoginState> emit) {
    // Store the mobile number without spaces
    emit(state.copyWith(mobileNumber: event.mobileNumber.replaceAll(' ', '')));
  }

  void _onCountryChanged(
      CountryChanged event, Emitter<LoginState> emit) {
    // Update the selected country
    debugPrint('>> Country changed to: ${event.country.name} (${event.country.dialCode})');
    emit(state.copyWith(selectedCountry: event.country));
  }

  Future<void> _onSendOtpPressed(
      SendOtpPressed event, Emitter<LoginState> emit) async {
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