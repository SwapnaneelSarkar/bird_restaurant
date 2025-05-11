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

  const RestaurantDocumentsState({
    required this.uploadedDocs,
    this.restaurantPhotos = const [],
    this.isSubmitting = false,
    this.submissionSuccess,
    this.submissionMessage,
    this.errorMessage,  // Add this parameter
  });

  RestaurantDocumentsState copyWith({
    Map<DocumentType, File?>? uploadedDocs,
    List<File>? restaurantPhotos,
    bool? isSubmitting,
    bool? submissionSuccess,
    String? submissionMessage,
    String? errorMessage,  // Add this parameter
  }) =>
      RestaurantDocumentsState(
        uploadedDocs: uploadedDocs ?? this.uploadedDocs,
        restaurantPhotos: restaurantPhotos ?? this.restaurantPhotos,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submissionSuccess: submissionSuccess ?? this.submissionSuccess,
        submissionMessage: submissionMessage ?? this.submissionMessage,
        errorMessage: errorMessage,  // Note: no null coalescing here
      );

  bool get allLegalUploaded =>
      uploadedDocs.values.every((file) => file != null);

  bool get canProceed => allLegalUploaded && restaurantPhotos.isNotEmpty;

  @override
  List<Object?> get props => [
        uploadedDocs,
        restaurantPhotos,
        isSubmitting,
        submissionSuccess,
        submissionMessage,
        errorMessage,  // Add this to props
      ];
}