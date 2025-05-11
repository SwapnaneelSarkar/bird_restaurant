// lib/presentation/screens/login/state.dart

class LoginState {
  final String mobileNumber;
  final String? formattedPhoneNumber;
  
  LoginState({
    required this.mobileNumber,
    this.formattedPhoneNumber,
  });
  
  factory LoginState.initial() {
    return LoginState(
      mobileNumber: '',
    );
  }
  
  LoginState copyWith({
    String? mobileNumber,
    String? formattedPhoneNumber,
  }) {
    return LoginState(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
    );
  }
}