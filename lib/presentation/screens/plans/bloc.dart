
// lib/presentation/plan_selection/bloc/plan_selection_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/plan_model.dart';
import 'event.dart';
import 'state.dart';

class PlanSelectionBloc extends Bloc<PlanSelectionEvent, PlanSelectionState> {
  PlanSelectionBloc() : super(PlanSelectionInitial()) {
    on<LoadPlansEvent>(_onLoadPlans);
    on<SelectPlanEvent>(_onSelectPlan);
  }

  void _onLoadPlans(LoadPlansEvent event, Emitter<PlanSelectionState> emit) {
    emit(PlanSelectionLoading());
    
    try {
      // Static data for now
      final plans = [
        const PlanModel(
          id: 'basic',
          title: 'Basic',
          description: 'Perfect for small restaurants starting their digital journey',
          features: [
            'Basic restaurant listing',
            'Online menu management',
            'Order notifications',
            'Basic analytics',
            'Email support',
          ],
          price: 999,
          buttonText: 'Select Basic',
        ),
        const PlanModel(
          id: 'plus',
          title: 'Plus',
          description: 'Enhanced features for growing restaurants',
          features: [
            'All Basic features',
            'Priority restaurant listing',
            'Advanced menu customization',
            'Detailed analytics & reports',
            'Priority customer support',
            'Marketing tools',
          ],
          price: 1999,
          isPopular: true,
          buttonText: 'Select Plus',
        ),
        const PlanModel(
          id: 'premium',
          title: 'Premium',
          description: 'Complete solution for established restaurants',
          features: [
            'All Plus features',
            'Featured restaurant placement',
            'Advanced inventory management',
            'Customer loyalty program',
            '24/7 dedicated support',
            'Advanced marketing tools',
          ],
          price: 3999,
          buttonText: 'Select Premium',
        ),
      ];

      emit(PlanSelectionLoaded(plans: plans));
    } catch (e) {
      emit(PlanSelectionError('Failed to load plans: ${e.toString()}'));
    }
  }

  void _onSelectPlan(SelectPlanEvent event, Emitter<PlanSelectionState> emit) {
    if (state is PlanSelectionLoaded) {
      final currentState = state as PlanSelectionLoaded;
      emit(currentState.copyWith(selectedPlanId: event.planId));
    }
  }
}
