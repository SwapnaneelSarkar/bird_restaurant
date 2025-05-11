// lib/presentation/screens/otp/state.dart

import 'package:equatable/equatable.dart';
import '../../../constants/enums.dart';

class OtpState extends Equatable {
  final List<String> digits;
  final bool isButtonEnabled;
  final int remainingSeconds;
  final OtpStatus status;
  final String? errorMessage;
  final String? verificationId;
  final String mobileNumber;
  final String? apiStatus;

  const OtpState({
    this.digits = const ['', '', '', '', '', ''],
    this.isButtonEnabled = false,
    this.remainingSeconds = 30,
    this.status = OtpStatus.initial,
    this.errorMessage,
    this.verificationId,
    this.mobileNumber = '',
    this.apiStatus,
  });


  OtpState copyWith({
    List<String>? digits,
    bool? isButtonEnabled,
    int? remainingSeconds,
    OtpStatus? status,
    String? errorMessage,
    String? verificationId,
    String? mobileNumber,
    String? apiStatus,
  }) {
    return OtpState(
      digits: digits ?? this.digits,
      isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationId: verificationId ?? this.verificationId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      apiStatus: apiStatus ?? this.apiStatus,
    );
  }

  @override
  List<Object?> get props => [
        digits,
        isButtonEnabled,
        remainingSeconds,
        status,
        errorMessage,
        verificationId,
        mobileNumber,
        apiStatus,
      ];
}
