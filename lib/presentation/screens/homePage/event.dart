import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshHomeData extends HomeEvent {}

class ToggleOrderAcceptance extends HomeEvent {
  final bool isAccepting;

  const ToggleOrderAcceptance(this.isAccepting);

  @override
  List<Object?> get props => [isAccepting];
}