// lib/presentation/plan_selection/bloc/plan_selection_state.dart
import 'package:equatable/equatable.dart';
import '../../../models/plan_model.dart';

abstract class PlanSelectionState extends Equatable {
  const PlanSelectionState();

  @override
  List<Object?> get props => [];
}

class PlanSelectionInitial extends PlanSelectionState {}

class PlanSelectionLoading extends PlanSelectionState {}

class PlanSelectionLoaded extends PlanSelectionState {
  final List<PlanModel> plans;
  final String? selectedPlanId;

  const PlanSelectionLoaded({
    required this.plans,
    this.selectedPlanId,
  });

  @override
  List<Object?> get props => [plans, selectedPlanId];

  PlanSelectionLoaded copyWith({
    List<PlanModel>? plans,
    String? selectedPlanId,
  }) {
    return PlanSelectionLoaded(
      plans: plans ?? this.plans,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
    );
  }
}

class PlanSelectionError extends PlanSelectionState {
  final String message;

  const PlanSelectionError(this.message);

  @override
  List<Object> get props => [message];
}

class SubscriptionCreating extends PlanSelectionState {
  final List<PlanModel> plans;
  final String? selectedPlanId;

  const SubscriptionCreating({
    required this.plans,
    this.selectedPlanId,
  });

  @override
  List<Object?> get props => [plans, selectedPlanId];
}

class SubscriptionCreated extends PlanSelectionState {
  final Map<String, dynamic> subscriptionData;
  final List<PlanModel> plans;
  final String? selectedPlanId;

  const SubscriptionCreated({
    required this.subscriptionData,
    required this.plans,
    this.selectedPlanId,
  });

  @override
  List<Object?> get props => [subscriptionData, plans, selectedPlanId];
}

class SubscriptionError extends PlanSelectionState {
  final String message;
  final List<PlanModel> plans;
  final String? selectedPlanId;

  const SubscriptionError({
    required this.message,
    required this.plans,
    this.selectedPlanId,
  });

  @override
  List<Object?> get props => [message, plans, selectedPlanId];
}
