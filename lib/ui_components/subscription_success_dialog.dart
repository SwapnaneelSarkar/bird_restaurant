import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class SubscriptionSuccessDialog extends StatelessWidget {
  final Map<String, dynamic> subscriptionData;
  final VoidCallback onGoToHome;

  const SubscriptionSuccessDialog({
    Key? key,
    required this.subscriptionData,
    required this.onGoToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Success Title
              Text(
                'Subscription Created!',
                style: TextStyle(
                  fontSize: FontSize.s20,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Success Message
              Text(
                'Your subscription has been successfully created. You will receive a confirmation shortly.',
                style: TextStyle(
                  fontSize: FontSize.s14,
                  color: ColorManager.textGrey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Subscription Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorManager.primary.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Subscription ID', subscriptionData['subscription_id'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', subscriptionData['status'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Payment Status', subscriptionData['payment_status'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Amount', '₹${subscriptionData['amount_paid']?.toString() ?? 'N/A'}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Go to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGoToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.semiBold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.textGrey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.semiBold,
              color: ColorManager.black,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 