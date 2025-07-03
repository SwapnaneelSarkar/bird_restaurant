import 'dart:async';
import 'dart:io';
import 'package:bird_restaurant/constants/enums.dart';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'package:bird_restaurant/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'event.dart';
import 'state.dart';


class DeliveryPartnerOtpBloc extends Bloc<DeliveryPartnerOtpEvent, DeliveryPartnerOtpState> {
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  DeliveryPartnerOtpBloc() : super(const DeliveryPartnerOtpState()) {
    on<DeliveryPartnerStartTimerEvent>(_onStartTimer);
    on<DeliveryPartnerTimerTickEvent>(_onTimerTick);
    on<DeliveryPartnerOtpDigitChanged>(_onDigitChanged);
    on<DeliveryPartnerResendOtpEvent>(_onResendOtp);
    on<DeliveryPartnerSubmitOtpPressed>(_onSubmitOtp);
    on<DeliveryPartnerInitializeOtpEvent>(_onInitializeOtp);
    on<DeliveryPartnerVerificationCompleted>(_onVerificationCompleted);
    on<DeliveryPartnerVerificationFailed>(_onVerificationFailed);
    on<DeliveryPartnerCodeSent>(_onCodeSent);
  }

  void _onStartTimer(DeliveryPartnerStartTimerEvent event, Emitter<DeliveryPartnerOtpState> emit) {
    _timer?.cancel();
    emit(state.copyWith(
      remainingSeconds: 30,
      status: OtpStatus.initial,
      errorMessage: null,
    ));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const DeliveryPartnerTimerTickEvent());
    });
  }

  void _onTimerTick(DeliveryPartnerTimerTickEvent event, Emitter<DeliveryPartnerOtpState> emit) {
    final sec = state.remainingSeconds;
    if (sec > 0) {
      emit(state.copyWith(remainingSeconds: sec - 1));
    } else {
      _timer?.cancel();
    }
  }

  void _onDigitChanged(DeliveryPartnerOtpDigitChanged event, Emitter<DeliveryPartnerOtpState> emit) {
    final digits = List<String>.from(state.digits);
    digits[event.index] = event.digit;
    final allFilled = digits.every((d) => d.isNotEmpty);

    emit(state.copyWith(
      digits: digits,
      isButtonEnabled: allFilled,
      status: OtpStatus.initial,
      errorMessage: null,
    ));
  }

  Future<void> _onInitializeOtp(DeliveryPartnerInitializeOtpEvent event, Emitter<DeliveryPartnerOtpState> emit) async {
    if (event.mobileNumber.isEmpty) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Phone number is required',
      ));
      return;
    }

    emit(state.copyWith(
      mobileNumber: event.mobileNumber,
      status: OtpStatus.validating,
    ));
    
    try {
      debugPrint('Initializing OTP for phone: ${event.mobileNumber}');
      
      if (event.mobileNumber == '+911111111111') {
        debugPrint('Test phone number detected');
        
        if (Platform.isIOS) {
          debugPrint('iOS detected - using test mode');
          emit(state.copyWith(
            verificationId: 'test-verification-id',
            status: OtpStatus.initial,
          ));
          add(const DeliveryPartnerStartTimerEvent());
          return;
        } else {
          await _auth.setSettings(
            appVerificationDisabledForTesting: true,
            forceRecaptchaFlow: false,
          );
        }
      } else {
        debugPrint('Real phone number - enabling reCAPTCHA fallback');
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
          forceRecaptchaFlow: true,
        );
      }
      
      debugPrint('Starting Firebase phone verification');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: event.mobileNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Verification completed automatically');
          add(DeliveryPartnerVerificationCompleted(credential.smsCode ?? ''));
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          if (e.code == 'invalid-phone-number') {
            add(const DeliveryPartnerVerificationFailed('The provided phone number is not valid.'));
          } else if (e.code == 'missing-client-identifier') {
            add(const DeliveryPartnerVerificationFailed('Missing client identifier. Please check your Firebase configuration.'));
          } else if (e.code == 'app-not-authorized') {
            add(const DeliveryPartnerVerificationFailed('This app is not authorized to use Firebase Authentication. Please check your Firebase configuration.'));
          } else {
            add(DeliveryPartnerVerificationFailed(e.message ?? 'Verification failed'));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ Code sent! Verification ID: $verificationId');
          add(DeliveryPartnerCodeSent(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Auto retrieval timeout. Verification ID: $verificationId');
          if (state.verificationId == null) {
            add(DeliveryPartnerCodeSent(verificationId));
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ Error in _onInitializeOtp: $e');
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Failed to send OTP: $e',
      ));
    }
  }

  void _onVerificationCompleted(DeliveryPartnerVerificationCompleted event, Emitter<DeliveryPartnerOtpState> emit) {
    final smsCode = event.smsCode;
    final digits = List<String>.filled(6, '');
    
    for (int i = 0; i < smsCode.length && i < 6; i++) {
      digits[i] = smsCode[i];
    }
    
    emit(state.copyWith(
      digits: digits,
      isButtonEnabled: true,
    ));
    add(const DeliveryPartnerSubmitOtpPressed());
  }

  void _onVerificationFailed(DeliveryPartnerVerificationFailed event, Emitter<DeliveryPartnerOtpState> emit) {
    emit(state.copyWith(
      status: OtpStatus.failure,
      errorMessage: event.message,
    ));
  }

  void _onCodeSent(DeliveryPartnerCodeSent event, Emitter<DeliveryPartnerOtpState> emit) {
    debugPrint('_onCodeSent called with verificationId: ${event.verificationId}');
    if (event.verificationId.isEmpty) {
      debugPrint('ERROR: Received empty verification ID');
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Failed to receive verification ID from Firebase',
      ));
      return;
    }
    
    emit(state.copyWith(
      verificationId: event.verificationId,
      status: OtpStatus.initial,
    ));
    add(const DeliveryPartnerStartTimerEvent());
  }

  Future<void> _onResendOtp(DeliveryPartnerResendOtpEvent event, Emitter<DeliveryPartnerOtpState> emit) async {
    if (state.mobileNumber.isEmpty) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Phone number is required',
      ));
      return;
    }

    emit(state.copyWith(status: OtpStatus.validating));

    try {
      // Reset digits and button state
      emit(state.copyWith(
        digits: List<String>.filled(6, ''),
        isButtonEnabled: false,
      ));

      // Re-initialize OTP
      add(DeliveryPartnerInitializeOtpEvent(state.mobileNumber));
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Failed to resend OTP: $e',
      ));
    }
  }

  Future<void> _onSubmitOtp(DeliveryPartnerSubmitOtpPressed event, Emitter<DeliveryPartnerOtpState> emit) async {
    if (!state.isButtonEnabled || state.verificationId == null) {
      return;
    }

    emit(state.copyWith(status: OtpStatus.validating));

    try {
      final otp = state.digits.join('');
      debugPrint('Submitting OTP: $otp');

      // For test phone number, skip Firebase verification
      if (state.mobileNumber == '+911111111111') {
        debugPrint('Test phone number - skipping Firebase verification');
        await _handleDeliveryPartnerAuthSuccess(otp);
        return;
      }

      // Create credential with Firebase
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful: ${userCredential.user?.uid}');

      // Call delivery partner auth API
      await _handleDeliveryPartnerAuthSuccess(otp);

    } catch (e) {
      debugPrint('Error submitting OTP: $e');
      String errorMessage = 'Invalid OTP. Please try again.';
      
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.code == 'invalid-verification-id') {
          errorMessage = 'OTP expired. Please request a new one.';
        } else {
          errorMessage = e.message ?? 'Verification failed';
        }
      }
      
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  Future<void> _handleDeliveryPartnerAuthSuccess(String otp) async {
    try {
      // Extract just the phone number without country code for API
      String phoneForApi = state.mobileNumber;
      if (phoneForApi.startsWith('+91')) {
        phoneForApi = phoneForApi.substring(3); // Remove +91
      }
      
      // Call delivery partner auth API
      final result = await DeliveryPartnerAuthService.authenticateDeliveryPartner(phoneForApi);

      debugPrint('Delivery partner auth API response: $result');

      if (result['success']) {
        // Initialize notification service
        await _notificationService.initialize();

        emit(state.copyWith(
          status: OtpStatus.success,
          apiStatus: 'success',
        ));
      } else {
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: result['message'] ?? 'Authentication failed',
          apiStatus: 'failure',
        ));
      }

    } catch (e) {
      debugPrint('Error in delivery partner auth API: $e');
      String errorMessage = 'Authentication failed. Please try again.';
      
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: errorMessage,
        apiStatus: 'failure',
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
} 