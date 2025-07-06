abstract class DeliveryPartnersEvent {}

class LoadDeliveryPartners extends DeliveryPartnersEvent {}

class RefreshDeliveryPartners extends DeliveryPartnersEvent {}

class AddDeliveryPartner extends DeliveryPartnersEvent {
  final String partnerId;
  final String phone;
  final String name;
  final String? licensePhotoPath;
  final String? vehicleDocumentPath;

  AddDeliveryPartner({
    required this.partnerId,
    required this.phone,
    required this.name,
    this.licensePhotoPath,
    this.vehicleDocumentPath,
  });
} 