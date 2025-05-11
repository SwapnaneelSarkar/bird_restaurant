import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// fired on each change in the text field
class MobileNumberChanged extends LoginEvent {
  final String mobileNumber;
  MobileNumberChanged(this.mobileNumber);

  @override
  List<Object?> get props => [mobileNumber];
}

/// fired when user taps “Send OTP”
class SendOtpPressed extends LoginEvent {}
