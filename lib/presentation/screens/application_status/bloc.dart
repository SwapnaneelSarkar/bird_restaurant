import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'event.dart';
import 'state.dart';

class ApplicationStatusBloc extends Bloc<ApplicationStatusEvent, ApplicationStatusState> {
  ApplicationStatusBloc() : super(
          ApplicationStatusState(
            steps: [],
            estimatedTime: 'We typically review applications within 24-48 hours',
            isLoading: true,
          ),
        ) {
    on<ContactSupportPressed>(_onContactSupportPressed);
    on<FetchApplicationStatus>(_onFetchApplicationStatus);
  }

  void _onContactSupportPressed(
    ContactSupportPressed event,
    Emitter<ApplicationStatusState> emit,
  ) {
    // Handle contact support
    // You can implement navigation to support screen or open email/chat
  }

  Future<void> _onFetchApplicationStatus(
  FetchApplicationStatus event,
  Emitter<ApplicationStatusState> emit,
) async {
  emit(state.copyWith(isLoading: true, error: null));

  try {
    final prefs = await SharedPreferences.getInstance();
    
    String? mobileNumber = prefs.getString('mobile');
    final token = prefs.getString('token');  // Use 'token' not 'auth_token'
    final userId = prefs.getString('user_id');

    debugPrint('All SharedPreferences keys: ${prefs.getKeys()}');
    debugPrint('Retrieved from SharedPreferences:');
    debugPrint('Mobile: $mobileNumber');
    debugPrint('Token: ${token?.substring(0, 20)}...');
    debugPrint('User ID: $userId');

    if (mobileNumber == null || mobileNumber.isEmpty) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Mobile number not found. Please login again.',
      ));
      return;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // The mobile number is already in the correct format (without country code)
    final cleanMobileNumber = mobileNumber;

    debugPrint('Using mobile number for API: $cleanMobileNumber');


    final uri = Uri.parse('https://api.bird.delivery/api/partner/getDetailsByMobile?mobile=$cleanMobileNumber');
    debugPrint('API URL: $uri');

    final response = await http.get(uri, headers: headers);

    debugPrint('API Response status: ${response.statusCode}');
    debugPrint('API Response body: ${response.body}');


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS') {
          final restaurantData = data['data'];
          final status = restaurantData['status'];
          
          List<StatusStep> steps = _generateSteps(status);
          
          emit(state.copyWith(
            isLoading: false,
            steps: steps,
            applicationStatus: status,
            restaurantData: restaurantData,
            estimatedTime: _getEstimatedTime(status),
          ));
        } else {
          emit(state.copyWith(
            isLoading: false,
            error: data['message'] ?? 'Failed to fetch application status',
          ));
        }
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to fetch application status. Please try again.',
        ));
      }
    } catch (e) {
      debugPrint('Error in FetchApplicationStatus: $e');
    emit(state.copyWith(
      isLoading: false,
      error: 'Network error: Please check your connection and try again.',
    ));
  }

  }

  List<StatusStep> _generateSteps(int? status) {
    final now = DateTime.now();
    
    if (status == 7) { // Rejected
      return [
        StatusStep(
          type: StatusType.submitted,
          title: 'Application Submitted',
          subtitle: 'Your restaurant details have been submitted',
          date: now.subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
        StatusStep(
          type: StatusType.underReview,
          title: 'Under Review',
          subtitle: 'Our team reviewed your application',
          date: now.subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        StatusStep(
          type: StatusType.rejected,
          title: 'Application Rejected',
          subtitle: 'Unfortunately, your application was not approved',
          date: now,
          isRejected: true,
          isCurrent: true,
        ),
      ];
    } else if (status == 1) { // Approved
      return [
        StatusStep(
          type: StatusType.submitted,
          title: 'Application Submitted',
          subtitle: 'Your restaurant details have been submitted',
          date: now.subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
        StatusStep(
          type: StatusType.underReview,
          title: 'Under Review',
          subtitle: 'Our team reviewed your application',
          date: now.subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        StatusStep(
          type: StatusType.approved,
          title: 'Application Approved',
          subtitle: 'Congratulations! Your restaurant has been approved',
          date: now,
          isCompleted: true,
          isCurrent: true,
        ),
      ];
    } else { // Under review (2 or null)
      return [
        StatusStep(
          type: StatusType.submitted,
          title: 'Application Submitted',
          subtitle: 'Your restaurant details have been successfully submitted',
          date: now.subtract(const Duration(hours: 6)),
          isCompleted: true,
        ),
        StatusStep(
          type: StatusType.underReview,
          title: 'Under Review',
          subtitle: 'Our team is reviewing your application',
          isCurrent: true,
        ),
        StatusStep(
          type: StatusType.activation,
          title: 'Restaurant Activation',
          subtitle: 'Pending approval',
        ),
      ];
    }
  }

  String _getEstimatedTime(int? status) {
    if (status == 7) {
      return 'Your application has been reviewed. Please contact support for more information.';
    } else if (status == 1) {
      return 'Your application has been approved! You can now start using our services.';
    } else {
      return 'We typically review applications within 24-48 hours';
    }
  }
}