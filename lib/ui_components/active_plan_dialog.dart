import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class ActivePlanDialog extends StatelessWidget {
  final String planName;
  final String planDescription;
  final String endDate;
  final String dialogTitle;
  final String dialogMessage;
  final VoidCallback onGoToHome;

  const ActivePlanDialog({
    Key? key,
    required this.planName,
    required this.planDescription,
    required this.endDate,
    this.dialogTitle = 'Active Plan Found!',
    this.dialogMessage = 'You already have an active subscription plan.',
    required this.onGoToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, immediately go to home
        onGoToHome();
        return false; // Prevent dialog from being dismissed normally
      },
      child: Dialog(
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
                // Info Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: ColorManager.primary,
                    size: 48,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  dialogTitle,
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
                  dialogMessage,
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    color: ColorManager.textGrey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Plan Details
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
                      _buildDetailRow('Plan Name', planName),
                      const SizedBox(height: 8),
                      _buildDetailRow('Description', planDescription),
                      const SizedBox(height: 8),
                      _buildDetailRow('Valid Until', endDate),
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