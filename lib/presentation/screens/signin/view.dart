// lib/presentation/screens/login/view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui_components/custom_button.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,                    
          children: [
            // full-screen background
            Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
            ),

            // full-screen dark overlay
            Container(color: Colors.black.withOpacity(0.7)),

            // your content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SizedBox(height: h * 0.02),
                    Image.asset(
                      'assets/svg/logo_text.png',
                      height: h * 0.2,
                    ),
                    // SizedBox(height: h * 0.02),
                    Text(
                      'Welcome to BIRD Partner',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s22,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.textWhite,
                      ),
                    ),
                    SizedBox(height: h * 0.015),
                    Text(
                      'Sign in with your mobile number',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s16,
                        color: ColorManager.textWhite.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: h * 0.05),
                    _MobileInputField(),
                    SizedBox(height: h * 0.03),
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.07,
                      child: BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          return CustomButton(
                            label: 'Send OTP',
                            onPressed: state.mobileNumber.isNotEmpty ? () {
                              // Format the phone number
                              final formattedNumber = '+91${state.mobileNumber}';
                              
                              // Debug print
                              debugPrint('Navigating with phone number: $formattedNumber');
                              
                              // Fire bloc event
                              context.read<LoginBloc>().add(SendOtpPressed());
                              
                              // Navigate to OTP screen with formatted number
                              Navigator.pushNamed(
                                context,
                                Routes.otp,
                                arguments: formattedNumber,
                              );
                            } : null,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.02),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: FontSize.s12,
                            fontWeight: FontWeightManager.regular,
                            color: ColorManager.textWhite,
                          ),
                          children: [
                            const TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: GoogleFonts.poppins(
                                fontSize: FontSize.s12,
                                fontWeight: FontWeightManager.semiBold,
                                color: ColorManager.textWhite,
                              ),
                            ),
                            const TextSpan(text: ' and\n'),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: GoogleFonts.poppins(
                                fontSize: FontSize.s12,
                                fontWeight: FontWeightManager.semiBold,
                                color: ColorManager.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _MobileInputField extends StatelessWidget {
  const _MobileInputField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: h * 0.07,
              padding: EdgeInsets.symmetric(horizontal: w * 0.03),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // translucent white
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.white, size: h * 0.035),
                  SizedBox(width: w * 0.02),
                  Text(
                    '+91',
                    style: GoogleFonts.poppins(
                      color: ColorManager.textWhite,
                      fontSize: FontSize.s16,
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: GoogleFonts.poppins(
                        color: ColorManager.textWhite,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter mobile number',
                        hintStyle: GoogleFonts.poppins(
                          color: ColorManager.textWhite.withOpacity(0.6),
                        ),
                      ),
                      onChanged: (val) => context
                          .read<LoginBloc>()
                          .add(MobileNumberChanged(val)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}