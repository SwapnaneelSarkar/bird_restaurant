// lib/presentation/screens/restaurant_details/submit_documents/event.dart

import 'package:equatable/equatable.dart';

enum DocumentType { fssai, gst, pan }

abstract class RestaurantDocumentsEvent extends Equatable {
  const RestaurantDocumentsEvent();
  @override
  List<Object?> get props => [];
}

class UploadDocumentEvent extends RestaurantDocumentsEvent {
  final DocumentType type;
  const UploadDocumentEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class UploadPhotosEvent extends RestaurantDocumentsEvent {
  const UploadPhotosEvent();
}

class RemoveDocumentEvent extends RestaurantDocumentsEvent {
  final DocumentType type;
  const RemoveDocumentEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class RemovePhotoEvent extends RestaurantDocumentsEvent {
  final int index;
  const RemovePhotoEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class SubmitDocumentsEvent extends RestaurantDocumentsEvent {
  const SubmitDocumentsEvent();
}