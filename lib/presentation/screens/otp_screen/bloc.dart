// lib/presentation/screens/otp_screen/bloc.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:flutter/foundation.dart'; // Add this import
import '../../../constants/enums.dart';

import '../../../services/api_service.dart' show ApiServices, UnauthorizedException;
import '../../../services/token_service.dart';
import '../../../services/notification_service.dart'; // Add this import
import 'event.dart';
import 'state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiServices _apiServices = ApiServices();
  final NotificationService _notificationService = NotificationService(); // Add this

  OtpBloc() : super(const OtpState()) {
    on<StartTimerEvent>(_onStartTimer);
    on<TimerTickEvent>(_onTimerTick);
    on<OtpDigitChanged>(_onDigitChanged);
    on<ResendOtpEvent>(_onResendOtp);
    on<SubmitOtpPressed>(_onSubmitOtp);
    on<InitializeOtpEvent>(_onInitializeOtp);
    on<VerificationCompleted>(_onVerificationCompleted);
    on<VerificationFailed>(_onVerificationFailed);
    on<CodeSent>(_onCodeSent);
  }

  void _onStartTimer(StartTimerEvent event, Emitter<OtpState> emit) {
    // reset & start countdown
    _timer?.cancel();
    emit(state.copyWith(
      remainingSeconds: 30,
      status: OtpStatus.initial,
      errorMessage: null,
    ));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(TimerTickEvent());
    });
  }

  void _onTimerTick(TimerTickEvent event, Emitter<OtpState> emit) {
    final sec = state.remainingSeconds;
    if (sec > 0) {
      emit(state.copyWith(remainingSeconds: sec - 1));
    } else {
      _timer?.cancel();
    }
  }

  void _onDigitChanged(OtpDigitChanged event, Emitter<OtpState> emit) {
    final digits = List<String>.from(state.digits);
    digits[event.index] = event.digit;
    final allFilled = digits.every((d) => d.isNotEmpty);

    emit(state.copyWith(
      digits: digits,
      isButtonEnabled: allFilled,
      status: OtpStatus.initial,      // clear any previous status
      errorMessage: null,
    ));
  }

  Future<void> _onInitializeOtp(InitializeOtpEvent event, Emitter<OtpState> emit) async {
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
    
    // Only use test mode for the specific test phone number
    if (event.mobileNumber == '+911111111111') {
      debugPrint('Test phone number detected');
      
      // For iOS test numbers, skip Firebase and use direct verification
      if (Platform.isIOS) {
        debugPrint('iOS detected - using test mode');
        // Set a dummy verification ID for test
        emit(state.copyWith(
          verificationId: 'test-verification-id',
          status: OtpStatus.initial,
        ));
        add(StartTimerEvent());
        return;
      } else {
        // For Android test numbers, use proper test settings
        await _auth.setSettings(
          appVerificationDisabledForTesting: true,
          forceRecaptchaFlow: false,
        );
      }
    } else {
      // ✅ FOR REAL PHONE NUMBERS - THIS IS THE KEY FIX
      debugPrint('Real phone number - enabling reCAPTCHA fallback');
      await _auth.setSettings(
        appVerificationDisabledForTesting: false,  // ✅ Changed from true to false
        forceRecaptchaFlow: true,                  // ✅ Changed from false to true
      );
    }
    
    // For all real phone numbers (including on iOS), use Firebase Phone Auth
    debugPrint('Starting Firebase phone verification');
    
    await _auth.verifyPhoneNumber(
      phoneNumber: event.mobileNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('✅ Verification completed automatically');
        add(VerificationCompleted(credential.smsCode ?? ''));
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
        if (e.code == 'invalid-phone-number') {
          add(VerificationFailed('The provided phone number is not valid.'));
        } else if (e.code == 'missing-client-identifier') {
          add(VerificationFailed('Missing client identifier. Please check your Firebase configuration.'));
        } else if (e.code == 'app-not-authorized') {
          add(VerificationFailed('This app is not authorized to use Firebase Authentication. Please check your Firebase configuration.'));
        } else {
          add(VerificationFailed(e.message ?? 'Verification failed'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('✅ Code sent! Verification ID: $verificationId');
        add(CodeSent(verificationId));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏰ Auto retrieval timeout. Verification ID: $verificationId');
        if (state.verificationId == null) {
          add(CodeSent(verificationId));
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

  void _onVerificationCompleted(VerificationCompleted event, Emitter<OtpState> emit) {
    final smsCode = event.smsCode;
    final digits = List<String>.filled(6, '');
    
    // Fill the digits array with the SMS code characters
    for (int i = 0; i < smsCode.length && i < 6; i++) {
      digits[i] = smsCode[i];
    }
    
    emit(state.copyWith(
      digits: digits,
      isButtonEnabled: true,
    ));
    add(SubmitOtpPressed());
  }

  void _onVerificationFailed(VerificationFailed event, Emitter<OtpState> emit) {
    emit(state.copyWith(
      status: OtpStatus.failure,
      errorMessage: event.message,
    ));
  }

  void _onCodeSent(CodeSent event, Emitter<OtpState> emit) {
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
    add(StartTimerEvent());
  }

  Future<void> _onResendOtp(ResendOtpEvent event, Emitter<OtpState> emit) async {
    // Clear verification ID before resending
    emit(state.copyWith(
      digits: List.filled(6, ''),
      isButtonEnabled: false,
      status: OtpStatus.validating,
      errorMessage: null,
      verificationId: null, // Clear previous verification ID
    ));
    
    try {
      // For test phone numbers on iOS, handle differently
      if (Platform.isIOS && state.mobileNumber == '+911111111111') {
        debugPrint('iOS test phone - using test mode for resend');
        emit(state.copyWith(
          verificationId: 'test-verification-id',
          status: OtpStatus.initial,
        ));
        add(StartTimerEvent());
        return;
      }
      
      // For Android test numbers
      if (Platform.isAndroid && state.mobileNumber == '+911111111111') {
        await _auth.setSettings(
          appVerificationDisabledForTesting: true,
          forceRecaptchaFlow: false,
        );
      }
      
      // Use the mobile number directly (it already includes +91)
      await _auth.verifyPhoneNumber(
        phoneNumber: state.mobileNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          add(VerificationCompleted(credential.smsCode ?? ''));
        },
        verificationFailed: (FirebaseAuthException e) {
          add(VerificationFailed(e.message ?? 'Verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          add(CodeSent(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout with verificationId: $verificationId');
          if (state.verificationId == null) {
            add(CodeSent(verificationId));
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Failed to resend OTP: $e',
      ));
    }
  }

  Future<void> _onSubmitOtp(SubmitOtpPressed event, Emitter<OtpState> emit) async {
    debugPrint('Current verificationId: ${state.verificationId}');
    debugPrint('Current status: ${state.status}');
    debugPrint('Current phone number: ${state.mobileNumber}');
    
    if (!state.isButtonEnabled) return;

    emit(state.copyWith(status: OtpStatus.validating));

    final code = state.digits.join();
    debugPrint('OTP code: $code');
    
    try {
      // Special handling for test phone number
      if (state.mobileNumber == '+911111111111' && (code == '000000' || code == '123456')) {
        debugPrint('Using test phone number with test OTP');
        
        // For iOS test numbers, bypass Firebase authentication
        if (Platform.isIOS) {
          debugPrint('iOS test mode - bypassing Firebase authentication');
          await _handleSuccessfulSignIn(state.mobileNumber, emit);
          return;
        }
        
        // For Android, try to create a test credential
        try {
          await _auth.signOut();
          
          final credential = PhoneAuthProvider.credential(
            verificationId: state.verificationId ?? 'test-verification-id',
            smsCode: code,
          );
          
          final userCredential = await _auth.signInWithCredential(credential);
          
          if (userCredential.user != null) {
            await _handleSuccessfulSignIn(state.mobileNumber, emit);
          } else {
            throw Exception('Sign in successful but user is null');
          }
        } catch (e) {
          debugPrint('Sign in with test credential failed: $e');
          if (code == '000000' || code == '123456') {
            debugPrint('Proceeding with test flow without Firebase authentication');
            await _handleSuccessfulSignIn(state.mobileNumber, emit);
          } else {
            throw e;
          }
        }
        return;
      }
      
      // Normal flow for real phone numbers
      if (state.verificationId == null || state.verificationId!.isEmpty) {
        debugPrint('Verification ID is null or empty');
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: 'Verification ID not available. Please try again.',
        ));
        return;
      }

      // Verify OTP with Firebase
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: code,
      );
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if sign in was successful
      if (userCredential.user != null) {
        await _handleSuccessfulSignIn(state.mobileNumber, emit);
      } else {
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: 'Failed to verify OTP. Please try again.',
        ));
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Verification session expired. Please request a new OTP.';
          break;
        case 'session-expired':
          errorMessage = 'Session expired. Please request a new OTP.';
          break;
        default:
          errorMessage = e.message ?? 'Invalid OTP, please try again';
      }
      
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: errorMessage,
      ));
    } on UnauthorizedException catch (e) {
      emit(state.copyWith(
        status: OtpStatus.unauthorized,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Error verifying OTP: $e',
      ));
    }
  }

  Future<void> _handleSuccessfulSignIn(String mobileNumber, Emitter<OtpState> emit) async {
    try {
      // Extract just the phone number without country code for API
      String phoneForApi = mobileNumber;
      debugPrint('Original mobile number: $phoneForApi');
      
      if (phoneForApi.startsWith('+91')) {
        phoneForApi = phoneForApi.substring(3); // Remove +91
      }
      debugPrint('Phone number for API: $phoneForApi');
      
      // Call the API to register the partner
      final response = await _apiServices.registerPartner(phoneForApi);
      debugPrint('API Response: ${response.status}, ${response.message}');
      
      // Debug print the response data structure
      debugPrint('Response data type: ${response.data?.runtimeType}');
      debugPrint('Response data: $response');
      
      // Extract and directly save authentication data
      if (response.status == 'SUCCESS' || response.status == 'EXISTS') {
        try {
          // Check if response body contains data
          final responseBody = response.data;
          
          if (responseBody != null) {
            // Try to extract token and userId/partnerId
            String? token;
            dynamic userId;
            
            // Extract from regular Map<String, dynamic>
            if (responseBody is Map<String, dynamic>) {
              if (responseBody.containsKey('token')) {
                token = responseBody['token'] as String;
              }
              
              // Check for partner_id first, then fall back to id
              if (responseBody.containsKey('partner_id')) {
                userId = responseBody['partner_id'];
                debugPrint('Found partner_id in response: $userId');
              } else if (responseBody.containsKey('id')) {
                userId = responseBody['id'];
                debugPrint('Found id in response: $userId');
              }
              
              // NEW: Extract supercategory ID if present
              if (responseBody.containsKey('supercategory')) {
                final supercategory = responseBody['supercategory'] as Map<String, dynamic>?;
                if (supercategory != null && supercategory.containsKey('id')) {
                  final supercategoryId = supercategory['id'] as String;
                  await TokenService.saveSupercategoryId(supercategoryId);
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('supercategory_id', supercategoryId);
                  
                  debugPrint('Supercategory ID saved for new user: $supercategoryId');
                }
              }
            }
            
            // Save token if available
            if (token != null && token.isNotEmpty) {
              // Save to both TokenService and SharedPreferences
              await TokenService.saveToken(token);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', token);
              
              debugPrint('Token saved for new user: ${token.substring(0, min(20, token.length))}...');
              
              // Verify token was saved
              final savedToken = await TokenService.getToken();
              final prefToken = prefs.getString('token');
              
              debugPrint('TokenService token saved: ${savedToken != null}');
              debugPrint('SharedPreferences token saved: ${prefToken != null}');
            } else {
              debugPrint('WARNING: Could not find token in response');
              
              // Try direct extraction from response string if all else fails
              try {
                final responseStr = response.toString();
                if (responseStr.contains('token')) {
                  final tokenStartIndex = responseStr.indexOf('token') + 8; // "token":"
                  final tokenEndIndex = responseStr.indexOf('"', tokenStartIndex);
                  if (tokenStartIndex > 0 && tokenEndIndex > tokenStartIndex) {
                    final extractedToken = responseStr.substring(tokenStartIndex, tokenEndIndex);
                    if (extractedToken.isNotEmpty) {
                      await TokenService.saveToken(extractedToken);
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('token', extractedToken);
                      
                      debugPrint('Token extracted and saved as fallback: ${extractedToken.substring(0, min(20, extractedToken.length))}...');
                    }
                  }
                }
              } catch (e) {
                debugPrint('Error trying to extract token as fallback: $e');
              }
            }
            
            // Save user ID if available
            if (userId != null) {
              // Save to both TokenService and SharedPreferences
              await TokenService.saveUserId(userId);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_id', userId.toString());
              
              debugPrint('User ID saved for new user: $userId');
              
              // Verify user ID was saved
              final savedUserId = await TokenService.getUserId();
              final prefUserId = prefs.getString('user_id');
              
              debugPrint('TokenService user ID saved: ${savedUserId != null}');
              debugPrint('SharedPreferences user ID saved: ${prefUserId != null}');
            } else {
              debugPrint('WARNING: Could not find user ID in response');
              
              // Try direct extraction from partner_id or id using regex
              try {
                final responseStr = response.toString();
                if (responseStr.contains('"partner_id"')) {
                  final idPattern = RegExp(r'"partner_id":"([^"]+)"');
                  final match = idPattern.firstMatch(responseStr);
                  if (match != null && match.groupCount >= 1) {
                    final extractedId = match.group(1);
                    if (extractedId != null && extractedId.isNotEmpty) {
                      await TokenService.saveUserId(extractedId);
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_id', extractedId);
                      
                      debugPrint('Partner ID extracted and saved as fallback: $extractedId');
                    }
                  }
                } else if (responseStr.contains('"id":')) {
                  final idPattern = RegExp(r'"id":(\d+)');
                  final match = idPattern.firstMatch(responseStr);
                  if (match != null && match.groupCount >= 1) {
                    final extractedId = match.group(1);
                    if (extractedId != null && extractedId.isNotEmpty) {
                      await TokenService.saveUserId(extractedId);
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_id', extractedId);
                      
                      debugPrint('User ID extracted and saved as fallback: $extractedId');
                    }
                  }
                }
              } catch (e) {
                debugPrint('Error trying to extract user ID as fallback: $e');
              }
            }
          } else {
            debugPrint('WARNING: Response body is null');
            
            // Try direct extraction from raw response
            try {
              final responseStr = response.toString();
              debugPrint('Raw response: $responseStr');
              
              // Extract token using regex
              final tokenPattern = RegExp(r'"token":"([^"]+)"');
              final tokenMatch = tokenPattern.firstMatch(responseStr);
              if (tokenMatch != null && tokenMatch.groupCount >= 1) {
                final extractedToken = tokenMatch.group(1);
                if (extractedToken != null && extractedToken.isNotEmpty) {
                  await TokenService.saveToken(extractedToken);
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('token', extractedToken);
                  
                  debugPrint('Token extracted and saved using regex: ${extractedToken.substring(0, min(20, extractedToken.length))}...');
                }
              }
              
              // Extract ID using regex - check for partner_id first
              final partnerIdPattern = RegExp(r'"partner_id":"([^"]+)"');
              final partnerIdMatch = partnerIdPattern.firstMatch(responseStr);
              if (partnerIdMatch != null && partnerIdMatch.groupCount >= 1) {
                final extractedId = partnerIdMatch.group(1);
                if (extractedId != null && extractedId.isNotEmpty) {
                  await TokenService.saveUserId(extractedId);
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_id', extractedId);
                  
                  debugPrint('Partner ID extracted and saved using regex: $extractedId');
                }
              } else {
                // Fall back to id if partner_id not found
                final idPattern = RegExp(r'"id":(\d+)');
                final idMatch = idPattern.firstMatch(responseStr);
                if (idMatch != null && idMatch.groupCount >= 1) {
                  final extractedId = idMatch.group(1);
                  if (extractedId != null && extractedId.isNotEmpty) {
                    await TokenService.saveUserId(extractedId);
                    
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_id', extractedId);
                    
                    debugPrint('User ID extracted and saved using regex: $extractedId');
                  }
                }
              }
              
              // NEW: Extract supercategory ID using regex
              final supercategoryIdPattern = RegExp(r'"supercategory":\s*\{[^}]*"id":\s*"([^"]+)"');
              final supercategoryIdMatch = supercategoryIdPattern.firstMatch(responseStr);
              if (supercategoryIdMatch != null && supercategoryIdMatch.groupCount >= 1) {
                final extractedSupercategoryId = supercategoryIdMatch.group(1);
                if (extractedSupercategoryId != null && extractedSupercategoryId.isNotEmpty) {
                  await TokenService.saveSupercategoryId(extractedSupercategoryId);
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('supercategory_id', extractedSupercategoryId);
                  
                  debugPrint('Supercategory ID extracted and saved using regex: $extractedSupercategoryId');
                }
              }
            } catch (e) {
              debugPrint('Error trying to extract using regex: $e');
            }
          }
          
          // Always save mobile number
          await TokenService.saveMobile(phoneForApi);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('mobile', phoneForApi);
          
          debugPrint('Mobile saved: $phoneForApi');

          // ✅ FCM TOKEN REGISTRATION - INITIALIZE AND REGISTER AFTER SUCCESSFUL LOGIN
          try {
            debugPrint('🔔 Starting FCM token registration after successful login...');
            
            // Initialize notification service if not already initialized
            if (!_notificationService.isInitialized) {
              debugPrint('🔔 Initializing notification service...');
              await _notificationService.initialize();
            }
            
            // Register FCM token with server
            debugPrint('🔔 Registering FCM token with server...');
            final fcmRegistrationSuccess = await _notificationService.registerTokenWithServer();
            
            if (fcmRegistrationSuccess) {
              debugPrint('✅ FCM token registered successfully with server');
            } else {
              debugPrint('❌ Failed to register FCM token with server (but continuing with login)');
              // Don't fail the login process if FCM registration fails
            }
            
            // Subscribe to relevant topics (optional)
            try {
              final savedUserId = await TokenService.getUserId();
              if (savedUserId != null) {
                await _notificationService.subscribeToTopic('partner_$savedUserId');
                await _notificationService.subscribeToTopic('all_partners');
                debugPrint('✅ Subscribed to FCM topics');
              }
            } catch (topicError) {
              debugPrint('❌ Error subscribing to FCM topics: $topicError');
              // Don't fail login if topic subscription fails
            }
            
          } catch (fcmError) {
            debugPrint('❌ Error during FCM setup: $fcmError');
            // Don't fail the login process if FCM setup fails
            // The user can still use the app without notifications
          }
          
        } catch (e) {
          debugPrint('Error processing authentication data: $e');
        }
        
        // Let's also try to access the response raw data as a manual last resort
        try {
          // Try parsing from the raw message JSON
          final rawResponse = response.message;
          if (rawResponse != null && rawResponse.contains('token')) {
            debugPrint('Attempting to parse from message: $rawResponse');
          }
        } catch (e) {
          debugPrint('Error parsing raw message: $e');
        }
        
        // Check the status to determine where to navigate
        final status = response.status;
        debugPrint('Setting navigation with API status: $status');
        
        if (status == 'SUCCESS') {
          // New user registered successfully - route to details add view
          emit(state.copyWith(
            status: OtpStatus.success,
            apiStatus: 'SUCCESS',
          ));
        } else if (status == 'EXISTS') {
          // User already exists - route to home page instead of details page
          emit(state.copyWith(
            status: OtpStatus.success,
            apiStatus: 'EXISTS',
          ));
        }
      } else {
        // API call was not successful
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: response.message ?? 'Registration failed',
        ));
      }
    } catch (e) {
      debugPrint('Error in _handleSuccessfulSignIn: $e');
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: 'Error during registration: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}