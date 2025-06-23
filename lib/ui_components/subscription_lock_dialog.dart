import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../services/subscription_lock_service.dart';

class SubscriptionLockDialog extends StatelessWidget {
  final String pageName;
  final VoidCallback? onGoToPlans;
  final VoidCallback? onGoBack;

  const SubscriptionLockDialog({
    Key? key,
    required this.pageName,
    this.onGoToPlans,
    this.onGoBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: ColorManager.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Subscription Required',
              style: TextStyle(
                fontSize: FontSize.s20,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              'Access to $pageName requires an active subscription plan.',
              style: TextStyle(
                fontSize: FontSize.s16,
                color: ColorManager.textGrey,
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Please subscribe to a plan to unlock all features.',
              style: TextStyle(
                fontSize: FontSize.s14,
                color: ColorManager.textGrey.withOpacity(0.8),
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                // Go Back Button
                if (onGoBack != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGoBack?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: ColorManager.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.medium,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ),
                
                if (onGoBack != null) const SizedBox(width: 12),
                
                // Subscribe Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Use safe navigation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          try {
                            Navigator.of(context).pushNamed('/plan');
                          } catch (e) {
                            debugPrint('Error navigating to plans from dialog: $e');
                            // Fallback navigation
                            try {
                              Navigator.of(context).pushNamedAndRemoveUntil('/plan', (route) => false);
                            } catch (fallbackError) {
                              debugPrint('Fallback navigation also failed: $fallbackError');
                            }
                          }
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Subscribe Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Pending Subscription Dialog
class PendingSubscriptionLockDialog extends StatelessWidget {
  final String pageName;
  final String planName;
  final String endDate;
  final VoidCallback? onGoBack;

  const PendingSubscriptionLockDialog({
    Key? key,
    required this.pageName,
    required this.planName,
    required this.endDate,
    this.onGoBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 40,
                color: Colors.orange,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Subscription Pending',
              style: TextStyle(
                fontSize: FontSize.s20,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              'Your $planName subscription is currently pending approval.',
              style: TextStyle(
                fontSize: FontSize.s16,
                color: ColorManager.textGrey,
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'You will be notified once your subscription is activated and you can access $pageName.',
              style: TextStyle(
                fontSize: FontSize.s14,
                color: ColorManager.textGrey.withOpacity(0.8),
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Subscription Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Plan:',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          color: ColorManager.textGrey,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
                          color: ColorManager.black,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start Date:',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          color: ColorManager.textGrey,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      Text(
                        endDate,
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontWeight: FontWeightManager.medium,
                          color: ColorManager.black,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Go Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onGoBack?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: FontSize.s16,
                    fontWeight: FontWeightManager.medium,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 