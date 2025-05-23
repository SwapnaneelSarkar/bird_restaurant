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
