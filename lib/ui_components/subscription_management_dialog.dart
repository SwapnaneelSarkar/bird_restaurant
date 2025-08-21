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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStatusColor(status).withOpacity(0.1),
                    _getStatusColor(status).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Status Icon with enhanced styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 48,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title with enhanced typography
                  Text(
                    _getStatusTitle(status),
                    style: TextStyle(
                      fontSize: FontSize.s25,
                      fontWeight: FontWeightManager.bold,
                      color: ColorManager.black,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Status Badge with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                                          child: Text(
                        status,
                        style: TextStyle(
                          fontSize: FontSize.s12,
                          fontWeight: FontWeightManager.bold,
                          color: _getStatusColor(status),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Subscription Details with enhanced card design
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorManager.primary.withOpacity(0.08),
                            ColorManager.primary.withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorManager.primary.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Plan name with special highlighting
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ColorManager.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan Name',
                                  style: TextStyle(
                                    fontSize: FontSize.s12,
                                    fontWeight: FontWeightManager.medium,
                                    color: ColorManager.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  planName,
                                  style: TextStyle(
                                    fontSize: FontSize.s18,
                                    fontWeight: FontWeightManager.bold,
                                    color: ColorManager.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Other details
                          _buildEnhancedDetailRow('Description', planDescription),
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow('Valid Until', formattedEndDate),
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow('Subscription ID', subscriptionId),
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow('Amount Paid', '₹$amountPaid'),
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow('Payment Status', paymentStatus),
                        ],
                      ),
                    ),
                    
                    // Expiry Warning with enhanced styling
                    if (isExpiringSoon && status == 'ACTIVE') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.withOpacity(0.15),
                              Colors.orange.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[700],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subscription Expiring Soon!',
                                    style: TextStyle(
                                      fontSize: FontSize.s14,
                                      fontWeight: FontWeightManager.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Renew your subscription to continue enjoying our services.',
                                    style: TextStyle(
                                      fontSize: FontSize.s12,
                                      color: Colors.orange[600],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons with enhanced styling
                    if (status == 'ACTIVE') ...[
                      if (isExpiringSoon) ...[
                        _buildGradientButton(
                          'Renew Subscription',
                          onRenewSubscription ?? onViewPlans,
                          [
                            Colors.orange[600]!,
                            Colors.orange[500]!,
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      _buildOutlinedButton(
                        'View Other Plans',
                        onUpgradeSubscription ?? onViewPlans,
                        ColorManager.primary,
                      ),
                      const SizedBox(height: 12),
                    ] else if (status == 'PENDING') ...[
                      _buildGradientButton(
                        'View Other Plans',
                        onViewPlans,
                        [
                          ColorManager.primary,
                          ColorManager.primary.withOpacity(0.8),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Go to Home Button with enhanced styling
                    _buildEnhancedHomeButton(
                      'Go to Home',
                      onGoToHome,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: FontSize.s12,
                fontWeight: FontWeightManager.medium,
                color: ColorManager.textGrey,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: FontSize.s12,
                fontWeight: FontWeightManager.semiBold,
                color: ColorManager.black,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed, List<Color> colors) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: FontSize.s16,
            fontWeight: FontWeightManager.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: FontSize.s16,
            fontWeight: FontWeightManager.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHomeButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary,
            ColorManager.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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