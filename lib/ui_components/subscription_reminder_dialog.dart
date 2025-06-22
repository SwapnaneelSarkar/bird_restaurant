import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class SubscriptionReminderDialog extends StatelessWidget {
  final bool hasExpiredPlan;
  final String? expiredPlanName;
  final VoidCallback onGoToPlans;
  final VoidCallback onSkip;

  const SubscriptionReminderDialog({
    Key? key,
    required this.hasExpiredPlan,
    this.expiredPlanName,
    required this.onGoToPlans,
    required this.onSkip,
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
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[600],
                  size: 48,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                hasExpiredPlan ? 'Plan Expired!' : 'No Active Plan',
                style: TextStyle(
                  fontSize: FontSize.s20,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Message
              Text(
                hasExpiredPlan 
                    ? 'Your ${expiredPlanName ?? 'subscription'} plan has expired. Please renew to continue enjoying our services.'
                    : 'You don\'t have an active subscription plan. Subscribe now to unlock all features.',
                style: TextStyle(
                  fontSize: FontSize.s14,
                  color: ColorManager.textGrey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Column(
                children: [
                  // Go to Plans Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onGoToPlans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        hasExpiredPlan ? 'Renew Plan' : 'Subscribe Now',
                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Skip Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: ColorManager.grey.withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        'Skip for Now',
                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.medium,
                          color: ColorManager.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 