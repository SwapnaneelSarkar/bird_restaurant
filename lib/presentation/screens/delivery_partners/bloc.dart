import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/delivery_partners_service.dart';
import '../../../services/api_responses.dart';
import '../../../models/delivery_partner_model.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/token_service.dart';
import 'package:flutter/foundation.dart';

class DeliveryPartnersBloc extends Bloc<DeliveryPartnersEvent, DeliveryPartnersState> {
  final DeliveryPartnersService _deliveryPartnersService;

  DeliveryPartnersBloc({required DeliveryPartnersService deliveryPartnersService})
      : _deliveryPartnersService = deliveryPartnersService,
        super(DeliveryPartnersInitial()) {
    
    on<LoadDeliveryPartners>(_onLoadDeliveryPartners);
    on<RefreshDeliveryPartners>(_onRefreshDeliveryPartners);
    on<AddDeliveryPartner>(_onAddDeliveryPartner);
    on<EditDeliveryPartner>(_onEditDeliveryPartner);
    on<DeleteDeliveryPartner>(_onDeleteDeliveryPartner);
  }

  Future<void> _onLoadDeliveryPartners(
    LoadDeliveryPartners event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    emit(DeliveryPartnersLoading());

    try {
      final response = await _deliveryPartnersService.getDeliveryPartnersLegacy();
      
      if (response.success && response.data != null) {
        // Convert the data back to DeliveryPartner objects
        final partners = (response.data as List)
            .map((json) => DeliveryPartner.fromJson(json))
            .toList();
        emit(DeliveryPartnersLoaded(partners));
      } else {
        emit(DeliveryPartnersError(response.message ?? 'Failed to load delivery partners'));
      }
    } catch (e) {
      emit(DeliveryPartnersError('Failed to load delivery partners: $e'));
    }
  }

  Future<void> _onRefreshDeliveryPartners(
    RefreshDeliveryPartners event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    List<DeliveryPartner> currentPartners = [];
    if (state is DeliveryPartnersLoaded) {
      final currentState = state as DeliveryPartnersLoaded;
      currentPartners = currentState.partners;
      emit(DeliveryPartnersRefreshing(currentState.partners));
    }

    try {
      final response = await _deliveryPartnersService.getDeliveryPartnersLegacy();
      
      if (response.success && response.data != null) {
        // Convert the data back to DeliveryPartner objects
        final partners = (response.data as List)
            .map((json) => DeliveryPartner.fromJson(json))
            .toList();
        emit(DeliveryPartnersLoaded(partners));
      } else {
        emit(DeliveryPartnersError(response.message ?? 'Failed to refresh delivery partners', partners: currentPartners));
      }
    } catch (e) {
      emit(DeliveryPartnersError('Failed to refresh delivery partners: $e', partners: currentPartners));
    }
  }

  Future<void> _onAddDeliveryPartner(
    AddDeliveryPartner event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    List<DeliveryPartner> currentPartners = [];
    if (state is DeliveryPartnersLoaded) {
      final currentState = state as DeliveryPartnersLoaded;
      currentPartners = currentState.partners;
    }
    
    emit(DeliveryPartnersLoading());
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        emit(DeliveryPartnersError('No token found. Please login again.', partners: currentPartners));
        return;
      }
      
      debugPrint('DeliveryPartnersBloc: Starting onboarding process...');
      debugPrint('DeliveryPartnersBloc: Partner ID: ${event.partnerId}');
      debugPrint('DeliveryPartnersBloc: Phone: ${event.phone}');
      debugPrint('DeliveryPartnersBloc: Name: ${event.name}');
      debugPrint('DeliveryPartnersBloc: Email: ${event.email}');
      debugPrint('DeliveryPartnersBloc: Username: ${event.username}');
      debugPrint('DeliveryPartnersBloc: License Photo: ${event.licensePhotoPath ?? 'Not provided'}');
      debugPrint('DeliveryPartnersBloc: Vehicle Document: ${event.vehicleDocumentPath ?? 'Not provided'}');
      
      // Try the onboarding with retry mechanism
      ApiResponse? response;
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        try {
          debugPrint('DeliveryPartnersBloc: Attempt ${retryCount + 1} of ${maxRetries + 1}');
          
          response = await _deliveryPartnersService.onboardDeliveryPartner(
            partnerId: event.partnerId,
            phone: event.phone,
            name: event.name,
            email: event.email,
            username: event.username,
            password: event.password,
            licensePhotoPath: event.licensePhotoPath,
            vehicleDocumentPath: event.vehicleDocumentPath,
            token: token,
          );
          
          // If we get a response, break out of retry loop
          break;
        } catch (e) {
          retryCount++;
          debugPrint('DeliveryPartnersBloc: Attempt $retryCount failed: $e');
          
          if (retryCount > maxRetries) {
            debugPrint('DeliveryPartnersBloc: Max retries reached, throwing error');
            rethrow;
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
      
      debugPrint('DeliveryPartnersBloc: Onboarding response received');
      debugPrint('DeliveryPartnersBloc: Success: ${response?.success}');
      debugPrint('DeliveryPartnersBloc: Status: ${response?.status}');
      debugPrint('DeliveryPartnersBloc: Message: ${response?.message}');
      
      if (response == null) {
        debugPrint('DeliveryPartnersBloc: No response received');
        emit(DeliveryPartnersError('No response received from server. Please try again.', partners: currentPartners));
        return;
      }
      
      if (response.success) {
        debugPrint('DeliveryPartnersBloc: Onboarding successful, refreshing partners list');
        add(RefreshDeliveryPartners());
        emit(DeliveryPartnerAdded());
      } else {
          String errorMessage = response.message ?? 'Failed to add delivery partner';
          
          // Provide more specific error messages based on status
          if (response.status == 'TIMEOUT') {
            errorMessage = 'Request timed out. The server is taking too long to respond. Please try again in a few moments.';
            debugPrint('DeliveryPartnersBloc: Onboarding timed out - $errorMessage');
            emit(DeliveryPartnersTimeout(errorMessage, partners: currentPartners));
          } else if (response.status == 'ERROR' && errorMessage.contains('504')) {
            errorMessage = 'Server is temporarily unavailable. Please try again in a few minutes.';
            debugPrint('DeliveryPartnersBloc: Onboarding failed with 504 - $errorMessage');
            emit(DeliveryPartnersTimeout(errorMessage, partners: currentPartners));
          } else if (response.status == 'ERROR' && errorMessage.contains('413')) {
            errorMessage = 'File size too large. Please compress your images and try again.';
            debugPrint('DeliveryPartnersBloc: Onboarding failed with 413 - $errorMessage');
            emit(DeliveryPartnersError(errorMessage, partners: currentPartners));
          } else {
            debugPrint('DeliveryPartnersBloc: Onboarding failed - $errorMessage');
            emit(DeliveryPartnersError(errorMessage, partners: currentPartners));
          }
        }
    } catch (e) {
      debugPrint('DeliveryPartnersBloc: Exception during onboarding: $e');
      String errorMessage = 'Failed to add delivery partner. Please try again.';
      
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your connection and try again.';
        emit(DeliveryPartnersTimeout(errorMessage, partners: currentPartners));
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
        emit(DeliveryPartnersError(errorMessage, partners: currentPartners));
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
        emit(DeliveryPartnersError(errorMessage, partners: currentPartners));
      } else {
        emit(DeliveryPartnersError(errorMessage, partners: currentPartners));
      }
    }
  }

  Future<void> _onEditDeliveryPartner(
    EditDeliveryPartner event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    emit(DeliveryPartnersLoading());
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        emit(DeliveryPartnerEditError('No token found. Please login again.'));
        return;
      }
      final response = await _deliveryPartnersService.updateDeliveryPartner(
        deliveryPartnerId: event.deliveryPartnerId,
        name: event.name,
        phone: event.phone,
        email: event.email,
        vehicleType: event.vehicleType,
        vehicleNumber: event.vehicleNumber,
        licensePhotoPath: event.licensePhotoPath,
        vehicleDocumentPath: event.vehicleDocumentPath,
        token: token,
      );
      if (response.success) {
        add(RefreshDeliveryPartners());
        emit(DeliveryPartnerEdited());
      } else {
        emit(DeliveryPartnerEditError(response.message ?? 'Failed to edit delivery partner'));
      }
    } catch (e) {
      emit(DeliveryPartnerEditError(e.toString()));
    }
  }

  Future<void> _onDeleteDeliveryPartner(
    DeleteDeliveryPartner event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    List<DeliveryPartner> currentPartners = [];
    if (state is DeliveryPartnersLoaded) {
      final currentState = state as DeliveryPartnersLoaded;
      currentPartners = currentState.partners;
    }
    
    // Show loading state while deleting
    emit(DeliveryPartnersLoading());
    
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        emit(DeliveryPartnersError('No token found. Please login again.', partners: currentPartners));
        return;
      }
      
      final response = await _deliveryPartnersService.deleteDeliveryPartner(
        event.deliveryPartnerId,
        token,
      );
      
      if (response.success) {
        // Show success state briefly, then refresh
        emit(DeliveryPartnerDeleted());
        // Add a small delay to show the success state
        await Future.delayed(const Duration(milliseconds: 100));
        // Refresh the partners list
        add(RefreshDeliveryPartners());
      } else {
        emit(DeliveryPartnersError(response.message ?? 'Failed to delete delivery partner', partners: currentPartners));
      }
    } catch (e) {
      emit(DeliveryPartnersError('Failed to delete delivery partner: $e', partners: currentPartners));
    }
  }
} 