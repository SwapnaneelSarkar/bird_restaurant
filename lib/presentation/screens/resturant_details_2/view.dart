// lib/presentation/screens/restaurant_details/category/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui_components/cuisine_card.dart';
import '../../../../ui_components/proggress_bar.dart';
import '../../../constants/enums.dart';
import '../../../ui_components/custom_button_slim.dart';
import '../../../ui_components/operations_card.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantCategoryView extends StatelessWidget {
  const RestaurantCategoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantCategoryBloc()..add(LoadSavedDataEvent()),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onSelected,
  ) async {
    debugPrint('⏱️ Opening time picker for initial=$initial');
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      debugPrint('⏰ Time picked: $picked');
      onSelected(picked);
    }
  }

  // Method to show validation message
  void _showValidationMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Method to get validation message
  String _getValidationMessage(RestaurantCategoryState state) {
    // Only require cuisine selection for Food supercategory
    if (state.shouldShowCuisineTypes && state.selected.isEmpty) {
      return 'Please select at least one cuisine type to continue.';
    }
    
    final enabledDays = state.days.where((day) => day.enabled).toList();
    if (enabledDays.isEmpty) {
      return 'Please set operational hours for at least one day to continue.';
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantCategoryBloc>();
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final sidePadding = w * 0.04;
    final verticalPadding = h * 0.02;

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
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: const StepProgressBar(
              currentStep: 2,
              totalSteps: 3,
            ),
          ),
        ),
      ),
      body: BlocBuilder<RestaurantCategoryBloc, RestaurantCategoryState>(
        builder: (context, state) {
          debugPrint(
              '🔄 Rebuild CategoryView: selected=${state.selected.map((e) => e.label).toList()}, '
              'canProceed=${state.canProceed}');
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sidePadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: verticalPadding),
                      Text(
                        'Store Category',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s18,
                          fontWeight: FontWeightManager.bold,
                        ),
                      ),
                      SizedBox(height: h * 0.005),
                      Text(
                        'Select cuisine types & set operation hours',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      // Conditionally show cuisine types section only for Food supercategory
                      if (state.shouldShowCuisineTypes) ...[
                        RichText(
                          text: TextSpan(
                            text: 'Type of Cuisine',
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
                        SizedBox(height: h * 0.01),
                        GridView.count(
                          crossAxisCount: (w > 600) ? 4 : 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: h * 0.015,
                          crossAxisSpacing: w * 0.03,
                          childAspectRatio: 1,
                          children: [
                            for (final ct in CuisineType.values)
                              CuisineCard(
                                cuisine: ct,
                                selected: state.selected.contains(ct),
                                onTap: () {
                                  debugPrint('🍽️ Tapped cuisine: ${ct.label}');
                                  bloc.add(ToggleCuisineEvent(ct));
                                },
                              ),
                          ],
                        ),
                        
                        // Add validation message for cuisine selection
                        if (state.selected.isEmpty)
                          Container(
                            margin: EdgeInsets.only(top: h * 0.01),
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.03,
                              vertical: h * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade600,
                                  size: 16,
                                ),
                                SizedBox(width: w * 0.02),
                                Expanded(
                                  child: Text(
                                    'Please select at least one cuisine type',
                                    style: TextStyle(
                                      fontFamily: FontConstants.fontFamily,
                                      fontSize: FontSize.s12,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      
                      SizedBox(height: verticalPadding * 1.5),
                      RichText(
                        text: TextSpan(
                          text: 'Operational Hours',
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
                      SizedBox(height: h * 0.01),
                      Column(
                        children: [
                          for (int i = 0; i < state.days.length; i++)
                            OperationalHourCard(
                              index: i,
                              day: state.days[i],
                              onToggleEnabled: () {
                                debugPrint(
                                    '☑️ Toggling day ${state.days[i].label}');
                                bloc.add(ToggleDayEnabledEvent(i));
                              },
                              onPickStart: () => _pickTime(
                                context,
                                state.days[i].start,
                                (t) => bloc.add(UpdateStartTimeEvent(i, t)),
                              ),
                              onPickEnd: () => _pickTime(
                                context,
                                state.days[i].end,
                                (t) => bloc.add(UpdateEndTimeEvent(i, t)),
                              ),
                            ),
                        ],
                      ),
                      
                      // Add validation message for operational hours
                      if (state.days.where((day) => day.enabled).isEmpty)
                        Container(
                          margin: EdgeInsets.only(top: h * 0.01),
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.03,
                            vertical: h * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.orange.shade600,
                                size: 16,
                              ),
                              SizedBox(width: w * 0.02),
                              Expanded(
                                child: Text(
                                  'Please set operational hours for at least one day',
                                  style: TextStyle(
                                    fontFamily: FontConstants.fontFamily,
                                    fontSize: FontSize.s12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: verticalPadding),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          BlocBuilder<RestaurantCategoryBloc, RestaurantCategoryState>(
        builder: (ctx, state) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: sidePadding,
              vertical: h * 0.03,
            ),
            child: NextButton(
              label: 'Next',
              suffixIcon: Icons.arrow_forward,
              onPressed: state.canProceed
                  ? () {
                      debugPrint('▶️ Next pressed, navigating to step-3');
                      Navigator.pushNamed(ctx, Routes.detailsAdd3);
                    }
                  : () {
                      // Show validation message when button is pressed but validation fails
                      final validationMessage = _getValidationMessage(state);
                      if (validationMessage.isNotEmpty) {
                        _showValidationMessage(ctx, validationMessage);
                      }
                    },
            ),
          );
        },
      ),
    );
  }
}