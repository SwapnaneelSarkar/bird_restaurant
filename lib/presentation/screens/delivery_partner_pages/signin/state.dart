import 'package:equatable/equatable.dart';

enum DeliveryPartnerSigninStatus {
  initial,
  loading,
  success,
  error,
}

class DeliveryPartnerSigninState extends Equatable {
  final String username;
  final String password;
  final DeliveryPartnerSigninStatus status;
  final String? errorMessage;
  final bool isValid;

  const DeliveryPartnerSigninState({
    required this.username,
    required this.password,
    required this.status,
    this.errorMessage,
    required this.isValid,
  });

  factory DeliveryPartnerSigninState.initial() {
    return DeliveryPartnerSigninState(
      username: '',
      password: '',
      status: DeliveryPartnerSigninStatus.initial,
      isValid: false,
    );
  }

  DeliveryPartnerSigninState copyWith({
    String? username,
    String? password,
    DeliveryPartnerSigninStatus? status,
    String? errorMessage,
    bool? isValid,
  }) {
    return DeliveryPartnerSigninState(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        status,
        errorMessage,
        isValid,
      ];
} 