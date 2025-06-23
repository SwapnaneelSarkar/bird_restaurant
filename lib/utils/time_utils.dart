// lib/utils/time_utils.dart

import 'package:intl/intl.dart';

// lib/utils/time_utils.dart

class TimeUtils {
  // IST offset from UTC (5 hours 30 minutes)
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);
  
  /// Get current time in IST
  static DateTime getCurrentIST() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(_istOffset);
  }
  
  /// Convert any DateTime to IST
  static DateTime toIST(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.add(_istOffset);
  }
  
  /// Parse ISO string and convert to IST
  static DateTime parseToIST(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return toIST(parsed);
    } catch (e) {
      // If parsing fails, return current IST time
      return getCurrentIST();
    }
  }
  
  /// Convert IST DateTime to ISO string for API
  static String toIsoStringForAPI(DateTime istDateTime) {
    // Convert IST back to UTC for API
    final utcDateTime = istDateTime.subtract(_istOffset);
    return utcDateTime.toIso8601String();
  }
  
  /// Format time for chat list display
  /// - Today: 12-hour IST time (e.g., "2:30 PM")
  /// - Yesterday: "Yesterday"
  /// - Older: Date (e.g., "12/25/2024")
  static String formatChatListTime(DateTime messageTime) {
    // messageTime is already in IST (from parseToIST), so don't convert again
    final istMessageTime = messageTime;
    final istNow = getCurrentIST();
    
    // Create date-only versions for comparison
    final istMessageDate = DateTime(istMessageTime.year, istMessageTime.month, istMessageTime.day);
    final istToday = DateTime(istNow.year, istNow.month, istNow.day);
    final istYesterday = istToday.subtract(const Duration(days: 1));
    
    if (istMessageDate == istToday) {
      // Today - show 12-hour IST time
      return _format12HourTime(istMessageTime);
    } else if (istMessageDate == istYesterday) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return _formatDate(istMessageTime);
    }
  }
  
  /// Format time for chat messages (always 12-hour IST)
  static String formatChatMessageTime(DateTime messageTime) {
    // messageTime is already in IST (from parseToIST), so don't convert again
    final istTime = messageTime;
    return _format12HourTime(istTime);
  }
  
  /// Format date for status timeline (MM/DD/YYYY, HH:MM in IST)
  static String formatStatusTimelineDate(DateTime dateTime) {
    // dateTime is already in IST (from parseToIST), so don't convert again
    final istTime = dateTime;
    final month = istTime.month.toString().padLeft(2, '0');
    final day = istTime.day.toString().padLeft(2, '0');
    final hour = istTime.hour.toString().padLeft(2, '0');
    final minute = istTime.minute.toString().padLeft(2, '0');
    return '$month/$day/${istTime.year}, $hour:$minute';
  }
  
  /// Format date for review display (e.g., "Jan 15, 2024")
  static String formatReviewDate(DateTime dateTime) {
    // dateTime is already in IST (from parseToIST), so don't convert again
    final istTime = dateTime;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[istTime.month - 1]} ${istTime.day}, ${istTime.year}';
  }
  
  /// Format date for plans display (DD/MM/YYYY)
  static String formatPlanDate(DateTime dateTime) {
    // dateTime is already in IST (from parseToIST), so don't convert again
    final istTime = dateTime;
    final day = istTime.day.toString().padLeft(2, '0');
    final month = istTime.month.toString().padLeft(2, '0');
    return '$day/$month/${istTime.year}';
  }
  
  /// Get time ago string in IST
  static String getTimeAgo(DateTime dateTime) {
    // dateTime is already in IST (from parseToIST), so don't convert again
    final istDateTime = dateTime;
    final istNow = getCurrentIST();
    final difference = istNow.difference(istDateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Format weekday name from date string (for sales data)
  static String formatDateToDay(String dateString) {
    try {
      final date = parseToIST(dateString);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } catch (e) {
      return 'Day';
    }
  }
  
  /// Format 12-hour time in IST
  static String _format12HourTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    String period;
    
    if (hour == 0) {
      hour = 12;
      period = 'AM';
    } else if (hour < 12) {
      period = 'AM';
    } else if (hour == 12) {
      period = 'PM';
    } else {
      hour = hour - 12;
      period = 'PM';
    }
    
    return '$hour:$minute $period';
  }
  
  /// Format date as MM/DD/YYYY
  static String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month/$day/${dateTime.year}';
  }
  
  /// Get day difference between two dates in IST
  static int getDayDifference(DateTime date1, DateTime date2) {
    // Both dates are already in IST (from parseToIST), so don't convert again
    final istDate1 = date1;
    final istDate2 = date2;
    final dateOnly1 = DateTime(istDate1.year, istDate1.month, istDate1.day);
    final dateOnly2 = DateTime(istDate2.year, istDate2.month, istDate2.day);
    return dateOnly2.difference(dateOnly1).inDays;
  }
  
  /// Check if two dates are the same day in IST
  static bool isSameDay(DateTime date1, DateTime date2) {
    // Both dates are already in IST (from parseToIST), so don't convert again
    final istDate1 = date1;
    final istDate2 = date2;
    
    return istDate1.year == istDate2.year &&
           istDate1.month == istDate2.month &&
           istDate1.day == istDate2.day;
  }
  
  /// Check if date is today in IST
  static bool isToday(DateTime date) {
    return isSameDay(date, getCurrentIST());
  }
  
  /// Check if date is yesterday in IST
  static bool isYesterday(DateTime date) {
    final istYesterday = getCurrentIST().subtract(const Duration(days: 1));
    return isSameDay(date, istYesterday);
  }
  
  /// Check if subscription is active/pending in IST
  static bool isSubscriptionValid(DateTime startDate, DateTime endDate, String status) {
    // Both dates are already in IST (from parseToIST), so don't convert again
    final istStart = startDate;
    final istEnd = endDate;
    final istNow = getCurrentIST();
    
    if (status.toUpperCase() == 'PENDING') {
      // PENDING subscriptions are valid if start date is today or in the future
      return istStart.isAfter(istNow.subtract(const Duration(days: 1)));
    } else if (status.toUpperCase() == 'ACTIVE') {
      // ACTIVE subscriptions are valid if end date is in the future
      return istEnd.isAfter(istNow);
    }
    return false;
  }
}