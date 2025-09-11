abstract class DeliveryPartnersEvent {}

class LoadDeliveryPartners extends DeliveryPartnersEvent {}

class RefreshDeliveryPartners extends DeliveryPartnersEvent {}

class AddDeliveryPartner extends DeliveryPartnersEvent {
  final String partnerId;
  final String phone;
  final String name;
  final String email;
  final String username;
  final String password;
  final String? licensePhotoPath;
  final String? vehicleDocumentPath;

  AddDeliveryPartner({
    required this.partnerId,
    required this.phone,
    required this.name,
    required this.email,
    required this.username,
    required this.password,
    this.licensePhotoPath,
    this.vehicleDocumentPath,
  });

  List<Object?> get props => [partnerId, phone, name, email, username, password, licensePhotoPath, vehicleDocumentPath];
}

class EditDeliveryPartner extends DeliveryPartnersEvent {
  final String deliveryPartnerId;
  final String name;
  final String phone;
  final String? email;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? licensePhotoPath;
  final String? vehicleDocumentPath;

  EditDeliveryPartner({
    required this.deliveryPartnerId,
    required this.name,
    required this.phone,
    this.email,
    this.vehicleType,
    this.vehicleNumber,
    this.licensePhotoPath,
    this.vehicleDocumentPath,
  });

  List<Object?> get props => [deliveryPartnerId, name, phone, email, vehicleType, vehicleNumber, licensePhotoPath, vehicleDocumentPath];
}

class DeleteDeliveryPartner extends DeliveryPartnersEvent {
  final String deliveryPartnerId;

  DeleteDeliveryPartner({required this.deliveryPartnerId});

  List<Object?> get props => [deliveryPartnerId];
} 