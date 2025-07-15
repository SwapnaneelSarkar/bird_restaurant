import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/delivery_partners_service.dart';
import '../../../models/delivery_partner_model.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/token_service.dart';

class DeliveryPartnersBloc extends Bloc<DeliveryPartnersEvent, DeliveryPartnersState> {
  final DeliveryPartnersService _deliveryPartnersService;

  DeliveryPartnersBloc({required DeliveryPartnersService deliveryPartnersService})
      : _deliveryPartnersService = deliveryPartnersService,
        super(DeliveryPartnersInitial()) {
    
    on<LoadDeliveryPartners>(_onLoadDeliveryPartners);
    on<RefreshDeliveryPartners>(_onRefreshDeliveryPartners);
    on<AddDeliveryPartner>(_onAddDeliveryPartner);
    on<EditDeliveryPartner>(_onEditDeliveryPartner);
  }

  Future<void> _onLoadDeliveryPartners(
    LoadDeliveryPartners event,
    Emitter<DeliveryPartnersState> emit,
  ) async {
    emit(DeliveryPartnersLoading());

    try {
      final response = await _deliveryPartnersService.getDeliveryPartners();
      
      if (response.success && response.data != null) {
        emit(DeliveryPartnersLoaded(response.data!));
      } else {
        emit(DeliveryPartnersError(response.message));
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
      final response = await _deliveryPartnersService.getDeliveryPartners();
      
      if (response.success && response.data != null) {
        emit(DeliveryPartnersLoaded(response.data!));
      } else {
        emit(DeliveryPartnersError(response.message, partners: currentPartners));
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
      final response = await _deliveryPartnersService.onboardDeliveryPartner(
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
      if (response.success) {
        add(RefreshDeliveryPartners());
        emit(DeliveryPartnerAdded());
      } else {
        emit(DeliveryPartnersError(response.message ?? 'Failed to add delivery partner', partners: currentPartners));
      }
    } catch (e) {
      emit(DeliveryPartnersError(e.toString(), partners: currentPartners));
    }
  }

  Future<void> _onEditDeliveryPartner(
    EditDeliveryPartner event,
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
} 