import 'package:equatable/equatable.dart';

enum StatusType { submitted, underReview, activation, approved, rejected }

class StatusStep extends Equatable {
  final StatusType type;
  final String title;
  final String subtitle;
  final DateTime? date;
  final bool isCurrent;
  final bool isCompleted;
  final bool isRejected;

  const StatusStep({
    required this.type,
    required this.title,
    required this.subtitle,
    this.date,
    this.isCurrent = false,
    this.isCompleted = false,
    this.isRejected = false,
  });

  @override
  List<Object?> get props => [type, title, subtitle, date, isCurrent, isCompleted, isRejected];
}

class ApplicationStatusState extends Equatable {
  final List<StatusStep> steps;
  final String estimatedTime;
  final bool isLoading;
  final String? error;
  final int? applicationStatus;
  final Map<String, dynamic>? restaurantData;

  const ApplicationStatusState({
    required this.steps,
    required this.estimatedTime,
    this.isLoading = false,
    this.error,
    this.applicationStatus,
    this.restaurantData,
  });

  @override
  List<Object?> get props => [steps, estimatedTime, isLoading, error, applicationStatus, restaurantData];

  ApplicationStatusState copyWith({
    List<StatusStep>? steps,
    String? estimatedTime,
    bool? isLoading,
    String? error,
    int? applicationStatus,
    Map<String, dynamic>? restaurantData,
  }) {
    return ApplicationStatusState(
      steps: steps ?? this.steps,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      restaurantData: restaurantData ?? this.restaurantData,
    );
  }
}