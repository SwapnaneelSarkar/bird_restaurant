// lib/presentation/plan_selection/bloc/plan_selection_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/subscription_plans_service.dart';
import '../../../services/token_service.dart';
import 'event.dart';
import 'state.dart';
import 'package:flutter/foundation.dart';

class PlanSelectionBloc extends Bloc<PlanSelectionEvent, PlanSelectionState> {
  PlanSelectionBloc() : super(PlanSelectionInitial()) {
    on<LoadPlansEvent>(_onLoadPlans);
    on<SelectPlanEvent>(_onSelectPlan);
    on<CreateSubscriptionEvent>(_onCreateSubscription);
  }

  void _onLoadPlans(LoadPlansEvent event, Emitter<PlanSelectionState> emit) async {
    emit(PlanSelectionLoading());
    
    try {
      // Fetch plans from API
      final plans = await SubscriptionPlansService.fetchSubscriptionPlans();
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

  void _onCreateSubscription(CreateSubscriptionEvent event, Emitter<PlanSelectionState> emit) async {
    debugPrint('PlanSelectionBloc: Starting subscription creation for plan ${event.planId}');
    
    if (state is PlanSelectionLoaded) {
      final currentState = state as PlanSelectionLoaded;
      debugPrint('PlanSelectionBloc: Current state has ${currentState.plans.length} plans');
      
      emit(SubscriptionCreating(
        plans: currentState.plans,
        selectedPlanId: currentState.selectedPlanId,
      ));
      
      try {
        // Get partner ID from token service
        debugPrint('PlanSelectionBloc: Getting partner ID...');
        final partnerId = await TokenService.getUserId();
        debugPrint('PlanSelectionBloc: Partner ID retrieved: $partnerId');
        
        if (partnerId == null) {
          throw Exception('Partner ID not found. Please login again.');
        }

        // Create subscription
        debugPrint('PlanSelectionBloc: Creating subscription with partner ID: $partnerId, plan ID: ${event.planId}, amount: ${event.amount}, payment method: ${event.paymentMethod}');
        
        final subscriptionData = await SubscriptionPlansService.createVendorSubscription(
          partnerId: partnerId,
          planId: event.planId,
          amountPaid: event.amount,
          paymentMethod: event.paymentMethod,
        );

        debugPrint('PlanSelectionBloc: Subscription created successfully: $subscriptionData');

        emit(SubscriptionCreated(
          subscriptionData: subscriptionData,
          plans: currentState.plans,
          selectedPlanId: currentState.selectedPlanId,
        ));
      } catch (e) {
        debugPrint('PlanSelectionBloc: Error creating subscription: $e');
        emit(SubscriptionError(
          message: e.toString(),
          plans: currentState.plans,
          selectedPlanId: currentState.selectedPlanId,
        ));
      }
    } else {
      debugPrint('PlanSelectionBloc: Invalid state for subscription creation: ${state.runtimeType}');
      emit(PlanSelectionError('Invalid state for subscription creation'));
    }
  }
}
