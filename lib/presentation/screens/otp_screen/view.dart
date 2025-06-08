// lib/presentation/screens/otp_screen/view.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/enums.dart';
import '../../../ui_components/custom_button.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OtpView extends StatelessWidget {
  final String? mobileNumber;
  
  const OtpView({Key? key, this.mobileNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get phone number from either parameter or route arguments
    final String? phoneNumber = mobileNumber ?? 
        ModalRoute.of(context)?.settings.arguments as String?;
    
    debugPrint('OtpView received phone number: $phoneNumber');
    
    return BlocProvider<OtpBloc>(
      create: (context) {
        final bloc = OtpBloc();
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          bloc.add(InitializeOtpEvent(phoneNumber));
        } else {
          debugPrint('ERROR: No phone number received in OtpView');
        }
        return bloc;
      },
      child: const OtpViewContent(),
    );
  }
}

class OtpViewContent extends StatefulWidget {
  const OtpViewContent({Key? key}) : super(key: key);

  @override
  State<OtpViewContent> createState() => _OtpViewContentState();
}

class _OtpViewContentState extends State<OtpViewContent> {
  // Using a single controller instead of 6 individual ones
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeHeight = size.height - padding.top - padding.bottom;
    
    // Responsive breakpoints
    final isSmallScreen = size.height < 600;
    final isMediumScreen = size.height >= 600 && size.height < 800;
    
    // Responsive dimensions
    final logoHeight = isSmallScreen ? safeHeight * 0.15 : safeHeight * 0.2;
    final titleFontSize = isSmallScreen ? FontSize.s20 : FontSize.s25;
    final subtitleFontSize = isSmallScreen ? FontSize.s14 : FontSize.s16;
    final buttonHeight = isSmallScreen ? 50.0 : 56.0;
    final horizontalPadding = size.width * 0.06;
    final verticalSpacing = isSmallScreen ? 12.0 : 16.0;

    return BlocListener<OtpBloc, OtpState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        debugPrint('BlocListener triggered with status: ${state.status}');
        debugPrint('BlocListener API status: ${state.apiStatus}');
        
        if (state.status == OtpStatus.success) {
          debugPrint('OTP success - API status: ${state.apiStatus}');
          
          if (state.apiStatus == 'SUCCESS') {
            debugPrint('Routing new user to details page');
            // For new users (SUCCESS) - go to registration flow
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.detailsAdd,
              (route) => false,
            );
          } else if (state.apiStatus == 'EXISTS') {
            debugPrint('Routing existing user to home page');
            // For existing users (EXISTS) - go to home page
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.homePage, 
              (route) => false,
            );
          } else {
            debugPrint('Routing default case to home page');
            // Default case - go to home page
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.homePage,
              (route) => false,
            );
          }
        } else if (state.status == OtpStatus.failure) {
          debugPrint('OTP failure: ${state.errorMessage}');
          
          // Clear the OTP field on failure
          _otpController.clear();
          _otpFocusNode.requestFocus();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'OTP verification failed'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.status == OtpStatus.unauthorized) {
          debugPrint('OTP unauthorized: ${state.errorMessage}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.signin,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              'assets/images/login.jpg',
              fit: BoxFit.cover,
            ),

            // Dark overlay
            Container(
              color: Colors.black.withOpacity(0.7),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [                            
                            // Logo
                            Image.asset(
                              'assets/svg/logo_text.png',
                              height: logoHeight,
                            ),
                            
                            SizedBox(height: verticalSpacing),
                            
                            // Title
                            Text(
                              'Enter OTP',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeightManager.semiBold,
                                color: ColorManager.textWhite,
                              ),
                            ),
                            
                            SizedBox(height: verticalSpacing),
                            
                            // Subtitle
                            Text(
                              'We have sent an OTP to your mobile number',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFontSize,
                                color: ColorManager.textWhite.withOpacity(0.9),
                              ),
                            ),
                            
                            SizedBox(height: verticalSpacing * 3),
                            
                            // OTP input as a single TextField instead of 6 boxes
                            BlocBuilder<OtpBloc, OtpState>(
                              buildWhen: (previous, current) => 
                                previous.digits != current.digits || 
                                previous.status != current.status,
                              builder: (context, state) {
                                // Update controller if needed to reflect state
                                final stateOtp = state.digits.join();
                                if (_otpController.text != stateOtp) {
                                  _otpController.text = stateOtp;
                                }
                                
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      width: size.width * 0.7,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _otpFocusNode.hasFocus 
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.2),
                                          width: _otpFocusNode.hasFocus ? 2 : 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _otpController,
                                        focusNode: _otpFocusNode,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          color: ColorManager.textWhite,
                                          fontSize: FontSize.s18,
                                          fontWeight: FontWeightManager.semiBold,
                                          letterSpacing: 8, // Spaced for OTP look
                                        ),
                                        maxLength: 6,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                          hintText: '• • • • • •',
                                          hintStyle: GoogleFonts.poppins(
                                            color: ColorManager.textWhite.withOpacity(0.6),
                                            fontSize: FontSize.s18,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (val) {
                                          // Update each digit in the bloc
                                          final digits = val.split('');
                                          for (int i = 0; i < 6; i++) {
                                            final digit = i < digits.length ? digits[i] : '';
                                            context.read<OtpBloc>().add(OtpDigitChanged(i, digit));
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: verticalSpacing * 4),
                            
                            // Verify button
                            BlocBuilder<OtpBloc, OtpState>(
                              buildWhen: (previous, current) => 
                                previous.isButtonEnabled != current.isButtonEnabled ||
                                previous.status != current.status,
                              builder: (context, state) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: CustomButton(
                                    label: state.status == OtpStatus.validating 
                                      ? 'Verifying...' 
                                      : 'Verify OTP',
                                    onPressed: state.isButtonEnabled && state.status != OtpStatus.validating
                                      ? () {
                                          debugPrint('Verify button pressed');
                                          FocusScope.of(context).unfocus();
                                          context.read<OtpBloc>().add(SubmitOtpPressed());
                                        }
                                      : null,
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: verticalSpacing * 2),
                            
                            // Resend timer
                            BlocBuilder<OtpBloc, OtpState>(
                              buildWhen: (previous, current) => 
                                previous.remainingSeconds != current.remainingSeconds,
                              builder: (context, state) {
                                return GestureDetector(
                                  onTap: state.remainingSeconds <= 0
                                    ? () => context.read<OtpBloc>().add(ResendOtpEvent())
                                    : null,
                                  child: Text(
                                    state.remainingSeconds > 0
                                      ? "Didn't receive OTP? Resend in ${state.remainingSeconds}s"
                                      : "Didn't receive OTP? Tap to resend",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: FontSize.s12,
                                      color: ColorManager.textWhite,
                                      decoration: state.remainingSeconds <= 0 
                                        ? TextDecoration.underline 
                                        : TextDecoration.none,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: verticalSpacing * 2),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}