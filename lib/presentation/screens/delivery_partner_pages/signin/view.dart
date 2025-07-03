import 'dart:ui';
import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
import 'package:bird_restaurant/ui_components/country_picker.dart';
import 'package:bird_restaurant/ui_components/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class DeliveryPartnerSigninView extends StatelessWidget {
  const DeliveryPartnerSigninView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return BlocProvider<DeliveryPartnerSigninBloc>(
      create: (_) => DeliveryPartnerSigninBloc(),
      child: Scaffold(
        backgroundColor: ColorManager.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: h * 0.10),
                Image.asset(
                  'assets/svg/logo_text.png',
                  height: h * 0.13,
                ),
                SizedBox(height: h * 0.04),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to BIRD Delivery Partner',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: FontSize.s22,
                          fontWeight: FontWeightManager.semiBold,
                          color: ColorManager.primary,
                        ),
                      ),
                      SizedBox(height: h * 0.012),
                      Text(
                        'Sign in with your mobile number',
                        style: GoogleFonts.poppins(
                          fontSize: FontSize.s16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: h * 0.04),
                      const DeliveryPartnerMobileInputField(),
                      SizedBox(height: h * 0.03),
                      SizedBox(
                        width: double.infinity,
                        height: h * 0.07,
                        child: BlocBuilder<DeliveryPartnerSigninBloc, DeliveryPartnerSigninState>(
                          builder: (context, state) {
                            return CustomButton(
                              label: 'Send OTP',
                              onPressed: state.mobileNumber.length >= 5 ? () {
                                final formattedNumber = '${state.selectedCountry.dialCode}${state.mobileNumber}';
                                debugPrint('Navigating with phone number: $formattedNumber');
                                context.read<DeliveryPartnerSigninBloc>().add(const DeliveryPartnerSendOtpPressed());
                                Navigator.pushNamed(
                                  context,
                                  Routes.deliveryPartnerOtp,
                                  arguments: formattedNumber,
                                );
                              } : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.04),
                Divider(
                  color: Colors.grey[300],
                  thickness: 1.1,
                  indent: w * 0.18,
                  endIndent: w * 0.18,
                ),
                SizedBox(height: h * 0.01),
                Padding(
                  padding: EdgeInsets.only(bottom: h * 0.02),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s12,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey[700],
                      ),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.poppins(
                            fontSize: FontSize.s12,
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, Routes.terms);
                            },
                        ),
                        const TextSpan(text: ' and\n'),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.poppins(
                            fontSize: FontSize.s12,
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, Routes.privacy);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryPartnerMobileInputField extends StatelessWidget {
  const DeliveryPartnerMobileInputField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return BlocBuilder<DeliveryPartnerSigninBloc, DeliveryPartnerSigninState>(
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
                  Icon(
                    Icons.phone,
                    color: Colors.grey[700] ?? Colors.grey,
                    size: h * 0.035,
                  ),
                  SizedBox(width: w * 0.02),
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
                          Text(
                            state.selectedCountry.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: w * 0.015),
                          Text(
                            state.selectedCountry.dialCode,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700] ?? Colors.grey,
                              fontSize: FontSize.s14,
                              fontWeight: FontWeightManager.medium,
                            ),
                          ),
                          SizedBox(width: w * 0.01),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.7),
                            size: h * 0.022,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700] ?? Colors.grey,
                        fontSize: FontSize.s16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter mobile number',
                        hintStyle: GoogleFonts.poppins(
                          color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                          fontSize: FontSize.s16,
                        ),
                      ),
                      onChanged: (value) {
                        context.read<DeliveryPartnerSigninBloc>().add(DeliveryPartnerMobileNumberChanged(value));
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
    final signinBloc = context.read<DeliveryPartnerSigninBloc>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => CountryPickerBottomSheet(
        selectedCountry: signinBloc.state.selectedCountry,
        onCountrySelected: (country) {
          signinBloc.add(DeliveryPartnerCountryChanged(country));
        },
      ),
    );
  }
} 