import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../utils/time_utils.dart';

class SubscriptionManagementDialog extends StatelessWidget {
  final Map<String, dynamic> subscriptionData;
  final VoidCallback onViewPlans;
  final VoidCallback onGoToHome;
  final VoidCallback? onRenewSubscription;
  final VoidCallback? onUpgradeSubscription;

  const SubscriptionManagementDialog({
    Key? key,
    required this.subscriptionData,
    required this.onViewPlans,
    required this.onGoToHome,
    this.onRenewSubscription,
    this.onUpgradeSubscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final planName = subscriptionData['plan_name']?.toString() ?? 'Unknown Plan';
    final planDescription = subscriptionData['plan_description']?.toString() ?? 'No description available';
    final endDate = subscriptionData['end_date']?.toString() ?? 'Unknown';
    final status = subscriptionData['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final subscriptionId = subscriptionData['subscription_id']?.toString() ?? 'N/A';
    final amountPaid = subscriptionData['amount_paid']?.toString() ?? 'N/A';
    final paymentStatus = subscriptionData['payment_status']?.toString() ?? 'N/A';
    
    // Format the end date for display
    String formattedEndDate = endDate;
    try {
      final date = TimeUtils.parseToIST(endDate);
      formattedEndDate = TimeUtils.formatPlanDate(date);
    } catch (e) {
      debugPrint('Error parsing end date: $e');
    }

    // Check if subscription is expiring soon (within 7 days)
    bool isExpiringSoon = false;
    try {
      final endDateTime = TimeUtils.parseToIST(endDate);
      final now = TimeUtils.getCurrentIST();
      final daysUntilExpiry = endDateTime.difference(now).inDays;
      isExpiringSoon = daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
    } catch (e) {
      debugPrint('Error calculating expiry: $e');
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              // Status Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 48,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                _getStatusTitle(status),
                style: TextStyle(
                  fontSize: FontSize.s20,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: FontSize.s12,
                    fontWeight: FontWeightManager.semiBold,
                    color: _getStatusColor(status),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
                    _buildDetailRow('Plan Name', planName),
                    const SizedBox(height: 8),
                    _buildDetailRow('Description', planDescription),
                    const SizedBox(height: 8),
                    _buildDetailRow('Valid Until', formattedEndDate),
                    const SizedBox(height: 8),
                    _buildDetailRow('Subscription ID', subscriptionId),
                    const SizedBox(height: 8),
                    _buildDetailRow('Amount Paid', '₹$amountPaid'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Payment Status', paymentStatus),
                  ],
                ),
              ),
              
              // Expiry Warning
              if (isExpiringSoon && status == 'ACTIVE')
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your subscription expires soon!',
                          style: TextStyle(
                            fontSize: FontSize.s14,
                            fontWeight: FontWeightManager.medium,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              if (status == 'ACTIVE') ...[
                // Renew/Upgrade buttons for active subscriptions
                if (isExpiringSoon) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRenewSubscription ?? onViewPlans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Renew Subscription',
                        style: TextStyle(
                          fontSize: FontSize.s16,
                          fontWeight: FontWeightManager.semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onUpgradeSubscription ?? onViewPlans,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorManager.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Other Plans',
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (status == 'PENDING') ...[
                // For pending subscriptions, show view plans option
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewPlans,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Other Plans',
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Go to Home Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onGoToHome,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorManager.textGrey.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.medium,
                      color: ColorManager.textGrey,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'EXPIRED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return ColorManager.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ACTIVE':
        return Icons.check_circle_outline;
      case 'PENDING':
        return Icons.pending_actions;
      case 'EXPIRED':
        return Icons.schedule;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Active Subscription';
      case 'PENDING':
        return 'Subscription Pending';
      case 'EXPIRED':
        return 'Subscription Expired';
      case 'CANCELLED':
        return 'Subscription Cancelled';
      default:
        return 'Subscription Status';
    }
  }
} 