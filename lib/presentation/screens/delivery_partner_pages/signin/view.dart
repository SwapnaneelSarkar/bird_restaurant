import 'dart:ui';
import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
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
                        'Sign in with your credentials',
                        style: GoogleFonts.poppins(
                          fontSize: FontSize.s16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: h * 0.04),
                      // Username Field with Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username *',
                            style: GoogleFonts.poppins(
                              fontSize: FontSize.s14,
                              fontWeight: FontWeightManager.medium,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: h * 0.008),
                          const DeliveryPartnerUsernameInputField(),
                        ],
                      ),
                      SizedBox(height: h * 0.02),
                      // Password Field with Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password *',
                            style: GoogleFonts.poppins(
                              fontSize: FontSize.s14,
                              fontWeight: FontWeightManager.medium,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: h * 0.008),
                          const DeliveryPartnerPasswordInputField(),
                        ],
                      ),
                      SizedBox(height: h * 0.03),
                      BlocListener<DeliveryPartnerSigninBloc, DeliveryPartnerSigninState>(
                        listener: (context, state) {
                          if (state.status == DeliveryPartnerSigninStatus.success) {
                            Navigator.pushNamedAndRemoveUntil(
                              context, 
                              Routes.deliveryPartnerDashboard,
                              (route) => false,
                            );
                          } else if (state.status == DeliveryPartnerSigninStatus.error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage ?? 'Authentication failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: h * 0.07,
                          child: BlocBuilder<DeliveryPartnerSigninBloc, DeliveryPartnerSigninState>(
                            builder: (context, state) {
                              return CustomButton(
                                label: state.status == DeliveryPartnerSigninStatus.loading 
                                    ? 'Signing In...' 
                                    : 'Sign In',
                                onPressed: state.isValid && state.status != DeliveryPartnerSigninStatus.loading 
                                    ? () {
                                        context.read<DeliveryPartnerSigninBloc>().add(const DeliveryPartnerSignInPressed());
                                      } 
                                    : null,
                              );
                            },
                          ),
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

class DeliveryPartnerUsernameInputField extends StatelessWidget {
  const DeliveryPartnerUsernameInputField({Key? key}) : super(key: key);

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
              child: TextField(
                style: GoogleFonts.poppins(
                  color: Colors.grey[700] ?? Colors.grey,
                  fontSize: FontSize.s16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter username',
                  hintStyle: GoogleFonts.poppins(
                    color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                    fontSize: FontSize.s16,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                  ),
                ),
                onChanged: (value) {
                  context.read<DeliveryPartnerSigninBloc>().add(DeliveryPartnerUsernameChanged(value));
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class DeliveryPartnerPasswordInputField extends StatefulWidget {
  const DeliveryPartnerPasswordInputField({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerPasswordInputField> createState() => _DeliveryPartnerPasswordInputFieldState();
}

class _DeliveryPartnerPasswordInputFieldState extends State<DeliveryPartnerPasswordInputField> {
  bool _obscureText = true;

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
              child: TextField(
                obscureText: _obscureText,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700] ?? Colors.grey,
                  fontSize: FontSize.s16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter password',
                  hintStyle: GoogleFonts.poppins(
                    color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                    fontSize: FontSize.s16,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: (Colors.grey[700] ?? Colors.grey).withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  context.read<DeliveryPartnerSigninBloc>().add(DeliveryPartnerPasswordChanged(value));
                },
              ),
            ),
          ),
        );
      },
    );
  }
} 