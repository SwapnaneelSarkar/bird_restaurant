import 'package:equatable/equatable.dart';

abstract class ApplicationStatusEvent extends Equatable {
  const ApplicationStatusEvent();
  @override
  List<Object?> get props => [];
}

class ContactSupportPressed extends ApplicationStatusEvent {}

class FetchApplicationStatus extends ApplicationStatusEvent {
  const FetchApplicationStatus();
}