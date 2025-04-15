import 'package:intl/intl.dart';

class Formatters {
  /// Formats a DateTime into a readable date string (e.g., "Aug 15, 2023")
  static String formatDate(DateTime date) {
    try {
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  /// Formats a DateTime into a readable date and time string
  static String formatDateTime(DateTime date) {
    try {
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  /// Formats a number with commas for thousands
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }
  
  /// Formats a duration in seconds to a readable time string (e.g., "5m 30s")
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
} 