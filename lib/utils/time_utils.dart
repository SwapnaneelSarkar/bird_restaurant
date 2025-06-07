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
  
  /// Format time for chat list display
  /// - Today: 12-hour IST time (e.g., "2:30 PM")
  /// - Yesterday: "Yesterday"
  /// - Older: Date (e.g., "12/25/2024")
  static String formatChatListTime(DateTime messageTime) {
    final istMessageTime = toIST(messageTime);
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
    final istTime = toIST(messageTime);
    return _format12HourTime(istTime);
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
    final istDate1 = DateTime(date1.year, date1.month, date1.day);
    final istDate2 = DateTime(date2.year, date2.month, date2.day);
    return istDate2.difference(istDate1).inDays;
  }
  
  /// Check if two dates are the same day in IST
  static bool isSameDay(DateTime date1, DateTime date2) {
    final istDate1 = toIST(date1);
    final istDate2 = toIST(date2);
    
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
}