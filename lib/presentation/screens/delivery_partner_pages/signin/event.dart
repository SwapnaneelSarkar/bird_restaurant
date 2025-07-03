import 'package:bird_restaurant/models/country.dart';
import 'package:equatable/equatable.dart';

abstract class DeliveryPartnerSigninEvent extends Equatable {
  const DeliveryPartnerSigninEvent();

  @override
  List<Object?> get props => [];
}

/// fired on each change in the text field
class DeliveryPartnerMobileNumberChanged extends DeliveryPartnerSigninEvent {
  final String mobileNumber;
  
  const DeliveryPartnerMobileNumberChanged(this.mobileNumber);

  @override
  List<Object?> get props => [mobileNumber];
}

/// fired when user selects a different country
class DeliveryPartnerCountryChanged extends DeliveryPartnerSigninEvent {
  final Country country;
  
  const DeliveryPartnerCountryChanged(this.country);

  @override
  List<Object?> get props => [country];
}

/// fired when user taps "Send OTP"
class DeliveryPartnerSendOtpPressed extends DeliveryPartnerSigninEvent {
  const DeliveryPartnerSendOtpPressed();
} 