// lib/presentation/screens/signin/bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'event.dart';
import 'state.dart';
import '../../../models/country.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<AutoDetectCountryRequested>(_onAutoDetectCountryRequested);
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

  Future<void> _onAutoDetectCountryRequested(
      AutoDetectCountryRequested event, Emitter<LoginState> emit) async {
    try {
      // Try using device locale first as a fast path
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      if (locale.countryCode != null) {
        final fromLocale = CountryData.findByCode(locale.countryCode!.toUpperCase());
        if (fromLocale != null) {
          emit(state.copyWith(selectedCountry: fromLocale));
          return;
        }
      }

      // Fallback to geolocation + reverse geocoding
      final hasPermission = await _hasLocationPermissionWithoutPrompt();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final isoCountryCode = placemarks.first.isoCountryCode;
        if (isoCountryCode != null) {
          final match = CountryData.findByCode(isoCountryCode.toUpperCase());
          if (match != null) {
            emit(state.copyWith(selectedCountry: match));
          }
        }
      }
    } catch (e) {
      debugPrint('Auto-detect country failed: $e');
      // Keep existing default on failure
    }
  }

  Future<bool> _hasLocationPermissionWithoutPrompt() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}