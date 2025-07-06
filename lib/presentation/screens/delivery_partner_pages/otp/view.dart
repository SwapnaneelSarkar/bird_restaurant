import 'package:bird_restaurant/constants/enums.dart';
import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';


class DeliveryPartnerOtpView extends StatelessWidget {
  final String? mobileNumber;
  const DeliveryPartnerOtpView({Key? key, this.mobileNumber}) : super(key: key);

  void _showNotRegisteredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Not Registered',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.primary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You are not registered as a delivery partner. Please contact support to register as a delivery partner.',
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to signin page
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? phoneNumber = mobileNumber ?? 
        ModalRoute.of(context)?.settings.arguments as String?;
    
    debugPrint('DeliveryPartnerOtpView received phone number: $phoneNumber');
    
    return BlocProvider<DeliveryPartnerOtpBloc>(
      create: (context) {
        final bloc = DeliveryPartnerOtpBloc();
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          bloc.add(DeliveryPartnerInitializeOtpEvent(phoneNumber));
        } else {
          debugPrint('ERROR: No phone number received in DeliveryPartnerOtpView');
        }
        return bloc;
      },
      child: BlocListener<DeliveryPartnerOtpBloc, DeliveryPartnerOtpState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == OtpStatus.success) {
            // Navigate to success page
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.deliveryPartnerAuthSuccess,
              (route) => false,
            );
          } else if (state.status == OtpStatus.failure) {
            if (state.apiStatus == 'not_registered') {
              // Show popup for unregistered users
              _showNotRegisteredDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'OTP verification failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: DeliveryPartnerOtpViewContent(),
      ),
    );
  }
}

class DeliveryPartnerOtpViewContent extends StatefulWidget {
  const DeliveryPartnerOtpViewContent({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerOtpViewContent> createState() => _DeliveryPartnerOtpViewContentState();
}

class _DeliveryPartnerOtpViewContentState extends State<DeliveryPartnerOtpViewContent> {
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
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    
    return Scaffold(
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
                      'Enter OTP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s22,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.primary,
                      ),
                    ),
                    SizedBox(height: h * 0.012),
                    Text(
                      'We have sent an OTP to your mobile number',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: h * 0.04),
                    DeliveryPartnerOtpInputField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                    ),
                    SizedBox(height: h * 0.03),
                    BlocBuilder<DeliveryPartnerOtpBloc, DeliveryPartnerOtpState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: h * 0.07,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.isButtonEnabled && state.status != OtpStatus.validating
                                  ? ColorManager.primary
                                  : Colors.grey[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: state.isButtonEnabled && state.status != OtpStatus.validating
                                ? () {
                                    context.read<DeliveryPartnerOtpBloc>().add(
                                      const DeliveryPartnerSubmitOtpPressed(),
                                    );
                                  }
                                : null,
                            child: state.status == OtpStatus.validating
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Verify OTP',
                                    style: GoogleFonts.poppins(
                                      fontSize: FontSize.s16,
                                      fontWeight: FontWeightManager.semiBold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: h * 0.03),
                    BlocBuilder<DeliveryPartnerOtpBloc, DeliveryPartnerOtpState>(
                      buildWhen: (previous, current) => 
                        previous.remainingSeconds != current.remainingSeconds,
                      builder: (context, state) {
                        return GestureDetector(
                          onTap: state.remainingSeconds <= 0
                            ? () => context.read<DeliveryPartnerOtpBloc>().add(const DeliveryPartnerResendOtpEvent())
                            : null,
                          child: Text(
                            state.remainingSeconds > 0
                              ? "Didn't receive OTP? Resend in ${state.remainingSeconds}s"
                              : "Didn't receive OTP? Tap to resend",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: FontSize.s12,
                              color: ColorManager.primary,
                              decoration: state.remainingSeconds <= 0 
                                ? TextDecoration.underline 
                                : TextDecoration.none,
                            ),
                          ),
                        );
                      },
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
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s12,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryPartnerOtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  DeliveryPartnerOtpInputField({
    Key? key,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    
    return BlocBuilder<DeliveryPartnerOtpBloc, DeliveryPartnerOtpState>(
      builder: (context, state) {
        return Container(
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
                Icons.lock,
                color: Colors.grey[700] ?? Colors.grey,
                size: h * 0.035,
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: ColorManager.primary,
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.semiBold,
                    letterSpacing: 8,
                  ),
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: '\u2022 \u2022 \u2022 \u2022 \u2022 \u2022',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400] ?? Colors.grey,
                      fontSize: FontSize.s18,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    // Update BLoC state with individual digits
                    final digits = List<String>.filled(6, '');
                    for (int i = 0; i < value.length && i < 6; i++) {
                      digits[i] = value[i];
                    }
                    
                    for (int i = 0; i < 6; i++) {
                      context.read<DeliveryPartnerOtpBloc>().add(
                        DeliveryPartnerOtpDigitChanged(i, digits[i]),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 