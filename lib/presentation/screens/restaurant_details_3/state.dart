// lib/presentation/screens/restaurant_details/submit_documents/state.dart

import 'dart:io';
import 'package:equatable/equatable.dart';
import 'event.dart';

class RestaurantDocumentsState extends Equatable {
  final Map<DocumentType, File?> uploadedDocs;
  final List<File> restaurantPhotos;
  final bool isSubmitting;
  final bool? submissionSuccess;
  final String? submissionMessage;
  final String? errorMessage;  // Add this field
  final String? selectedSupercategoryId; // Add supercategory information

  const RestaurantDocumentsState({
    required this.uploadedDocs,
    this.restaurantPhotos = const [],
    this.isSubmitting = false,
    this.submissionSuccess,
    this.submissionMessage,
    this.errorMessage,  // Add this parameter
    this.selectedSupercategoryId, // Add supercategory parameter
  });

  RestaurantDocumentsState copyWith({
    Map<DocumentType, File?>? uploadedDocs,
    List<File>? restaurantPhotos,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? submissionMessage,
    String? errorMessage,  // Add this parameter
    String? selectedSupercategoryId, // Add supercategory parameter
  }) =>
      RestaurantDocumentsState(
        uploadedDocs: uploadedDocs ?? this.uploadedDocs,
        restaurantPhotos: restaurantPhotos ?? this.restaurantPhotos,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submissionSuccess: submissionSuccess ?? this.submissionSuccess,
        submissionMessage: submissionMessage ?? this.submissionMessage,
        errorMessage: errorMessage,  // Note: no null coalescing here
        selectedSupercategoryId: selectedSupercategoryId ?? this.selectedSupercategoryId,
      );

  bool get allLegalUploaded {
    // For Food supercategory (ID: "7acc47a2fa5a4eeb906a753b3"), require all documents
    if (selectedSupercategoryId == "7acc47a2fa5a4eeb906a753b3") {
      return uploadedDocs.values.every((file) => file != null);
    }
    // For other supercategories, FSSAI license is optional
    return uploadedDocs[DocumentType.gst] != null && 
           uploadedDocs[DocumentType.pan] != null;
  }

  bool get canProceed => allLegalUploaded && restaurantPhotos.isNotEmpty;

  bool get isFssaiRequired => selectedSupercategoryId == "7acc47a2fa5a4eeb906a753b3";

  @override
  List<Object?> get props => [
        uploadedDocs,
        restaurantPhotos,
        isSubmitting,
        submissionSuccess,
        submissionMessage,
        errorMessage,  // Add this to props
        selectedSupercategoryId,
      ];
}