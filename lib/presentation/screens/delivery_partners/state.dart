import '../../../models/delivery_partner_model.dart';

abstract class DeliveryPartnersState {}

class DeliveryPartnersInitial extends DeliveryPartnersState {}

class DeliveryPartnersLoading extends DeliveryPartnersState {}

class DeliveryPartnersLoaded extends DeliveryPartnersState {
  final List<DeliveryPartner> partners;

  DeliveryPartnersLoaded(this.partners);
}

class DeliveryPartnersError extends DeliveryPartnersState {
  final String message;
  final List<DeliveryPartner>? partners;

  DeliveryPartnersError(this.message, {this.partners});
}

class DeliveryPartnersTimeout extends DeliveryPartnersState {
  final String message;
  final List<DeliveryPartner>? partners;

  DeliveryPartnersTimeout(this.message, {this.partners});
}

class DeliveryPartnersRefreshing extends DeliveryPartnersState {
  final List<DeliveryPartner> partners;

  DeliveryPartnersRefreshing(this.partners);
}

class DeliveryPartnerAdded extends DeliveryPartnersState {}

class DeliveryPartnerEdited extends DeliveryPartnersState {}

class DeliveryPartnerEditError extends DeliveryPartnersState {
  final String message;
  DeliveryPartnerEditError(this.message);
} 