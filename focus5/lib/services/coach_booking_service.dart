import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to handle coach booking functionality
class CoachBookingService {
  /// Launch the booking URL for a coach
  Future<bool> launchBookingUrl(String url) async {
    if (url.isEmpty) {
      debugPrint('Booking URL is empty');
      return false;
    }
    
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching booking URL: $e');
      return false;
    }
  }
  
  /// Check if a coach is available for booking
  bool isCoachAvailableForBooking(String coachId, Map<String, dynamic> availability) {
    if (availability.isEmpty) {
      return false;
    }
    
    // Check if the coach has any available slots
    final slots = availability['slots'] as List?;
    return slots != null && slots.isNotEmpty;
  }
} 