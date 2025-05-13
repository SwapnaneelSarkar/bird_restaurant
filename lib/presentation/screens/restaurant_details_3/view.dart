// lib/presentation/screens/restaurant_details/submit_documents/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../../ui_components/custom_button_slim.dart';
import '../../../ui_components/legal_card.dart';
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
          'Restaurant Details',
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

                  Text(
                    'Legal Documents',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s14,
                      fontWeight: FontWeightManager.medium,
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  
                  LegalDocumentCard(
                    title: 'FSSAI License',
                    description: 'Upload your FSSAI license',
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

                  Text(
                    'Restaurant Photos',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s14,
                      fontWeight: FontWeightManager.medium,
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  
                  LegalDocumentCard(
                    title: 'Add Photos',
                    description: 'Upload restaurant photos',
                    hint: 'Multiple photos allowed',
                    icon: Icons.add_photo_alternate,
                    uploaded: state.restaurantPhotos.isNotEmpty,
                    fileName: state.restaurantPhotos.isNotEmpty
                        ? '${state.restaurantPhotos.length} photos selected'
                        : null,
                    onTap: () => bloc.add(const UploadPhotosEvent()),
                    onRemove: state.restaurantPhotos.isNotEmpty
                        ? () => bloc.add(RemovePhotoEvent(state.restaurantPhotos.length - 1))
                        : null,
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
              onPressed: state.canProceed && !state.isSubmitting
                  ? () => bloc.add(const SubmitDocumentsEvent())
                  : null,
            ),
          );
        },
      ),
    );
  }
}