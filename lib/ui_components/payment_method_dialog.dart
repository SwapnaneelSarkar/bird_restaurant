import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class PaymentMethodDialog extends StatelessWidget {
  final String planName;
  final double amount;
  final Function(String) onPaymentMethodSelected;

  const PaymentMethodDialog({
    Key? key,
    required this.planName,
    required this.amount,
    required this.onPaymentMethodSelected,
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: ColorManager.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Payment Method',
                          style: TextStyle(
                            fontSize: FontSize.s18,
                            fontWeight: FontWeightManager.bold,
                            color: ColorManager.black,
                          ),
                        ),
                        Text(
                          '$planName Plan - ₹${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: FontSize.s14,
                            color: ColorManager.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Payment Methods
              _buildPaymentOption(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Pay via UPI',
                subtitle: 'Coming soon',
                isEnabled: false,
                onTap: () {
                  // Disabled for now
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildPaymentOption(
                context,
                icon: Icons.money,
                title: 'Pay via Cash',
                subtitle: 'Pay at our office',
                isEnabled: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onPaymentMethodSelected('CASH');
                },
              ),
              
              const SizedBox(height: 24),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: ColorManager.signUpRed.withOpacity(0.8)),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.medium,
                      color: ColorManager.signUpRed,
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

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled 
                ? Colors.white 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                  ? ColorManager.primary.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? ColorManager.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEnabled 
                      ? ColorManager.primary
                      : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.medium,
                        color: isEnabled 
                            ? ColorManager.black
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSize.s14,
                        color: isEnabled 
                            ? ColorManager.textGrey
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: FontSize.s12,
                      fontWeight: FontWeightManager.medium,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 