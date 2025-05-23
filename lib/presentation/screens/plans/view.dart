// lib/presentation/plan_selection/view/plan_selection_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/plan_card.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class PlanSelectionView extends StatelessWidget {
  const PlanSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanSelectionBloc()..add(LoadPlansEvent()),
      child: const PlanSelectionScreen(),
    );
  }
}

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const AppBackHeader(title: 'Choose Your Plan'),
            Expanded(
              child: BlocBuilder<PlanSelectionBloc, PlanSelectionState>(
                builder: (context, state) {
                  if (state is PlanSelectionLoading) {
                    return  Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primary,
                      ),
                    );
                  }
                  
                  if (state is PlanSelectionError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: FontSize.s18,
                              fontWeight: FontWeightManager.bold,
                              color: ColorManager.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: FontSize.s14,
                              color: ColorManager.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is PlanSelectionLoaded) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              fontSize: FontSize.s22,
                              fontWeight: FontWeightManager.bold,
                              color: ColorManager.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the best plan for your business',
                            style: TextStyle(
                              fontSize: FontSize.s16,
                              color: ColorManager.textGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Plans list
                          ...state.plans.map((plan) => PlanCard(
                            plan: plan,
                            isSelected: state.selectedPlanId == plan.id,
                            onTap: () {
                              context.read<PlanSelectionBloc>().add(
                                SelectPlanEvent(plan.id),
                              );
                              // Handle plan selection - navigate or show success
                              _handlePlanSelection(context, plan);
                            },
                          )).toList(),
                        ],
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlanSelection(BuildContext context, dynamic plan) {
    // Show snackbar or navigate to next screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plan.title} plan selected'),
        backgroundColor: ColorManager.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // You can add navigation logic here
    // Navigator.pushNamed(context, '/payment', arguments: plan);
  }
}

