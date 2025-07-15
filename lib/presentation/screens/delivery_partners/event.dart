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

  @override
  List<Object?> get props => [partnerId, phone, name, email, username, password, licensePhotoPath, vehicleDocumentPath];
} 