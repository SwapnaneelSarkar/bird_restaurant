import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../models/delivery_partner_model.dart';
import '../../../services/token_service.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../services/delivery_partners_service.dart';
import '../../../presentation/resources/colors.dart';
import '../../../presentation/resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import 'package:flutter/services.dart';
import '../../../models/country.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../presentation/resources/router/router.dart';

class DeliveryPartnersView extends StatefulWidget {
  const DeliveryPartnersView({super.key});

  @override
  State<DeliveryPartnersView> createState() => _DeliveryPartnersViewState();
}

class _DeliveryPartnersViewState extends State<DeliveryPartnersView> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, String>? _restaurantInfo;

  @override
  void initState() {
    super.initState();
    context.read<DeliveryPartnersBloc>().add(LoadDeliveryPartners());
    _loadRestaurantInfo();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final info = await RestaurantInfoService.getRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
        });
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  void _openSidebar() {
    try {
      _scaffoldKey.currentState?.openDrawer();
    } catch (e) {
      debugPrint('Error opening sidebar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(Routes.homePage, (route) => false);
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: SidebarDrawer(
          activePage: 'deliveryPartners',
          restaurantName: _restaurantInfo?['name'] ?? 'Delivery Partners',
          restaurantSlogan:
              _restaurantInfo?['slogan'] ?? 'Manage your delivery partners',
          restaurantImageUrl: _restaurantInfo?['imageUrl'],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocConsumer<
                  DeliveryPartnersBloc,
                  DeliveryPartnersState
                >(
                  listener: (context, state) {
                    if (state is DeliveryPartnerAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery partner added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Close modal on success
                      }
                    } else if (state is DeliveryPartnerEdited) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Delivery partner updated successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Close modal on success
                      }
                    } else if (state is DeliveryPartnersError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Close modal on error
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is DeliveryPartnersLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorManager.primary,
                          ),
                        ),
                      );
                    } else if (state is DeliveryPartnersLoaded) {
                      return _buildPartnersList(state.partners);
                    } else if (state is DeliveryPartnersRefreshing) {
                      return _buildPartnersList(state.partners);
                    } else if (state is DeliveryPartnersError) {
                      // Show partners list if available, otherwise show empty state
                      if (state.partners != null &&
                          state.partners!.isNotEmpty) {
                        return _buildPartnersList(state.partners!);
                      } else {
                        return const Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              fontFamily: FontConstants.fontFamily,
                              fontSize: FontSize.s16,
                            ),
                          ),
                        );
                      }
                    }
                    // Default case
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(
                          fontFamily: FontConstants.fontFamily,
                          fontSize: FontSize.s16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final partnerId = await TokenService.getUserId();
            if (partnerId != null && mounted) {
              if (mounted) {
                _showAddPartnerModal(
                  context,
                  partnerId,
                  context.read<DeliveryPartnersBloc>(),
                );
              }
            }
          },
          backgroundColor: ColorManager.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: _openSidebar,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.menu_rounded,
                color: Colors.black87,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Delivery Partners',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersList(List<DeliveryPartner> partners) {
    if (partners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Delivery Partners',
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.semiBold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery partner to get started',
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeliveryPartnersBloc>().add(RefreshDeliveryPartners());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: partners.length,
        itemBuilder: (context, index) {
          final partner = partners[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Primary color accent bar
                Container(
                  width: 6,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: ColorManager.primary,
                      child: Text(
                        partner.name.isNotEmpty
                            ? partner.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      partner.name,
                      style: const TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${partner.phone}',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${partner.deliveryPartnerId}',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: 13.0,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${partner.status}',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                partner.status == 'ACTIVE'
                                    ? ColorManager.primary
                                    : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            partner.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.edit, color: ColorManager.primary),
                          tooltip: 'Edit Partner',
                          onPressed: () {
                            _showEditPartnerModal(
                              context,
                              partner,
                              context.read<DeliveryPartnersBloc>(),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: ColorManager.primary,
                          ),
                          tooltip: 'Delete Partner',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text(
                                      'Delete Delivery Partner',
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete ${partner.name}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ColorManager.primary,
                                        ),
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              _deleteDeliveryPartner(
                                context,
                                partner.deliveryPartnerId,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteDeliveryPartner(
    BuildContext context,
    String deliveryPartnerId,
  ) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No token found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final response = await DeliveryPartnersService().deleteDeliveryPartner(
        deliveryPartnerId,
        token,
      );
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery partner deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<DeliveryPartnersBloc>().add(RefreshDeliveryPartners());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddPartnerModal(
    BuildContext context,
    String partnerId,
    DeliveryPartnersBloc bloc,
  ) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String username = '';
    String password = '';
    File? licensePhotoFile;
    File? vehicleDocumentFile;
    bool isSubmitting = false;
    Country selectedCountry = CountryData.countries.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddPartnerBottomSheet(partnerId: partnerId, bloc: bloc);
      },
    );
  }

  void _showEditPartnerModal(
    BuildContext context,
    DeliveryPartner partner,
    DeliveryPartnersBloc bloc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditPartnerBottomSheet(partner: partner, bloc: bloc);
      },
    );
  }
}

class _AddPartnerBottomSheet extends StatefulWidget {
  final String partnerId;
  final DeliveryPartnersBloc bloc;

  const _AddPartnerBottomSheet({required this.partnerId, required this.bloc});

  @override
  State<_AddPartnerBottomSheet> createState() => _AddPartnerBottomSheetState();
}

class _AddPartnerBottomSheetState extends State<_AddPartnerBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  String email = '';
  String username = '';
  String password = '';
  File? licensePhotoFile;
  File? vehicleDocumentFile;
  bool isSubmitting = false;
  Country selectedCountry = CountryData.countries.first;

  // OTP state
  String otp = '';
  String verificationId = '';
  bool otpSent = false;
  bool otpVerified = false;
  bool otpLoading = false;
  String otpError = '';
  bool isLicensePhotoValid = true;
  bool isVehicleDocValid = true;

  @override
  void initState() {
    super.initState();
    // Initialize OTP state variables
    otp = '';
    verificationId = '';
    otpSent = false;
    otpVerified = false;
    otpLoading = false;
    otpError = '';
  }

  // Function to send OTP
  Future<void> sendOtp() async {
    setState(() {
      otpLoading = true;
      otpError = '';
    });
    final fullPhone = '${selectedCountry.dialCode}${phone.trim()}';

    try {
      debugPrint('Sending OTP to: $fullPhone');

      // Check if it's a test phone number
      if (fullPhone == '+911111111111') {
        debugPrint('Test phone number detected');
        if (Platform.isIOS) {
          debugPrint('iOS test mode - using test verification ID');
          setState(() {
            verificationId = 'test-verification-id';
            otpSent = true;
            otpLoading = false;
          });
          return;
        } else {
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: true,
            forceRecaptchaFlow: false,
          );
        }
      } else {
        // ✅ FOR REAL PHONE NUMBERS - SAME AS RESTAURANT PARTNER
        debugPrint('Real phone number - enabling reCAPTCHA fallback');
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: false,
          forceRecaptchaFlow: true, // Same as restaurant partner
        );
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Verification completed automatically');
          setState(() {
            otpVerified = true;
            otpLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          String errorMessage;
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'The provided phone number is not valid.';
          } else if (e.code == 'missing-client-identifier') {
            errorMessage =
                'Missing client identifier. Please check your Firebase configuration.';
          } else if (e.code == 'app-not-authorized') {
            errorMessage =
                'This app is not authorized to use Firebase Authentication.';
          } else {
            errorMessage = e.message ?? 'OTP verification failed';
          }
          setState(() {
            otpError = errorMessage;
            otpLoading = false;
          });
        },
        codeSent: (String vId, int? resendToken) {
          debugPrint('✅ Code sent! Verification ID: $vId');
          setState(() {
            verificationId = vId;
            otpSent = true;
            otpLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String vId) {
          debugPrint('⏰ Auto retrieval timeout. Verification ID: $vId');
          setState(() {
            verificationId = vId;
            otpLoading = false;
            // Don't show error for timeout, just let user enter manually
          });
        },
      );
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      setState(() {
        otpError = 'Failed to send OTP: $e';
        otpLoading = false;
      });
    }
  }

  // Function to verify OTP
  Future<void> verifyOtp() async {
    setState(() {
      otpLoading = true;
      otpError = '';
    });

    try {
      final fullPhone = '${selectedCountry.dialCode}${phone.trim()}';

      // Handle test phone number
      if (fullPhone == '+911111111111') {
        debugPrint('Test phone number - checking for test OTP');
        if (otp == '000000' || otp == '123456') {
          debugPrint('Test OTP verified successfully');
          setState(() {
            otpVerified = true;
            otpLoading = false;
          });
          return;
        } else {
          setState(() {
            otpError = 'Invalid test OTP. Use 000000 or 123456';
            otpLoading = false;
          });
          return;
        }
      }

      // For real phone numbers, use Firebase verification
      if (verificationId.isEmpty) {
        setState(() {
          otpError =
              'Verification ID not available. Please try sending OTP again.';
          otpLoading = false;
        });
        return;
      }

      debugPrint('Verifying OTP with Firebase');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with Firebase temporarily to validate OTP
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        debugPrint('Firebase OTP verification successful');

        // Sign out from Firebase immediately - we don't want to keep user signed in
        await FirebaseAuth.instance.signOut();
        debugPrint('Signed out from Firebase after OTP verification');

        setState(() {
          otpVerified = true;
          otpLoading = false;
        });
      } else {
        setState(() {
          otpError = 'Failed to verify OTP. Please try again.';
          otpLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage =
              'Verification session expired. Please request a new OTP.';
          break;
        case 'session-expired':
          errorMessage = 'Session expired. Please request a new OTP.';
          break;
        default:
          errorMessage = e.message ?? 'OTP verification failed';
      }
      setState(() {
        otpError = errorMessage;
        otpLoading = false;
      });
    } catch (e) {
      debugPrint('General error verifying OTP: $e');
      setState(() {
        otpError = 'Error verifying OTP: $e';
        otpLoading = false;
      });
    }
  }

  // Function to check if all required fields are filled
  bool _areAllFieldsFilled() {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        phone.isNotEmpty &&
        phone.trim().length == 10 &&
        RegExp(r'^\d{10}$').hasMatch(phone.trim()) &&
        licensePhotoFile != null &&
        vehicleDocumentFile != null &&
        otpVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Delivery Partner',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s18,
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              Text(
                'Name *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter delivery partner name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Name is required'
                            : null,
                onChanged: (value) => setState(() => name = value),
              ),
              const SizedBox(height: 20),

              // Email Field
              Text(
                'Email *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => email = value.trim()),
              ),
              const SizedBox(height: 20),

              // Username Field
              Text(
                'Username *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Username is required'
                            : null,
                onChanged: (value) => setState(() => username = value),
              ),
              const SizedBox(height: 20),

              // Password Field
              Text(
                'Password *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Password is required'
                            : null,
                onChanged: (value) => setState(() => password = value),
              ),
              const SizedBox(height: 20),

              // Phone Field
              Text(
                'Phone *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<Country>(
                    value: selectedCountry,
                    items:
                        CountryData.countries.map((country) {
                          return DropdownMenuItem<Country>(
                            value: country,
                            child: Row(
                              children: [
                                Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  country.dialCode,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (country) {
                      if (country != null) {
                        setState(() {
                          selectedCountry = country;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorManager.primary),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Phone is required';
                        }
                        if (trimmed.length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                          return 'Phone number must contain only digits';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() => phone = value.trim()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: otpLoading ? null : sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child:
                      otpLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Send OTP',
                                style: TextStyle(
                                  fontSize: FontSize.s16,
                                  fontWeight: FontWeightManager.medium,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              if (otpSent) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OTP sent to ${selectedCountry.dialCode}${phone.trim()}',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter OTP *',
                  style: TextStyle(
                    fontFamily: FontConstants.fontFamily,
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (val) => setState(() => otp = val),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.semiBold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: FontSize.s18,
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorManager.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    errorText: otpError.isNotEmpty ? otpError : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (otpLoading || otpVerified) ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          otpVerified ? Colors.green : ColorManager.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child:
                        otpLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  otpVerified
                                      ? Icons.check_circle
                                      : Icons.verified,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  otpVerified ? 'Verified' : 'Verify OTP',
                                  style: TextStyle(
                                    fontSize: FontSize.s16,
                                    fontWeight: FontWeightManager.medium,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ],

              // Resend OTP button
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s14,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: otpLoading ? null : sendOtp,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s14,
                        color: ColorManager.primary,
                        fontWeight: FontWeightManager.medium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // License Photo
              Text(
                'License Photo *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      licensePhotoFile = File(pickedFile.path);
                      isLicensePhotoValid = true;
                      print("isLicensePhotoValid :- $isLicensePhotoValid");
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          licensePhotoFile != null
                              ? ColorManager.primary
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.upload_file, color: ColorManager.primary),
                      const SizedBox(width: 14),
                      Expanded(
                                                  child: Text(
                            licensePhotoFile != null
                                ? licensePhotoFile!.path.split('/').last
                                : 'Select License Photo (Required)',
                            style: TextStyle(
                              fontFamily: FontConstants.fontFamily,
                              fontSize: FontSize.s14,
                              color: Colors.grey[700],
                            ),
                          ),
                      ),
                      if (licensePhotoFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
              if (!isLicensePhotoValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Text(
                    'This field is mandatory',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),

              // Vehicle Document
              Text(
                'Vehicle Document *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      vehicleDocumentFile = File(pickedFile.path);
                      isVehicleDocValid = true;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          vehicleDocumentFile != null
                              ? ColorManager.primary
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.upload_file, color: ColorManager.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          vehicleDocumentFile != null
                              ? vehicleDocumentFile!.path.split('/').last
                              : 'Select Vehicle Document (Required)',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      if (vehicleDocumentFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
              if (!isVehicleDocValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Text(
                    'This field is mandatory',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (isSubmitting || !_areAllFieldsFilled())
                          ? null
                          : () async {
                            bool licenseValid = licensePhotoFile != null;
                            bool vehicleValid = vehicleDocumentFile != null;

                            setState(() {
                              isLicensePhotoValid = licenseValid;
                              isVehicleDocValid = vehicleValid;
                            });

                            if (formKey.currentState!.validate() &&
                                licenseValid &&
                                vehicleValid) {
                              setState(() => isSubmitting = true);
                              widget.bloc.add(
                                AddDeliveryPartner(
                                  partnerId: widget.partnerId,
                                  phone: phone,
                                  name: name,
                                  email: email,
                                  username: username,
                                  password: password,
                                  licensePhotoPath: licensePhotoFile?.path,
                                  vehicleDocumentPath:
                                      vehicleDocumentFile?.path,
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isSubmitting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Add Partner',
                            style: TextStyle(
                              fontSize: FontSize.s16,
                              fontWeight: FontWeightManager.medium,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPartnerBottomSheet extends StatefulWidget {
  final DeliveryPartner partner;
  final DeliveryPartnersBloc bloc;

  const _EditPartnerBottomSheet({required this.partner, required this.bloc});

  @override
  State<_EditPartnerBottomSheet> createState() =>
      _EditPartnerBottomSheetState();
}

class _EditPartnerBottomSheetState extends State<_EditPartnerBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late String name;
  late String phone;
  late String? email;
  late String? vehicleType;
  late String? vehicleNumber;
  File? licensePhotoFile;
  File? vehicleDocumentFile;
  bool isSubmitting = false;
  bool isLicensePhotoValid = true;
  bool isVehicleDocValid = true;

  @override
  void initState() {
    super.initState();
    name = widget.partner.name;
    phone = widget.partner.phone;
    email = widget.partner.email;
    vehicleType = widget.partner.vehicleType;
    vehicleNumber = widget.partner.vehicleNumber;
    // License and vehicle doc are URLs, not files, so leave as null unless changed
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Delivery Partner',
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s18,
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Name Field
              Text(
                'Name *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  hintText: 'Enter delivery partner name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Name is required'
                            : null,
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 20),
              // Email Field
              Text(
                'Email',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) => email = value.trim(),
              ),
              const SizedBox(height: 20),
              // Phone Field
              Text(
                'Phone *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: phone,
                enabled: false, // Disable editing phone number
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Phone is required';
                  }
                  if (trimmed.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
                    return 'Phone number must contain only digits';
                  }
                  return null;
                },
                onChanged: (value) => phone = value.trim(),
              ),
              const SizedBox(height: 20),
              // Vehicle Type
              Text(
                'Vehicle Type',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: vehicleType,
                decoration: InputDecoration(
                  hintText: 'Enter vehicle type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                onChanged: (value) => vehicleType = value,
              ),
              const SizedBox(height: 20),
              // Vehicle Number
              Text(
                'Vehicle Number',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: vehicleNumber,
                decoration: InputDecoration(
                  hintText: 'Enter vehicle number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                ),
                onChanged: (value) => vehicleNumber = value,
              ),
              const SizedBox(height: 20),
              // License Photo
              Text(
                'License Photo *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      licensePhotoFile = File(pickedFile.path);
                      isLicensePhotoValid = true;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          licensePhotoFile != null
                              ? ColorManager.primary
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.upload_file, color: ColorManager.primary),
                      const SizedBox(width: 14),
                      Expanded(
                                                  child: Text(
                            licensePhotoFile != null
                                ? licensePhotoFile!.path.split('/').last
                                : (widget.partner.licensePhoto != null
                                    ? 'Current: ${widget.partner.licensePhoto!.split('/').last}'
                                    : 'Select License Photo (Required)'),
                            style: TextStyle(
                              fontFamily: FontConstants.fontFamily,
                              fontSize: FontSize.s14,
                              color: Colors.grey[700],
                            ),
                          ),
                      ),
                      if (licensePhotoFile != null ||
                          widget.partner.licensePhoto != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
              if (!isLicensePhotoValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Text(
                    'This field is mandatory',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              // Vehicle Document
              Text(
                'Vehicle Document *',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      vehicleDocumentFile = File(pickedFile.path);
                      isVehicleDocValid = true;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          vehicleDocumentFile != null
                              ? ColorManager.primary
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.upload_file, color: ColorManager.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          vehicleDocumentFile != null
                              ? vehicleDocumentFile!.path.split('/').last
                              : (widget.partner.vehicleDocument != null
                                  ? 'Current: ${widget.partner.vehicleDocument!.split('/').last}'
                                  : 'Select Vehicle Document (Required)'),
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      if (vehicleDocumentFile != null ||
                          widget.partner.vehicleDocument != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
              if (!isVehicleDocValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Text(
                    'This field is mandatory',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            bool licenseValid = licensePhotoFile != null || widget.partner.licensePhoto != null;
                            bool vehicleValid = vehicleDocumentFile != null || widget.partner.vehicleDocument != null;

                            setState(() {
                              isLicensePhotoValid = licenseValid;
                              isVehicleDocValid = vehicleValid;
                            });

                            if (formKey.currentState!.validate() &&
                                licenseValid &&
                                vehicleValid) {
                              setState(() => isSubmitting = true);
                              widget.bloc.add(
                                EditDeliveryPartner(
                                  deliveryPartnerId:
                                      widget.partner.deliveryPartnerId,
                                  name: name,
                                  phone: phone,
                                  email: email,
                                  vehicleType: vehicleType,
                                  vehicleNumber: vehicleNumber,
                                  licensePhotoPath: licensePhotoFile?.path,
                                  vehicleDocumentPath:
                                      vehicleDocumentFile?.path,
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isSubmitting
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: FontSize.s16,
                              fontWeight: FontWeightManager.medium,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
