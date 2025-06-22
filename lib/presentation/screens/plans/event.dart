// lib/presentation/plan_selection/bloc/plan_selection_event.dart
import 'package:equatable/equatable.dart';

abstract class PlanSelectionEvent extends Equatable {
  const PlanSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadPlansEvent extends PlanSelectionEvent {}

class SelectPlanEvent extends PlanSelectionEvent {
  final String planId;

  const SelectPlanEvent(this.planId);

  @override
  List<Object> get props => [planId];
}

class CreateSubscriptionEvent extends PlanSelectionEvent {
  final String planId;
  final double amount;
  final String paymentMethod;

  const CreateSubscriptionEvent({
    required this.planId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  List<Object> get props => [planId, amount, paymentMethod];
}
