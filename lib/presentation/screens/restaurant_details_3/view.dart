// lib/presentation/screens/restaurant_details/submit_documents/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../ui_components/custom_button_slim.dart';
import '../../../ui_components/legal_card.dart';
import '../../../ui_components/image_cropper_widget.dart';
import '../../../../ui_components/proggress_bar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';

import '../application_status/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDocumentsSubmitView extends StatelessWidget {
  const RestaurantDocumentsSubmitView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantDocumentsBloc(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  // Method to show validation popup alert
  void _showValidationAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Incomplete Documents',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          content: Text(
            'Please upload all required documents and at least one restaurant photo before submitting.',
            style: TextStyle(
              fontFamily: FontConstants.fontFamily,
              fontSize: FontSize.s14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to get missing items for detailed validation
  List<String> _getMissingItems(RestaurantDocumentsState state) {
    List<String> missing = [];
    
    // Only require FSSAI license for Food supercategory
    if (state.isFssaiRequired && state.uploadedDocs[DocumentType.fssai] == null) {
      missing.add('FSSAI License');
    }
    if (state.uploadedDocs[DocumentType.gst] == null) {
      missing.add('GST Certificate');
    }
    if (state.uploadedDocs[DocumentType.pan] == null) {
      missing.add('PAN Card');
    }
    if (state.restaurantPhotos.isEmpty) {
      missing.add('Restaurant Photos');
    }
    
    return missing;
  }

  // Method to show detailed validation popup
  void _showDetailedValidationAlert(BuildContext context, List<String> missingItems) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Missing Documents',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please upload the following required items:',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...missingItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantDocumentsBloc>();
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final sidePad = w * 0.04;
    final vertPad = h * 0.02;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 50,
        title: Text(
          'Store Details',
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s16,
            color: ColorManager.black,
            fontWeight: FontWeightManager.semiBold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: const StepProgressBar(
              currentStep: 3,
              totalSteps: 3,
            ),
          ),
        ),
      ),
      body: BlocConsumer<RestaurantDocumentsBloc, RestaurantDocumentsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.submissionSuccess != null) {
            if (state.submissionSuccess!) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.submissionMessage ?? 'Submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to next screen after success
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, __, ___) => const ApplicationStatusView(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.submissionMessage ?? 'Submission failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: sidePad,
                vertical: vertPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurant Documents',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s18,
                      fontWeight: FontWeightManager.bold,
                    ),
                  ),
                  SizedBox(height: h * 0.005),
                  Text(
                    'Upload required documents & photos',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: vertPad),

                  RichText(
                    text: TextSpan(
                      text: 'Legal Documents',
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s14,
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.black,
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  
                  LegalDocumentCard(
                    title: 'FSSAI License',
                    description: state.isFssaiRequired 
                        ? 'Upload your FSSAI license' 
                        : 'Upload your FSSAI license (Optional)',
                    hint: 'PDF, JPG or PNG (Max 5MB)',
                    icon: Icons.upload_file,
                    uploaded: state.uploadedDocs[DocumentType.fssai] != null,
                    fileName: state.uploadedDocs[DocumentType.fssai]?.path.split('/').last,
                    onTap: () => bloc.add(const UploadDocumentEvent(DocumentType.fssai)),
                    onRemove: () => bloc.add(const RemoveDocumentEvent(DocumentType.fssai)),
                  ),
                  
                  LegalDocumentCard(
                    title: 'GST Certificate',
                    description: 'Upload your GST certificate',
                    hint: 'PDF, JPG or PNG (Max 5MB)',
                    icon: Icons.upload_file,
                    uploaded: state.uploadedDocs[DocumentType.gst] != null,
                    fileName: state.uploadedDocs[DocumentType.gst]?.path.split('/').last,
                    onTap: () => bloc.add(const UploadDocumentEvent(DocumentType.gst)),
                    onRemove: () => bloc.add(const RemoveDocumentEvent(DocumentType.gst)),
                  ),
                  
                  LegalDocumentCard(
                    title: 'PAN Card',
                    description: 'Upload your PAN card',
                    hint: 'PDF, JPG or PNG (Max 5MB)',
                    icon: Icons.upload_file,
                    uploaded: state.uploadedDocs[DocumentType.pan] != null,
                    fileName: state.uploadedDocs[DocumentType.pan]?.path.split('/').last,
                    onTap: () => bloc.add(const UploadDocumentEvent(DocumentType.pan)),
                    onRemove: () => bloc.add(const RemoveDocumentEvent(DocumentType.pan)),
                  ),
                  
                  SizedBox(height: vertPad),

                  RichText(
                    text: TextSpan(
                      text: 'Store Photos',
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s14,
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.black,
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  
                  LegalDocumentCard(
                    title: 'Add Photos',
                    description: 'Upload store photos',
                    hint: 'Multiple photos allowed',
                    icon: Icons.add_photo_alternate,
                    uploaded: state.restaurantPhotos.isNotEmpty,
                    fileName: state.restaurantPhotos.isNotEmpty
                        ? '${state.restaurantPhotos.length} photos selected'
                        : null,
                    onTap: () => _showImagePicker(context, bloc),
                    onRemove: state.restaurantPhotos.isNotEmpty
                        ? () => bloc.add(RemovePhotoEvent(state.restaurantPhotos.length - 1))
                        : null,
                  ),
                  
                  // Add validation message section if items are missing
                  if (!state.canProceed)
                    Container(
                      margin: EdgeInsets.only(top: vertPad),
                      padding: EdgeInsets.all(w * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                              SizedBox(width: w * 0.02),
                              Text(
                                'Required Items Missing',
                                style: TextStyle(
                                  fontFamily: FontConstants.fontFamily,
                                  fontSize: FontSize.s14,
                                  fontWeight: FontWeightManager.semiBold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: h * 0.01),
                          Text(
                            state.isFssaiRequired
                                ? 'Please upload all legal documents and at least one store photo to proceed.'
                                : 'Please upload GST Certificate, PAN Card, and at least one store photo to proceed.',
                            style: TextStyle(
                              fontFamily: FontConstants.fontFamily,
                              fontSize: FontSize.s12,
                              color: Colors.orange.shade700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<RestaurantDocumentsBloc, RestaurantDocumentsState>(
        builder: (context, state) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: sidePad, vertical: h * 0.03),
            child: NextButton(
              label: state.isSubmitting ? 'Submitting...' : 'Submit',
              suffixIcon: Icons.arrow_forward,
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      if (state.canProceed) {
                        // Proceed with submission
                        bloc.add(const SubmitDocumentsEvent());
                      } else {
                        // Show validation alert
                        final missingItems = _getMissingItems(state);
                        if (missingItems.isNotEmpty) {
                          _showDetailedValidationAlert(context, missingItems);
                        } else {
                          _showValidationAlert(context);
                        }
                      }
                    },
            ),
          );
        },
      ),
    );
  }

  void _showImagePicker(BuildContext context, RestaurantDocumentsBloc bloc) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Navigate to crop screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperWidget(
            imagePath: image.path,
            aspectRatio: 16.0 / 9.0, // Restaurant photos typically use 16:9 aspect ratio
            onCropComplete: (File croppedFile) {
              // Add the cropped image to the photos list
              bloc.add(UploadPhotosEvent());
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }
}