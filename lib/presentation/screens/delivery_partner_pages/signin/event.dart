import 'package:equatable/equatable.dart';

abstract class DeliveryPartnerSigninEvent extends Equatable {
  const DeliveryPartnerSigninEvent();

  @override
  List<Object?> get props => [];
}

/// fired on each change in the username field
class DeliveryPartnerUsernameChanged extends DeliveryPartnerSigninEvent {
  final String username;
  
  const DeliveryPartnerUsernameChanged(this.username);

  @override
  List<Object?> get props => [username];
}

/// fired on each change in the password field
class DeliveryPartnerPasswordChanged extends DeliveryPartnerSigninEvent {
  final String password;
  
  const DeliveryPartnerPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

/// fired when user taps "Sign In"
class DeliveryPartnerSignInPressed extends DeliveryPartnerSigninEvent {
  const DeliveryPartnerSignInPressed();
} 