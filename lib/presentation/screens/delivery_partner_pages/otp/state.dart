import 'package:bird_restaurant/constants/enums.dart';
import 'package:equatable/equatable.dart';

class DeliveryPartnerOtpState extends Equatable {
  final List<String> digits;
  final bool isButtonEnabled;
  final int remainingSeconds;
  final OtpStatus status;
  final String? errorMessage;
  final String? verificationId;
  final String mobileNumber;
  final String? apiStatus;

  const DeliveryPartnerOtpState({
    this.digits = const ['', '', '', '', '', ''],
    this.isButtonEnabled = false,
    this.remainingSeconds = 30,
    this.status = OtpStatus.initial,
    this.errorMessage,
    this.verificationId,
    this.mobileNumber = '',
    this.apiStatus,
  });

  DeliveryPartnerOtpState copyWith({
    List<String>? digits,
    bool? isButtonEnabled,
    int? remainingSeconds,
    OtpStatus? status,
    String? errorMessage,
    String? verificationId,
    String? mobileNumber,
    String? apiStatus,
  }) {
    return DeliveryPartnerOtpState(
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