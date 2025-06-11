// lib/presentation/screens/signin/view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../ui_components/custom_button.dart';
import '../../../ui_components/country_picker.dart';
import '../../../models/country.dart';
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
            // Background image
            Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
            ),

            // Dark overlay
            Container(color: Colors.black.withOpacity(0.7)),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/svg/logo_text.png',
                      height: h * 0.2,
                    ),
                    
                    // Welcome text
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
                    
                    // Subtitle
                    Text(
                      'Sign in with your mobile number',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s16,
                        color: ColorManager.textWhite.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: h * 0.05),
                    
                    // Mobile input field with country picker
                    const MobileInputField(),
                    SizedBox(height: h * 0.03),
                    
                    // Send OTP button
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.07,
                      child: BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          return CustomButton(
                            label: 'Send OTP',
                            onPressed: state.mobileNumber.isNotEmpty ? () {
                              // Format the phone number using selected country
                              final formattedNumber = '${state.selectedCountry.dialCode}${state.mobileNumber}';
                              
                              debugPrint('Navigating with phone number: $formattedNumber');
                              
                              // Fire bloc event
                              context.read<LoginBloc>().add(SendOtpPressed());
                              
                              // Navigate to OTP screen
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
                    
                    // Terms and privacy policy
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

class MobileInputField extends StatelessWidget {
  const MobileInputField({Key? key}) : super(key: key);

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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Phone icon
                  Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: h * 0.035,
                  ),
                  SizedBox(width: w * 0.02),
                  
                  // Country picker
                  GestureDetector(
                    onTap: () => _showCountryPicker(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025,
                        vertical: h * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Flag
                          Text(
                            state.selectedCountry.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: w * 0.015),
                          
                          // Dial code
                          Text(
                            state.selectedCountry.dialCode,
                            style: GoogleFonts.poppins(
                              color: ColorManager.textWhite,
                              fontSize: FontSize.s14,
                              fontWeight: FontWeightManager.medium,
                            ),
                          ),
                          SizedBox(width: w * 0.01),
                          
                          // Dropdown arrow
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.7),
                            size: h * 0.022,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: w * 0.025),
                  
                  // Phone number input
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: GoogleFonts.poppins(
                        color: ColorManager.textWhite,
                        fontSize: FontSize.s16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter mobile number',
                        hintStyle: GoogleFonts.poppins(
                          color: ColorManager.textWhite.withOpacity(0.6),
                          fontSize: FontSize.s16,
                        ),
                      ),
                      onChanged: (value) {
                        context.read<LoginBloc>().add(MobileNumberChanged(value));
                      },
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

  void _showCountryPicker(BuildContext context) {
    final loginBloc = context.read<LoginBloc>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => CountryPickerBottomSheet(
        selectedCountry: loginBloc.state.selectedCountry,
        onCountrySelected: (country) {
          loginBloc.add(CountryChanged(country));
        },
      ),
    );
  }
}