// lib/presentation/screens/order_action_result/view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';

class OrderActionResultView extends StatelessWidget {
  final String orderId;
  final String action; // 'accepted' or 'cancelled'
  final bool isSuccess;

  const OrderActionResultView({
    Key? key,
    required this.orderId,
    required this.action,
    required this.isSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        elevation: 0,
        title: Text(
          'Order Action Result',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeightManager.semiBold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.orders,
            (route) => false,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isSuccess 
                      ? (action == 'accepted' ? Colors.green[50] : Colors.red[50])
                      : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess 
                      ? (action == 'accepted' ? Icons.check_circle : Icons.cancel)
                      : Icons.error,
                  size: 60,
                  color: isSuccess 
                      ? (action == 'accepted' ? Colors.green[600] : Colors.red[600])
                      : Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                isSuccess 
                    ? (action == 'accepted' ? 'Order Accepted!' : 'Order Cancelled!')
                    : 'Action Failed',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeightManager.bold,
                  color: isSuccess 
                      ? (action == 'accepted' ? Colors.green[700] : Colors.red[700])
                      : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                isSuccess 
                    ? (action == 'accepted' 
                        ? 'Order #$orderId has been accepted and confirmed'
                        : 'Order #$orderId has been cancelled')
                    : 'Failed to process order action. Please try again.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Status details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Order ID', '#$orderId'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Action', action.toUpperCase()),
                    const SizedBox(height: 8),
                    _buildInfoRow('Status', isSuccess 
                        ? (action == 'accepted' ? 'CONFIRMED' : 'CANCELLED')
                        : 'FAILED'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Time', DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.orders,
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Orders',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeightManager.semiBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.homePage,
                        (route) => false,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: ColorManager.primary),
                      ),
                      child: Text(
                        'Go Home',
                        style: GoogleFonts.poppins(
                          color: ColorManager.primary,
                          fontWeight: FontWeightManager.semiBold,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeightManager.medium,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeightManager.semiBold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
} 