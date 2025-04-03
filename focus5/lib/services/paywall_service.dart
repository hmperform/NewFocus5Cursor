import 'package:flutter/material.dart';
import '../screens/paywall/paywall_screen.dart';

class PaywallService {
  // Singleton instance
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();
  
  // Track if user has subscription
  bool _hasSubscription = false;
  
  // Temporary in-memory storage for when a paywall was last shown
  DateTime? _lastPaywallShown;
  
  // Getter for subscription status
  bool get hasSubscription => _hasSubscription;
  
  // Method to check if user has subscription
  // In a real app, this would check with a backend service
  Future<bool> checkSubscription() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    // For demo purposes, always return false to show paywall
    return _hasSubscription;
  }
  
  // Method to show paywall if necessary
  Future<bool> showPaywallIfNeeded(BuildContext context, {required String source}) async {
    // If user already has subscription, allow access
    if (await checkSubscription()) {
      return true;
    }
    
    // Show paywall every time for premium content
    // Update last shown time
    _lastPaywallShown = DateTime.now();
    
    // Show paywall
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(sourceScreen: source),
        fullscreenDialog: true,
      ),
    );
    
    // If the result is true, the user has subscribed
    if (result == true) {
      _hasSubscription = true;
      return true;
    }
    
    // Otherwise, access is denied
    return false;
  }
  
  // Method to purchase subscription (would integrate with payment provider)
  Future<bool> purchaseSubscription(String planType) async {
    // Simulate payment process
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes, always succeed
    _hasSubscription = true;
    return true;
  }
  
  // Method to restore purchase
  Future<bool> restorePurchase() async {
    // Simulate restore process
    await Future.delayed(const Duration(seconds: 1));
    
    // For demo purposes, always succeed
    _hasSubscription = true;
    return true;
  }
} 