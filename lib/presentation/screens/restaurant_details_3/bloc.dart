import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDocumentsBloc
    extends Bloc<RestaurantDocumentsEvent, RestaurantDocumentsState> {
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _imagePicker = ImagePicker();
  
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB per file
  static const int maxTotalUploadSize = 10 * 1024 * 1024; // 10MB total

  RestaurantDocumentsBloc()
      : super(RestaurantDocumentsState(
          uploadedDocs: {
            DocumentType.fssai: null,
            DocumentType.gst: null,
            DocumentType.pan: null,
          },
          restaurantPhotos: [],
        )) {
    on<UploadDocumentEvent>(_onUploadDocument);
    on<UploadPhotosEvent>(_onUploadPhotos);
    on<SubmitDocumentsEvent>(_onSubmitDocuments);
    on<RemoveDocumentEvent>(_onRemoveDocument);
    on<RemovePhotoEvent>(_onRemovePhoto);
  }

  Future<void> _onUploadDocument(
    UploadDocumentEvent event,
    Emitter<RestaurantDocumentsState> emit,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // For images, compress if needed
        if (result.files.single.name.toLowerCase().endsWith('.jpg') ||
            result.files.single.name.toLowerCase().endsWith('.jpeg') ||
            result.files.single.name.toLowerCase().endsWith('.png')) {
          file = await _compressImageIfNeeded(file);
        }
        
        // Check file size
        final fileSize = await file.length();
        if (fileSize > maxFileSize) {
          final sizeInMB = fileSize / (1024 * 1024);
          debugPrint('File too large: ${sizeInMB.toStringAsFixed(2)} MB');
          emit(state.copyWith(
            errorMessage: 'File size must be less than 5MB. Your file is ${sizeInMB.toStringAsFixed(2)}MB',
          ));
          return;
        }
        
        final updatedDocs = Map<DocumentType, File?>.from(state.uploadedDocs);
        updatedDocs[event.type] = file;
        emit(state.copyWith(
          uploadedDocs: updatedDocs,
          errorMessage: null,
        ));
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      emit(state.copyWith(
        errorMessage: 'Error selecting file: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadPhotos(
    UploadPhotosEvent event,
    Emitter<RestaurantDocumentsState> emit,
  ) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        List<File> photoFiles = [];
        for (var image in images) {
          File file = File(image.path);
          file = await _compressImageIfNeeded(file);
          
          final fileSize = await file.length();
          if (fileSize <= maxFileSize) {
            photoFiles.add(file);
          } else {
            debugPrint('Image too large after compression: ${image.path}');
          }
        }
        
        final updatedPhotos = List<File>.from(state.restaurantPhotos)..addAll(photoFiles);
        emit(state.copyWith(restaurantPhotos: updatedPhotos));
      }
    } catch (e) {
      debugPrint('Error picking photos: $e');
    }
  }

  Future<File> _compressImageIfNeeded(File file) async {
    final fileSize = await file.length();
    if (fileSize <= maxFileSize) {
      return file;
    }

    debugPrint('Compressing image: ${file.path}');
    
    // Calculate compression quality based on file size
    int quality = 80;
    if (fileSize > 10 * 1024 * 1024) {
      quality = 30;
    } else if (fileSize > 5 * 1024 * 1024) {
      quality = 50;
    } else if (fileSize > 2 * 1024 * 1024) {
      quality = 70;
    }

    final targetPath = file.path.replaceAll('.jpg', '_compressed.jpg')
                          .replaceAll('.jpeg', '_compressed.jpg')
                          .replaceAll('.png', '_compressed.jpg');

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      debugPrint('Compressed from ${fileSize / 1024}KB to ${compressedSize / 1024}KB');
      
      // If still too large, compress more
      if (compressedSize > maxFileSize && quality > 20) {
        return _compressImageIfNeeded(compressedFile);
      }
      
      return compressedFile;
    }
    
    return file;
  }

  Future<void> _onSubmitDocuments(
    SubmitDocumentsEvent event,
    Emitter<RestaurantDocumentsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    
    try {
      // First check directly in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('user_id');
      
      debugPrint('Token from SharedPreferences: ${token != null ? token.substring(0, 20) + '...' : 'null'}');
      debugPrint('User ID from SharedPreferences: $userId');
      
      if (token == null ) {
        throw UnauthorizedException('No token or user ID found. Please login again.');
      }
      
      // Check total size before submission
      int totalSize = 0;
      
      // Add document sizes
      for (var doc in state.uploadedDocs.values) {
        if (doc != null) {
          totalSize += await doc.length();
        }
      }
      
      // Add photo sizes
      for (var photo in state.restaurantPhotos) {
        totalSize += await photo.length();
      }
      
      debugPrint('Total upload size: ${totalSize / (1024 * 1024)} MB');
      
      if (totalSize > maxTotalUploadSize) {
        emit(state.copyWith(
          isSubmitting: false,
          submissionSuccess: false,
          submissionMessage: 'Total file size exceeds 10MB. Please compress or remove some files.',
        ));
        return;
      }
      
      // Get saved data from SharedPreferences
      
      // Get restaurant data
      final restaurantName = prefs.getString('restaurant_name') ?? '';
      final address = prefs.getString('restaurant_address') ?? '';
      final email = prefs.getString('restaurant_email') ?? '';
      
      // Get coordinates - this is the important part for location
      final latitude = prefs.getDouble('restaurant_latitude') ?? 0.0;
      final longitude = prefs.getDouble('restaurant_longitude') ?? 0.0;
      
      // Get selected cuisines and operational hours
      final selectedCuisines = prefs.getStringList('selected_cuisines') ?? [];
      final category = selectedCuisines
          .map((e) => e.split('.').last.toLowerCase())
          .join(', ');
      
      final operationalHours = prefs.getString('operational_hours') ?? '{}';
      
      debugPrint('Submitting with data:');
      debugPrint('Restaurant Name: $restaurantName');
      debugPrint('Address: $address');
      debugPrint('Email: $email');
      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');
      debugPrint('Category: $category');
      debugPrint('Operational Hours: $operationalHours');
      
      // Call updatePartnerWithAllFields API which includes coordinates
      final response = await _apiServices.updatePartnerWithAllFields(
        restaurantName: restaurantName,
        address: address,
        email: email,
        category: category,
        operationalHours: operationalHours,
        latitude: latitude.toString(), // Convert to string for API
        longitude: longitude.toString(), // Convert to string for API
        ownerName: prefs.getString('owner_name') ?? '', // Default empty if not set
        vegNonveg: prefs.getString('veg-nonveg') ?? 'veg', // Default to both if not set
        cookingTime: prefs.getString('cooking_time') ?? '30', // Default to 30 mins if not set
        fssaiLicense: state.uploadedDocs[DocumentType.fssai],
        gstCertificate: state.uploadedDocs[DocumentType.gst],
        panCard: state.uploadedDocs[DocumentType.pan],
        restaurantPhotos: state.restaurantPhotos,
      );
      
      if (response.success) {
        // Clear saved data except token and user ID
        await ApiServices.clearSavedData();
        
        emit(state.copyWith(
          isSubmitting: false,
          submissionSuccess: true,
          submissionMessage: response.message,
        ));
      } else {
        emit(state.copyWith(
          isSubmitting: false,
          submissionSuccess: false,
          submissionMessage: response.message,
        ));
      }
    } catch (e) {
      debugPrint('Error submitting documents: $e');
      
      String errorMessage;
      if (e.toString().contains('413 Request Entity Too Large')) {
        errorMessage = 'The total file size is too large. Please compress your images or upload smaller files.';
      } else if (e.toString().contains('Invalid response format')) {
        errorMessage = 'The server returned an unexpected response. This might be due to large file sizes.';
      } else {
        errorMessage = 'Failed to submit: ${e.toString()}';
      }
      
      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        submissionMessage: errorMessage,
      ));
    }
  }

  void _onRemoveDocument(
    RemoveDocumentEvent event,
    Emitter<RestaurantDocumentsState> emit,
  ) {
    final updatedDocs = Map<DocumentType, File?>.from(state.uploadedDocs);
    updatedDocs[event.type] = null;
    emit(state.copyWith(uploadedDocs: updatedDocs));
  }

  void _onRemovePhoto(
    RemovePhotoEvent event,
    Emitter<RestaurantDocumentsState> emit,
  ) {
    final updatedPhotos = List<File>.from(state.restaurantPhotos);
    if (event.index < updatedPhotos.length) {
      updatedPhotos.removeAt(event.index);
      emit(state.copyWith(restaurantPhotos: updatedPhotos));
    }
  }
}