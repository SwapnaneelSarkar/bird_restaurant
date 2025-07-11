import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliveryPartnerAuthSuccessView extends StatelessWidget {
  const DeliveryPartnerAuthSuccessView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  color: ColorManager.primary,
                  size: h * 0.12,
                ),
                SizedBox(height: h * 0.04),
                Text(
                  'Authentication Successful!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s22,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.primary,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'You have successfully logged in as a Delivery Partner.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: h * 0.04),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/deliveryPartnerDashboard',
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Go to Home',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.semiBold,
                      color: Colors.white,
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
} 