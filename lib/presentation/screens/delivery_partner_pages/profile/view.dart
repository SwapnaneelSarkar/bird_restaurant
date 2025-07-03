import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../resources/colors.dart';
import '../../../resources/font.dart';

class DeliveryPartnerProfileView extends StatelessWidget {
  const DeliveryPartnerProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final primary = ColorManager.primary;

    // Mock profile data
    final profile = {
      'name': 'Ravi Kumar',
      'phone': '+91 9876543210',
      'email': 'ravi.kumar@email.com',
      'id': 'DP12345',
      'status': 'Active',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeightManager.semiBold,
            fontSize: FontSize.s18,
          ),
        ),
      ),
      backgroundColor: ColorManager.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(Icons.account_circle, size: 80, color: primary),
            ),
            SizedBox(height: h * 0.03),
            Text(
              profile['name']!,
              style: GoogleFonts.poppins(
                fontSize: FontSize.s20,
                fontWeight: FontWeightManager.semiBold,
                color: primary,
              ),
            ),
            SizedBox(height: h * 0.01),
            Text(
              profile['phone']!,
              style: GoogleFonts.poppins(
                fontSize: FontSize.s14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: h * 0.01),
            Text(
              profile['email']!,
              style: GoogleFonts.poppins(
                fontSize: FontSize.s14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: h * 0.03),
            Divider(color: Colors.grey[300]),
            SizedBox(height: h * 0.03),
            _ProfileDetailRow(label: 'Partner ID', value: profile['id']!),
            SizedBox(height: h * 0.01),
            _ProfileDetailRow(label: 'Status', value: profile['status']!),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
} 