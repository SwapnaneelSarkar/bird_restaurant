import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'event.dart';
import 'state.dart';

class DeliveryPartnerSigninBloc extends Bloc<DeliveryPartnerSigninEvent, DeliveryPartnerSigninState> {
  DeliveryPartnerSigninBloc() : super(DeliveryPartnerSigninState.initial()) {
    on<DeliveryPartnerUsernameChanged>(_onUsernameChanged);
    on<DeliveryPartnerPasswordChanged>(_onPasswordChanged);
    on<DeliveryPartnerSignInPressed>(_onSignInPressed);
  }

  void _onUsernameChanged(
      DeliveryPartnerUsernameChanged event, Emitter<DeliveryPartnerSigninState> emit) {
    emit(state.copyWith(
      username: event.username,
      isValid: event.username.isNotEmpty && state.password.isNotEmpty,
    ));
  }

  void _onPasswordChanged(
      DeliveryPartnerPasswordChanged event, Emitter<DeliveryPartnerSigninState> emit) {
    emit(state.copyWith(
      password: event.password,
      isValid: state.username.isNotEmpty && event.password.isNotEmpty,
    ));
  }

  Future<void> _onSignInPressed(
      DeliveryPartnerSignInPressed event, Emitter<DeliveryPartnerSigninState> emit) async {
    emit(state.copyWith(status: DeliveryPartnerSigninStatus.loading));
    
    try {
      final result = await DeliveryPartnerAuthService.authenticateDeliveryPartnerWithCredentials(
        username: state.username,
        password: state.password,
      );
      
      if (result['success']) {
        emit(state.copyWith(status: DeliveryPartnerSigninStatus.success));
      } else {
        emit(state.copyWith(
          status: DeliveryPartnerSigninStatus.error,
          errorMessage: result['message'] ?? 'Authentication failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DeliveryPartnerSigninStatus.error,
        errorMessage: 'Network error: $e',
      ));
    }
  }
} 