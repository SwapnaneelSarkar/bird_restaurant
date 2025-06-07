// lib/utils/time_utils.dart

import 'package:intl/intl.dart';

class TimeUtils {
  // Indian Standard Time timezone offset (+5:30)
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);
  
  /// Converts DateTime to Indian Standard Time
  static DateTime toIST(DateTime dateTime) {
    // If the DateTime is already in IST, return as is
    if (dateTime.timeZoneOffset == _istOffset) {
      return dateTime;
    }
    
    // Convert UTC to IST
    if (dateTime.isUtc) {
      return dateTime.add(_istOffset);
    }
    
    // Convert local time to IST
    final utc = dateTime.toUtc();
    return utc.add(_istOffset);
  }
  
  /// Format time in 12-hour IST format (e.g., "2:30 PM")
  static String format12HourIST(DateTime dateTime) {
    final istTime = toIST(dateTime);
    
    int hour = istTime.hour;
    final int minute = istTime.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    
    // Convert to 12-hour format
    if (hour == 0) {
      hour = 12; // 12:xx AM
    } else if (hour > 12) {
      hour = hour - 12; // 1:xx PM to 11:xx PM
    }
    // hour 12 stays as 12 (12:xx PM)
    
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }
  
  /// Format time for chat list - shows relative time or 12-hour format
  static String formatChatListTime(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final now = toIST(DateTime.now());
    
    final difference = now.difference(istTime);
    
    if (difference.inDays == 0) {
      // Today - show 12-hour time
      return format12HourIST(istTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(istTime); // Monday, Tuesday, etc.
    } else if (istTime.year == now.year) {
      // This year - show date without year
      return DateFormat('dd/MM').format(istTime);
    } else {
      // Previous years - show full date
      return DateFormat('dd/MM/yy').format(istTime);
    }
  }
  
  /// Format time for chat messages - always shows 12-hour time
  static String formatChatMessageTime(DateTime dateTime) {
    return format12HourIST(dateTime);
  }
  
  /// Get current IST time
  static DateTime getCurrentIST() {
    return toIST(DateTime.now());
  }
  
  /// Format date for chat header (e.g., "Today", "Yesterday", "15 Jan 2024")
  static String formatChatHeaderDate(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final now = toIST(DateTime.now());
    
    final difference = now.difference(istTime);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (istTime.year == now.year) {
      return DateFormat('dd MMM').format(istTime); // "15 Jan"
    } else {
      return DateFormat('dd MMM yyyy').format(istTime); // "15 Jan 2024"
    }
  }
}