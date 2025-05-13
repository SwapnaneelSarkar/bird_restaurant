abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

class ToggleOrderAcceptance extends HomeEvent {
  final bool isAccepting;

  ToggleOrderAcceptance(this.isAccepting);
}