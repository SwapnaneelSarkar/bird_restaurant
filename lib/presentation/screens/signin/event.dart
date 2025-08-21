// lib/presentation/screens/login/event.dart

import 'package:equatable/equatable.dart';
import '../../../models/country.dart';

abstract class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// fired when view loads to auto-detect country from location/locale
class AutoDetectCountryRequested extends LoginEvent {}

/// fired on each change in the text field
class MobileNumberChanged extends LoginEvent {
  final String mobileNumber;
  MobileNumberChanged(this.mobileNumber);

  @override
  List<Object?> get props => [mobileNumber];
}

/// fired when user selects a different country
class CountryChanged extends LoginEvent {
  final Country country;
  CountryChanged(this.country);

  @override
  List<Object?> get props => [country];
}

/// fired when user taps "Send OTP"
class SendOtpPressed extends LoginEvent {}