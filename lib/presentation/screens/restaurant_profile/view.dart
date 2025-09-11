import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/token_service.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
import '../../../ui_components/image_cropper_widget.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../constants/api_constants.dart';
import '../../../ui_components/custom_button_locatin.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/operations_card.dart';
import '../../../ui_components/profile_button.dart';
import '../address bottomSheet/view.dart';
// Remove this import
import '../homePage/sidebar/sidebar_drawer.dart';

import '../../../constants/enums.dart';
import '../../../ui_components/cuisine_card.dart';
import '../../../ui_components/cuisine_grid.dart';
import '../../../models/cuisine_model.dart';
import '../../../services/cuisine_service.dart';
import '../../../ui_components/country_picker.dart';
import '../../../ui_components/radius_map_widget.dart';

class RestaurantProfileView extends StatelessWidget {
  const RestaurantProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantProfileBloc(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _ownerMobileCtrl;
  late final TextEditingController _ownerEmailCtrl;
  late final TextEditingController _ownerAddressCtrl;
  late final TextEditingController _restNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _cookTimeCtrl;
  late final TextEditingController
  _deliveryRadiusCtrl; // 👈 NEW CONTROLLER ADDED
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // We'll store address info from the location picker
  String _selectedAddress = '';

  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  late Future<List<Cuisine>> _cuisinesFuture;

  @override
  void initState() {
    super.initState();
    _ownerNameCtrl = TextEditingController();
    _ownerMobileCtrl = TextEditingController();
    _ownerEmailCtrl = TextEditingController();
    _ownerAddressCtrl = TextEditingController();
    _restNameCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _cookTimeCtrl = TextEditingController();
    _deliveryRadiusCtrl =
        TextEditingController(); // 👈 NEW CONTROLLER INITIALIZED

    // Load mobile number from shared preferences
    _loadMobileNumber();

    // Load restaurant info
    _loadRestaurantInfo();

    _cuisinesFuture = CuisineService.fetchCuisines();
    
    // Check location permission and auto-detect country after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<RestaurantProfileBloc>();
      bloc.add(CheckLocationPermissionEvent());
      // Clear any existing error messages when page is loaded
      bloc.add(ClearSubmissionMessage());
    });
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      // Force refresh from API to get the latest restaurant info
      final info = await RestaurantInfoService.refreshRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
        });
        debugPrint(
          '🔄 RestaurantProfilePage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}',
        );
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  Future<void> _loadMobileNumber() async {
    final mobile = await TokenService.getMobile();
    if (mobile != null && mobile.isNotEmpty) {
      if (mounted) {
        setState(() {
          _ownerMobileCtrl.text = mobile;
        });

        // Update the bloc state
        context.read<RestaurantProfileBloc>().add(OwnerMobileChanged(mobile));
      }
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerMobileCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerAddressCtrl.dispose();
    _restNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _cookTimeCtrl.dispose();
    _deliveryRadiusCtrl.dispose(); // 👈 NEW CONTROLLER DISPOSED
    super.dispose();
  }

  // Method to open the location picker
  Future<void> _openLocationPicker() async {
    final result = await AddressPickerBottomSheet.show(context);

    if (result != null) {
      final address = result['address'];
      final subAddress = result['subAddress'];
      final latitude = result['latitude'];
      final longitude = result['longitude'];

      // Update the full address
      final fullAddress =
          subAddress != null && subAddress.toString().isNotEmpty
              ? '$address, $subAddress'
              : address;

      // Update the owner address field
      setState(() {
        _ownerAddressCtrl.text = fullAddress;
        _selectedAddress = fullAddress;
      });

      // Update the bloc state with all values
      final bloc = context.read<RestaurantProfileBloc>();
      bloc.add(OwnerAddressChanged(fullAddress));
      bloc.add(LatitudeChanged(latitude.toString()));
      bloc.add(LongitudeChanged(longitude.toString()));

      debugPrint('Location selected:');
      debugPrint('Address: $fullAddress');
      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onSelected,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onSelected(picked);
  }

  // Update text fields when state changes
  void _updateTextFields(RestaurantProfileState state) {
    // Only update controllers if the values are different to avoid cursor jump
    if (_ownerNameCtrl.text != state.ownerName) {
      _ownerNameCtrl.text = state.ownerName;
    }
    if (_ownerMobileCtrl.text != state.ownerMobile) {
      _ownerMobileCtrl.text = state.ownerMobile;
    }
    if (_ownerEmailCtrl.text != state.ownerEmail) {
      _ownerEmailCtrl.text = state.ownerEmail;
    }
    if (_ownerAddressCtrl.text != state.ownerAddress) {
      _ownerAddressCtrl.text = state.ownerAddress;
      _selectedAddress = state.ownerAddress;
    }
    if (_restNameCtrl.text != state.restaurantName) {
      _restNameCtrl.text = state.restaurantName;
    }
    if (_descriptionCtrl.text != state.description) {
      _descriptionCtrl.text = state.description;
    }
    if (_cookTimeCtrl.text != state.cookingTime) {
      _cookTimeCtrl.text = state.cookingTime;
    }
    // 👈 NEW CONTROLLER UPDATE ADDED
    if (_deliveryRadiusCtrl.text != state.deliveryRadius) {
      _deliveryRadiusCtrl.text = state.deliveryRadius;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantProfileBloc>();
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final side = w * 0.04;
    final vert = h * 0.02;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(Routes.homePage, (route) => false);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ColorManager.background,
        drawer: SidebarDrawer(
          activePage: 'profile',
          restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
          restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Manage your profile',
          restaurantImageUrl: _restaurantInfo?['imageUrl'],
        ),
        appBar: AppBar(
          leading: null,
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
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
              Text(
                'Store Profile',
                style: TextStyle(
                  fontFamily: FontConstants.fontFamily,
                  fontSize: FontSize.s18,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
        ),
        body: BlocConsumer<RestaurantProfileBloc, RestaurantProfileState>(
          listenWhen: (previous, current) {
            return previous.isSubmitting && !current.isSubmitting;
          },
          listener: (context, state) {
            _updateTextFields(state);

            if (state.submissionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.submissionMessage!),
                  backgroundColor:
                      state.submissionSuccess == true
                          ? Colors.green
                          : Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );

              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted) {
                  context.read<RestaurantProfileBloc>().add(
                    ClearSubmissionMessage(),
                  );
                }
              });
            }

            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, st) {
            // Update text fields with current state values
            _updateTextFields(st);

            return SafeArea(
              child: Stack(
                children: [
                  // Main content
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: side,
                      vertical: vert,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Image
                        Stack(
                          children: [
                            Container(
                              height: w * 0.5,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildRestaurantImage(st),
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: InkWell(
                                onTap: () => _showImagePicker(context, bloc),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFCB56E),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.photo,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vert),

                        _sectionHeader('Owner Details', Icons.person_outline),
                        SizedBox(height: vert * 0.5),

                        CustomTextField(
                          controller: _ownerNameCtrl,
                          label: 'Owner Name',
                          hintText: 'Enter owner name',
                          onChanged: (v) => bloc.add(OwnerNameChanged(v)),
                          maxLength: 50,
                          errorText: st.ownerNameError,
                          counterText: '${_ownerNameCtrl.text.length}/50',
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[0-9]')), // Deny numbers
                            LengthLimitingTextInputFormatter(50), // Limit to 50 characters
                          ],
                        ),
                        SizedBox(height: vert * .8),
                        // Phone Number with OTP Verification
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Debug info (remove in production)
                            if (kDebugMode)
                              Container(
                                padding: EdgeInsets.all(4),
                                margin: EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DEBUG: isPhoneVerified=${st.isPhoneVerified}, hasLocationPermission=${st.hasLocationPermission}, fieldEnabled=${!st.isPhoneVerified && st.hasLocationPermission}, ownerMobile="${st.ownerMobile}"',
                                  style: TextStyle(fontSize: 10, color: Colors.black87),
                                ),
                              ),
                            Text(
                              'Mobile Number',
                              style: TextStyle(
                                fontFamily: FontConstants.fontFamily,
                                fontSize: FontSize.s14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 6),
                                                        // Combined Phone Number Field with Country Code
                                                        Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ColorManager.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Country Code Display with Picker (Always clickable)
                                  GestureDetector(
                                    onTap: () => _showCountryPicker(context),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: ColorManager.grey,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            st.selectedCountry.flag,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            st.selectedCountry.dialCode,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeightManager.medium,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Phone Number Input
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Tooltip(
                                        message: st.isPhoneVerified 
                                            ? 'Phone number is verified. You can now edit it.' 
                                            : 'Verify your phone number first to edit it',
                                        child: TextField(
                                          controller: _ownerMobileCtrl,
                                          enabled: st.isPhoneVerified, // Only enable if phone is verified
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          style: TextStyle(
                                            fontSize: FontSize.s14,
                                            fontWeight: FontWeightManager.regular,
                                            color: ColorManager.black,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: st.isPhoneVerified 
                                                ? 'Phone number verified - click to edit' 
                                                : 'Verify your phone number first',
                                            hintStyle: TextStyle(
                                              fontSize: FontSize.s14,
                                              fontWeight: FontWeightManager.regular,
                                              color: ColorManager.textGrey,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (v) {
                                            bloc.add(OwnerMobileChanged(v));
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            // Verify Button - Only show if not verified
                            if (!st.isPhoneVerified) ...[
                              ElevatedButton.icon(
                                onPressed: st.isPhoneVerificationInProgress || st.ownerMobile.isEmpty || !st.hasLocationPermission
                                    ? null 
                                    : () => bloc.add(InitializePhoneOtpEvent(st.ownerMobile)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorManager.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: st.isPhoneVerificationInProgress
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.verified_user, size: 16, color: Colors.white),
                                label: Text(
                                  'Verify Number',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeightManager.medium,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeightManager.medium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Location Permission Warning
                            if (!st.hasLocationPermission) ...[
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Location access is required to verify your phone number. This helps us detect your country and ensure proper formatting.',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (st.phoneVerificationError != null) ...[
                              SizedBox(height: 4),
                              Text(
                                st.phoneVerificationError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            // OTP Input Section
                            if (st.phoneVerificationId != null && !st.isPhoneVerified) ...[
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enter OTP sent to ${st.selectedCountry.dialCode}${st.ownerMobile}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeightManager.medium,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: List.generate(6, (index) {
                                        return Expanded(
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: 2),
                                            child: TextField(
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              maxLength: 1,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeightManager.bold,
                                              ),
                                              decoration: InputDecoration(
                                                counterText: '',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              onChanged: (value) {
                                                bloc.add(PhoneOtpDigitChanged(index, value));
                                                if (value.isNotEmpty && index < 5) {
                                                  FocusScope.of(context).nextFocus();
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: st.isPhoneVerificationInProgress
                                                ? null
                                                : () => bloc.add(const SubmitPhoneOtpEvent()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: ColorManager.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: st.isPhoneVerificationInProgress
                                                ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    'Verify OTP',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeightManager.medium,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        if (st.phoneOtpTimer > 0) ...[
                                          Text(
                                            'Resend in ${st.phoneOtpTimer}s',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ] else ...[
                                          TextButton(
                                            onPressed: st.isPhoneVerificationInProgress
                                                ? null
                                                : () => bloc.add(const ResendPhoneOtpEvent()),
                                            child: Text(
                                              'Resend OTP',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ColorManager.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: vert * .8),
                        CustomTextField(
                          controller: _ownerEmailCtrl,
                          label: 'Email',
                          hintText: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => bloc.add(OwnerEmailChanged(v)),
                        ),
                        SizedBox(height: vert * .8),

                        // Location picker button and address display
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address',
                              style: TextStyle(
                                fontFamily: FontConstants.fontFamily,
                                fontSize: FontSize.s14,
                                fontWeight: FontWeightManager.medium,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            CustomButtonSlim(
                              label: 'Select Location',
                              suffixIcon: Icons.location_on_outlined,
                              onPressed: _openLocationPicker,
                            ),
                            SizedBox(height: 8),
                            if (_selectedAddress.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    fontSize: FontSize.s14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: vert * 1.2),

                        _sectionHeader(
                          'Restaurant Details',
                          Icons.restaurant_menu_outlined,
                        ),
                        SizedBox(height: vert * 0.5),

                        CustomTextField(
                          controller: _restNameCtrl,
                          label: 'Store Name',
                          hintText: 'Enter store name (max 30 characters)',
                          maxLength: 30,
                          counterText: '${st.restaurantName.length}/30',
                          errorText: st.restaurantNameError,
                          onChanged: (v) {
                            // Capitalize first letter of each word
                            final capitalized = v.split(' ').map((word) {
                              if (word.isEmpty) return word;
                              return word[0].toUpperCase() + word.substring(1).toLowerCase();
                            }).join(' ');
                            bloc.add(RestaurantNameChanged(capitalized));
                          },
                        ),
                        // Real-time character counter
                        SizedBox(height: vert * 0.3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Characters: ${st.restaurantName.length}',
                              style: TextStyle(
                                fontSize: FontSize.s12,
                                color: st.restaurantName.length >= 30 
                                    ? Colors.red.shade600 
                                    : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${st.restaurantName.length}/30',
                              style: TextStyle(
                                fontSize: FontSize.s12,
                                color: st.restaurantName.length >= 30 
                                    ? Colors.red.shade600 
                                    : Colors.grey.shade600,
                                fontWeight: FontWeightManager.medium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vert * .8),
                        CustomTextField(
                          controller: _descriptionCtrl,
                          label: 'Description',
                          hintText: 'Enter restaurant description',
                          maxLines: 3,
                          onChanged: (v) => bloc.add(DescriptionChanged(v)),
                        ),
                        SizedBox(height: vert * .8),
                        
                        // Only show cooking time for food supercategory
                        if (st.isFoodSupercategory) ...[
                        CustomTextField(
                          controller: _cookTimeCtrl,
                          label: 'Average Cooking Time (minutes)',
                            hintText: 'Enter cooking time (limited to 2 digits, max 99)',
                          keyboardType: TextInputType.number,
                            maxLength: 2,
                            counterText: '${_cookTimeCtrl.text.length}/2',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            onChanged: (v) {
                              // Ensure value is within 1-99 range
                              final intValue = int.tryParse(v);
                              if (intValue != null && intValue > 99) {
                                _cookTimeCtrl.text = '99';
                                _cookTimeCtrl.selection = TextSelection.fromPosition(
                                  TextPosition(offset: 2),
                                );
                                bloc.add(CookingTimeChanged('99'));
                              } else {
                                bloc.add(CookingTimeChanged(v));
                              }
                            },
                        ),
                        SizedBox(height: vert * .8),
                        ],

                        // 👈 NEW DELIVERY RADIUS MAP WIDGET ADDED
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Radius',
                              style: TextStyle(
                                fontFamily: FontConstants.fontFamily,
                                fontSize: FontSize.s14,
                                fontWeight: FontWeightManager.medium,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Set your delivery area by adjusting the radius on the map below',
                              style: TextStyle(
                                fontFamily: FontConstants.fontFamily,
                                fontSize: FontSize.s12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 12),
                            RadiusMapWidget(
                              initialRadius: double.tryParse(st.deliveryRadius) ?? 5.0,
                              initialLatitude: double.tryParse(st.latitude) ?? 28.6139, // Default to Delhi
                              initialLongitude: double.tryParse(st.longitude) ?? 77.2090,
                              onRadiusChanged: (radius, latitude, longitude) {
                                bloc.add(DeliveryRadiusChanged(radius.toStringAsFixed(1)));
                                bloc.add(LatitudeChanged(latitude.toString()));
                                bloc.add(LongitudeChanged(longitude.toString()));
                              },
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Current radius: ${st.deliveryRadius} km • Move the map to adjust your restaurant location',
                                      style: TextStyle(
                                        fontSize: FontSize.s12,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: vert * 1.2),

                        // Only show store type for food supercategory
                        if (st.isFoodSupercategory) ...[
                        _sectionHeader('Store Type', Icons.store_outlined),
                        Row(
                          children: [
                            _typeChip(
                              ctx: context,
                              label: 'Vegetarian',
                              selected: st.type == RestaurantType.veg,
                              onTap:
                                  () => bloc.add(
                                    const TypeChanged(RestaurantType.veg),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            _typeChip(
                              ctx: context,
                              label: 'Non-Vegetarian',
                              selected: st.type == RestaurantType.nonVeg,
                              onTap:
                                  () => bloc.add(
                                    const TypeChanged(RestaurantType.nonVeg),
                                  ),
                            ),
                          ],
                        ),
                        ],

                        // Store Type Dropdown - NEW SECTION
                        // Only show kitchen type for food supercategory
                        if (st.isFoodSupercategory) ...[
                        SizedBox(height: vert * 1.2),
                        _sectionHeader('Kitchen Type', Icons.store_outlined),
                        SizedBox(height: vert * 0.5),

                        BlocBuilder<
                          RestaurantProfileBloc,
                          RestaurantProfileState
                        >(
                          buildWhen:
                              (previous, current) =>
                                  previous.restaurantTypes !=
                                      current.restaurantTypes ||
                                  previous.selectedRestaurantType !=
                                      current.selectedRestaurantType ||
                                  previous.isLoadingRestaurantTypes !=
                                      current.isLoadingRestaurantTypes,
                          builder: (context, state) {
                            if (state.isLoadingRestaurantTypes) {
                              return Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorManager.primary,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (state.restaurantTypes.isEmpty) {
                              return Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  'No store types available',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: FontSize.s14,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Map<String, dynamic>>(
                                  isExpanded: true,
                                  value: state.selectedRestaurantType,
                                  hint: Text(
                                    'Select store type',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: FontSize.s14,
                                    ),
                                  ),
                                  items:
                                      state.restaurantTypes.map<
                                        DropdownMenuItem<Map<String, dynamic>>
                                      >((Map<String, dynamic> type) {
                                        return DropdownMenuItem<
                                          Map<String, dynamic>
                                        >(
                                          value: type,
                                          child: Text(
                                            type['name'],
                                            style: TextStyle(
                                              fontSize: FontSize.s14,
                                              color: ColorManager.black,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (
                                    Map<String, dynamic>? selectedType,
                                  ) {
                                    if (selectedType != null) {
                                      context.read<RestaurantProfileBloc>().add(
                                        RestaurantTypeChanged(selectedType),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        ],
                        SizedBox(height: vert * 1.2),

                        // Only show cuisine types for food supercategory
                        if (st.isFoodSupercategory) ...[
                        _sectionHeader('Cuisine Types', Icons.fastfood),
                        SizedBox(height: vert * 0.5),
                        FutureBuilder<List<Cuisine>>(
                          future: _cuisinesFuture,
                          builder: (context, snapshot) {
                            final cuisines = snapshot.data ?? const <Cuisine>[];
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (cuisines.isNotEmpty) {
                              return CuisineGrid(
                                width: w,
                                height: h,
                                cuisines: cuisines,
                                selected: st.selectedCuisines.toSet(),
                                onTap: (ct) => bloc.add(ToggleCuisineType(ct)),
                              );
                            }
                            return GridView.count(
                              crossAxisCount: (w > 600) ? 4 : 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: h * 0.015,
                              crossAxisSpacing: w * 0.03,
                              childAspectRatio: 1,
                              children: [
                                for (final ct in CuisineType.values)
                                  CuisineCard(
                                    cuisine: ct,
                                    selected: st.selectedCuisines.contains(ct),
                                    onTap: () => bloc.add(ToggleCuisineType(ct)),
                                  ),
                              ],
                            );
                          },
                        ),
                        ],
                        SizedBox(height: vert * 1.2),

                        _sectionHeader(
                          'Working Hours',
                          Icons.access_time_outlined,
                        ),
                        for (int i = 0; i < st.hours.length; i++) ...[
                          OperationalHourCard(
                            index: i,
                            day: st.hours[i],
                            onToggleEnabled:
                                () => bloc.add(ToggleDayEnabledEvent(i)),
                            onPickStart:
                                () => _pickTime(
                                  context,
                                  st.hours[i].start,
                                  (t) => bloc.add(UpdateStartTimeEvent(i, t)),
                                ),
                            onPickEnd:
                                () => _pickTime(
                                  context,
                                  st.hours[i].end,
                                  (t) => bloc.add(UpdateEndTimeEvent(i, t)),
                                ),
                          ),
                          SizedBox(height: vert * .1),
                        ],
                        SizedBox(height: vert * 1),

                        ProfileButton(
                          label:
                              st.isSubmitting
                                  ? 'Updating...'
                                  : 'Update Profile',
                          icon: Icons.save_outlined,
                          style: ProfileButtonStyle.filled,
                          onPressed:
                              st.isValid && !st.isSubmitting
                                  ? () => bloc.add(const UpdateProfilePressed())
                                  : null,
                        ),
                        SizedBox(height: vert),
                      ],
                    ),
                  ),

                  // Overlays
                  if (st.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (st.isSubmitting)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRestaurantImage(RestaurantProfileState state) {
    // Local file takes precedence over remote URL
    if (state.imagePath != null) {
      debugPrint('🖼️ Displaying local image: ${state.imagePath}');
      final File imageFile = File(state.imagePath!);
      final bool fileExists = imageFile.existsSync();
      debugPrint('🖼️ Image file exists: $fileExists');
      if (fileExists) {
        final int fileSize = imageFile.lengthSync();
        debugPrint('🖼️ Image file size: $fileSize bytes');
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(state.imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error loading local image: $error');
            debugPrint('❌ Image path: ${state.imagePath}');
            return Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red,
            );
          },
        ),
      );
    }
    // If we have a URL from the API, display network image
    else if (state.restaurantImageUrl != null &&
        state.restaurantImageUrl!.isNotEmpty) {
      // Clean and construct the image URL
      String cleanUrl = state.restaurantImageUrl!;

      // Remove malformed prefix if present
      if (cleanUrl.contains('https://api.bird.delivery/api/%5B%22')) {
        cleanUrl = cleanUrl.replaceAll(
          'https://api.bird.delivery/api/%5B%22',
          '',
        );
      }

      // Remove trailing encoded characters
      if (cleanUrl.contains('%22%5D')) {
        cleanUrl = cleanUrl.replaceAll('%22%5D', '');
      }

      // URL decode any remaining encoded characters
      cleanUrl = Uri.decodeFull(cleanUrl);

      // If it's already a full URL (starts with http), use it as is
      // Otherwise, check if we need to add base URL
      String fullUrl = cleanUrl;
      if (!cleanUrl.startsWith('http')) {
        fullUrl = '${ApiConstants.baseUrl}/$cleanUrl';
      }

      debugPrint('Using cleaned image URL: $fullUrl');

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
            debugPrint('Failed URL: $fullUrl');
            // Fallback to placeholder on error
            return Icon(
              Icons.add_photo_alternate_outlined,
              size: 72,
              color: ColorManager.textGrey,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
        ),
      );
    }
    // Default placeholder
    else {
      return Icon(
        Icons.add_photo_alternate_outlined,
        size: 72,
        color: ColorManager.textGrey,
      );
    }
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    ),
  );

  Widget _typeChip({
    required BuildContext ctx,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: (MediaQuery.of(ctx).size.width - 48) / 2,
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? ColorManager.primary : Colors.grey.shade400,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child:
                selected
                    ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorManager.primary,
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.medium,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _openSidebar() {
    // Use the scaffold's built-in drawer instead of pushing a new route
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showImagePicker(
    BuildContext context,
    RestaurantProfileBloc bloc,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Navigate to crop screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ImageCropperWidget(
                imagePath: image.path,
                aspectRatio:
                    16.0 /
                    9.0, // Restaurant images typically use 16:9 aspect ratio
                onCropComplete: (File croppedFile) {
                  // Update the state with the cropped image path
                  bloc.add(ImageCropped(croppedFile.path));
                  Navigator.pop(context);
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
        ),
      );
    }
  }

  void _showCountryPicker(BuildContext context) {
    final restaurantProfileBloc = context.read<RestaurantProfileBloc>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => CountryPickerBottomSheet(
        selectedCountry: restaurantProfileBloc.state.selectedCountry,
        onCountrySelected: (country) {
          restaurantProfileBloc.add(CountryChanged(country));
        },
      ),
    );
  }
  
}
