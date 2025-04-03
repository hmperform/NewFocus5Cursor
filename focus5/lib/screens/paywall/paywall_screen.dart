import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/paywall_service.dart';

class PaywallScreen extends StatefulWidget {
  final String? sourceScreen;

  const PaywallScreen({Key? key, this.sourceScreen}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'monthly';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context, false), // Return false if user cancels
        ),
        title: Text(
          'Select plan',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Access (App Only)',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Free for 3 months',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 32),
            
            // Features list
            _buildFeatureItem(
              context, 
              '⭐', 
              'Ad-free content', 
              'curated by experts and professionals in every sports discipline',
              textColor,
              secondaryTextColor
            ),
            const SizedBox(height: 20),
            
            _buildFeatureItem(
              context, 
              '⭐', 
              'Celebrity-hosted training sessions', 
              'and the best techniques from top athletes',
              textColor,
              secondaryTextColor
            ),
            const SizedBox(height: 20),
            
            _buildFeatureItem(
              context, 
              '⭐', 
              'Mental performance tools', 
              'across the entire mental skills spectrum',
              textColor,
              secondaryTextColor
            ),
            const SizedBox(height: 20),
            
            _buildFeatureItem(
              context, 
              '⭐', 
              'Complete analytics and tracking', 
              'plus personalized recommendations and insights',
              textColor,
              secondaryTextColor
            ),
            
            const Spacer(),
            
            // Payment options
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPlan == 'monthly' ? accentColor : Colors.grey.withOpacity(0.3),
                  width: _selectedPlan == 'monthly' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile(
                title: Text(
                  'Monthly',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free for 3 months, then',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                    Text(
                      '\$5.00/mo.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                value: 'monthly',
                groupValue: _selectedPlan,
                activeColor: accentColor,
                onChanged: (value) {
                  setState(() {
                    _selectedPlan = value.toString();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPlan == 'yearly' ? accentColor : Colors.grey.withOpacity(0.3),
                  width: _selectedPlan == 'yearly' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile(
                title: Row(
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free for 7 days, then',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                    Row(
                      children: [
                        Text(
                          '\$50/yr.',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(\$4.17/mo.)',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                value: 'yearly',
                groupValue: _selectedPlan,
                activeColor: accentColor,
                onChanged: (value) {
                  setState(() {
                    _selectedPlan = value.toString();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _purchaseSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Colors.black : Colors.white),
                        ),
                      )
                    : const Text(
                        'Agree & continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                'Cancel anytime. All plans include 14-day free trial.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _purchaseSubscription() async {
    setState(() {
      _isProcessing = true;
    });
    
    final paywallService = PaywallService();
    final success = await paywallService.purchaseSubscription(_selectedPlan);
    
    if (!mounted) return;
    
    if (success) {
      // Pop with true result to indicate successful subscription
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isProcessing = false;
      });
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process payment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildFeatureItem(BuildContext context, String emoji, String title, String description, Color titleColor, Color descriptionColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: descriptionColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 