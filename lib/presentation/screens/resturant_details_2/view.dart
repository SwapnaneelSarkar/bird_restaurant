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
                        'Restaurant Category',
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
                      Text(
                        'Type of Cuisine',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
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
                      SizedBox(height: verticalPadding * 1.5),
                      Text(
                        'Operational Hours',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
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
                  : null,
            ),
          );
        },
      ),
    );
  }
}