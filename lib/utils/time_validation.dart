// lib/utils/time_validation.dart
import 'package:flutter/material.dart';
import '../presentation/screens/add_product/state.dart';

class TimeValidationUtils {
  /// Validates that the end time is at least 1 minute after the start time
  /// Returns null if valid, error message if invalid
  static String? validateTimeRange(String startTime, String endTime) {
    try {
      final start = _parseTimeString(startTime);
      final end = _parseTimeString(endTime);
      
      if (start == null || end == null) {
        return 'Invalid time format';
      }
      
      // Convert to minutes for easier comparison
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      
      // Simple validation: end time must be at least 1 minute after start time
      // We don't allow overnight operations for menu items
      if (endMinutes <= startMinutes) {
        return 'End time must be at least 1 minute after start time';
      }
      
      int timeDifference = endMinutes - startMinutes;
      
      // Check if end time is at least 1 minute after start time
      if (timeDifference < 1) {
        return 'End time must be at least 1 minute after start time';
      }
      
      return null; // Valid
    } catch (e) {
      return 'Invalid time format';
    }
  }
  
  /// Validates the entire timing schedule
  /// Returns null if valid, error message if invalid
  static String? validateTimingSchedule(TimingSchedule schedule) {
    final days = [
      schedule.monday,
      schedule.tuesday,
      schedule.wednesday,
      schedule.thursday,
      schedule.friday,
      schedule.saturday,
      schedule.sunday,
    ];
    
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      if (day.enabled) {
        final error = validateTimeRange(day.start, day.end);
        if (error != null) {
          final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          return '${dayNames[i]}: $error';
        }
      }
    }
    
    return null; // All valid
  }
  
  /// Parses time string in HH:MM format to TimeOfDay
  static TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }
} 
