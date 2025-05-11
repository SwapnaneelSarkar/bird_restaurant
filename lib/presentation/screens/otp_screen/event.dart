// lib/presentation/screens/otp/event.dart

abstract class OtpEvent {}

class StartTimerEvent extends OtpEvent {}

class TimerTickEvent extends OtpEvent {}

class OtpDigitChanged extends OtpEvent {
  final int index;
  final String digit;

  OtpDigitChanged(this.index, this.digit);
}

class ResendOtpEvent extends OtpEvent {}

class SubmitOtpPressed extends OtpEvent {}

class InitializeOtpEvent extends OtpEvent {
  final String mobileNumber;
  
  InitializeOtpEvent(this.mobileNumber);
}

class VerificationCompleted extends OtpEvent {
  final String smsCode;
  
  VerificationCompleted(this.smsCode);
}

class VerificationFailed extends OtpEvent {
  final String message;
  
  VerificationFailed(this.message);
}

class CodeSent extends OtpEvent {
  final String verificationId;
  
  CodeSent(this.verificationId);
}

