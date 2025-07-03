import 'package:equatable/equatable.dart';

abstract class DeliveryPartnerOtpEvent extends Equatable {
  const DeliveryPartnerOtpEvent();

  @override
  List<Object?> get props => [];
}

class DeliveryPartnerStartTimerEvent extends DeliveryPartnerOtpEvent {
  const DeliveryPartnerStartTimerEvent();
}

class DeliveryPartnerTimerTickEvent extends DeliveryPartnerOtpEvent {
  const DeliveryPartnerTimerTickEvent();
}

class DeliveryPartnerOtpDigitChanged extends DeliveryPartnerOtpEvent {
  final int index;
  final String digit;

  const DeliveryPartnerOtpDigitChanged(this.index, this.digit);

  @override
  List<Object?> get props => [index, digit];
}

class DeliveryPartnerResendOtpEvent extends DeliveryPartnerOtpEvent {
  const DeliveryPartnerResendOtpEvent();
}

class DeliveryPartnerSubmitOtpPressed extends DeliveryPartnerOtpEvent {
  const DeliveryPartnerSubmitOtpPressed();
}

class DeliveryPartnerInitializeOtpEvent extends DeliveryPartnerOtpEvent {
  final String mobileNumber;
  
  const DeliveryPartnerInitializeOtpEvent(this.mobileNumber);

  @override
  List<Object?> get props => [mobileNumber];
}

class DeliveryPartnerVerificationCompleted extends DeliveryPartnerOtpEvent {
  final String smsCode;
  
  const DeliveryPartnerVerificationCompleted(this.smsCode);

  @override
  List<Object?> get props => [smsCode];
}

class DeliveryPartnerVerificationFailed extends DeliveryPartnerOtpEvent {
  final String message;
  
  const DeliveryPartnerVerificationFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryPartnerCodeSent extends DeliveryPartnerOtpEvent {
  final String verificationId;
  
  const DeliveryPartnerCodeSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
} 