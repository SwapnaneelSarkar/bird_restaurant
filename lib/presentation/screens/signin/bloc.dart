// lib/presentation/screens/login/bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<MobileNumberChanged>(_onMobileChanged);
    on<SendOtpPressed>(_onSendOtpPressed);
  }

  void _onMobileChanged(
      MobileNumberChanged event, Emitter<LoginState> emit) {
    // Store the mobile number without spaces
    emit(state.copyWith(mobileNumber: event.mobileNumber.replaceAll(' ', '')));
  }

  Future<void> _onSendOtpPressed(
      SendOtpPressed event, Emitter<LoginState> emit) async {
    // Format the phone number properly before sending
    String formattedNumber = '+91${state.mobileNumber}';
    debugPrint('>> SEND OTP for $formattedNumber');
    
    // Update the state with the formatted number
    emit(state.copyWith(
      mobileNumber: state.mobileNumber,
      formattedPhoneNumber: formattedNumber,
    ));
  }
}