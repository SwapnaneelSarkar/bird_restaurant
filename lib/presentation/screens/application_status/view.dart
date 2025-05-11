import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui_components/estimate_card.dart';
import '../../../ui_components/status_timeline.dart';
import '../../../ui_components/custom_button_slim.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class ApplicationStatusView extends StatelessWidget {
  final String? mobileNumber;

  const ApplicationStatusView({
    Key? key,
    this.mobileNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationStatusBloc()..add(FetchApplicationStatus()),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Application Status',
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s18,
            fontWeight: FontWeightManager.semiBold,
            color: ColorManager.black,
          ),
        ),
      ),
      body: BlocBuilder<ApplicationStatusBloc, ApplicationStatusState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ApplicationStatusBloc>().add(FetchApplicationStatus());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final sidePad = isTablet ? constraints.maxWidth * 0.1 : constraints.maxWidth * 0.04;
                final vertPad = constraints.maxHeight * 0.02;
                final iconSize = isTablet ? constraints.maxWidth * 0.12 : constraints.maxWidth * 0.4;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sidePad,
                    vertical: vertPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStatusIcon(state, iconSize),
                      SizedBox(height: vertPad),
                      _buildStatusTitle(state),
                      const SizedBox(height: 8),
                      _buildStatusSubtitle(state),
                      SizedBox(height: vertPad * 1.5),

                      // Timeline steps
                      for (int i = 0; i < state.steps.length; i++) ...[
                        StatusTimelineItem(
                          step: state.steps[i],
                          isLast: i == state.steps.length - 1,
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(height: vertPad * 2),

                      // Estimated time card
                      EstimatedReviewCard(
                        message: state.estimatedTime,
                      ),

                      SizedBox(height: vertPad * 2),

                      // Restaurant details (if available)
                      if (state.restaurantData != null) ...[
                        _buildRestaurantDetails(state.restaurantData!),
                        SizedBox(height: vertPad * 2),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: NextButton(
            label: 'Contact Support',
            suffixIcon: Icons.headset_mic,
            onPressed: () {
              context.read<ApplicationStatusBloc>().add(ContactSupportPressed());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ApplicationStatusState state, double iconSize) {
    IconData icon;
    Color color;

    if (state.applicationStatus == 7) {
      icon = Icons.cancel_outlined;
      color = Colors.red;
    } else if (state.applicationStatus == 1) {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    } else {
      icon = Icons.timer_outlined;
      color = ColorManager.primary;
    }

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(.1),
      ),
      child: Icon(
        icon,
        size: iconSize * 0.425,
        color: color,
      ),
    );
  }

  Widget _buildStatusTitle(ApplicationStatusState state) {
    String title;
    if (state.applicationStatus == 7) {
      title = 'Application Rejected';
    } else if (state.applicationStatus == 1) {
      title = 'Application Approved';
    } else {
      title = 'Under Review';
    }

    return Text(
      title,
      style: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontSize: FontSize.s20,
        fontWeight: FontWeightManager.semiBold,
        color: ColorManager.black,
      ),
    );
  }

  Widget _buildStatusSubtitle(ApplicationStatusState state) {
    String text;
    if (state.applicationStatus == 7) {
      text = 'Your restaurant application was not approved';
    } else if (state.applicationStatus == 1) {
      text = 'Congratulations! Your restaurant has been approved';
    } else {
      text = 'Your restaurant application is being reviewed by our team';
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontSize: FontSize.s14,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildRestaurantDetails(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant Details',
            style: TextStyle(
              fontFamily: FontConstants.fontFamily,
              fontSize: FontSize.s18,
              fontWeight: FontWeightManager.semiBold,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 16),
          if (data['restaurant_name'] != null)
            _buildDetailRow('Restaurant Name', data['restaurant_name']),
          if (data['address'] != null)
            _buildDetailRow('Address', data['address']),
          if (data['email'] != null)
            _buildDetailRow('Email', data['email']),
          if (data['category'] != null)
            _buildDetailRow('Category', data['category']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: FontConstants.fontFamily,
              fontSize: FontSize.s14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: FontConstants.fontFamily,
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }
}