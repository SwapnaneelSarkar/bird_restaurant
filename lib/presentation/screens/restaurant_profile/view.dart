import 'dart:io';
import 'package:bird_restaurant/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/token_service.dart';
import '../../../ui_components/custom_button_locatin.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/operations_card.dart';
import '../../../ui_components/profile_button.dart';
import '../address bottomSheet/view.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

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

  // We'll store address info from the location picker
  String _selectedAddress = '';
  
  @override
  void initState() {
    super.initState();
    _ownerNameCtrl   = TextEditingController();
    _ownerMobileCtrl = TextEditingController();
    _ownerEmailCtrl  = TextEditingController();
    _ownerAddressCtrl= TextEditingController();
    _restNameCtrl    = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _cookTimeCtrl    = TextEditingController();
    
    // Load mobile number from shared preferences
    _loadMobileNumber();
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
      final fullAddress = subAddress.isNotEmpty 
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
    final picked =
        await showTimePicker(context: context, initialTime: initial);
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
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantProfileBloc>();
    final mq   = MediaQuery.of(context);
    final w    = mq.size.width;
    final h    = mq.size.height;
    final side = w * 0.04;
    final vert = h * 0.02;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Restaurant Profile',
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s18,
            fontWeight: FontWeightManager.semiBold,
            color: ColorManager.black,
          ),
        ),
      ),
      body: BlocConsumer<RestaurantProfileBloc, RestaurantProfileState>(
        listenWhen: (previous, current) {
          // Only update when certain state parts change to avoid excessive rebuilds
          return previous.ownerName != current.ownerName ||
                 previous.ownerMobile != current.ownerMobile ||
                 previous.ownerEmail != current.ownerEmail ||
                 previous.ownerAddress != current.ownerAddress ||
                 previous.restaurantName != current.restaurantName ||
                 previous.description != current.description ||
                 previous.cookingTime != current.cookingTime ||
                 previous.latitude != current.latitude ||
                 previous.longitude != current.longitude ||
                 previous.submissionMessage != current.submissionMessage ||
                 previous.errorMessage != current.errorMessage;
        },
        listener: (context, state) {
          // Update text fields when state changes
          _updateTextFields(state);
          
          // Show success/error messages
          if (state.submissionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.submissionMessage!),
                backgroundColor: state.submissionSuccess == true 
                    ? Colors.green 
                    : Colors.red,
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
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
                  padding: EdgeInsets.symmetric(horizontal: side, vertical: vert),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Image
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
                              onTap: () => bloc.add(SelectImagePressed()),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFCB56E),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.photo, color: Colors.white),
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
                      ),
                      SizedBox(height: vert * .8),
                      CustomTextField(
                        controller: _ownerMobileCtrl,
                        label: 'Mobile Number',
                        hintText: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => bloc.add(OwnerMobileChanged(v)),
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
                                border: Border.all(color: Colors.grey.shade300),
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

                      _sectionHeader('Restaurant Details', Icons.restaurant_menu_outlined),
                      SizedBox(height: vert * 0.5),

                      CustomTextField(
                        controller: _restNameCtrl,
                        label: 'Restaurant Name',
                        hintText: 'Enter restaurant name',
                        onChanged: (v) => bloc.add(RestaurantNameChanged(v)),
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
                      CustomTextField(
                        controller: _cookTimeCtrl,
                        label: 'Average Cooking Time (minutes)',
                        hintText: 'Enter cooking time',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => bloc.add(CookingTimeChanged(v)),
                      ),
                      SizedBox(height: vert * 1.2),

                      _sectionHeader('Restaurant Type', Icons.restaurant_outlined),
                      Row(
                        children: [
                          _typeChip(
                            ctx: context,
                            label: 'Vegetarian',
                            selected: st.type == RestaurantType.veg,
                            onTap: () => bloc.add(const TypeChanged(RestaurantType.veg)),
                          ),
                          const SizedBox(width: 12),
                          _typeChip(
                            ctx: context,
                            label: 'Non-Vegetarian',
                            selected: st.type == RestaurantType.nonVeg,
                            onTap: () => bloc.add(const TypeChanged(RestaurantType.nonVeg)),
                          ),
                        ],
                      ),
                      SizedBox(height: vert * 1.2),

                      _sectionHeader('Working Hours', Icons.access_time_outlined),
                      for (int i = 0; i < st.hours.length; i++) ...[
                        OperationalHourCard(
                          index: i,
                          day: st.hours[i],
                          onToggleEnabled: () => bloc.add(ToggleDayEnabledEvent(i)),
                          onPickStart: () => _pickTime(
                            context,
                            st.hours[i].start,
                            (t) => bloc.add(UpdateStartTimeEvent(i, t)),
                          ),
                          onPickEnd: () => _pickTime(
                            context,
                            st.hours[i].end,
                            (t) => bloc.add(UpdateEndTimeEvent(i, t)),
                          ),
                        ),
                        SizedBox(height: vert * .1),
                      ],
                      SizedBox(height: vert * 1),

                      ProfileButton(
                        label: st.isSubmitting ? 'Updating...' : 'Update Profile',
                        icon: Icons.save_outlined,
                        style: ProfileButtonStyle.filled,
                        onPressed: st.isValid && !st.isSubmitting
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
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (st.isSubmitting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantImage(RestaurantProfileState state) {
    // Local file takes precedence over remote URL
    if (state.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(state.imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } 
    // If we have a URL from the API, display network image
    else if (state.restaurantImageUrl != null && state.restaurantImageUrl!.isNotEmpty) {
      // Construct the full URL (adjust based on your API URL structure)
      String fullUrl = state.restaurantImageUrl!;
      if (!fullUrl.startsWith('http')) {
        // If it's a relative path, append to base URL
        fullUrl = '${ApiConstants.baseUrl}/${state.restaurantImageUrl!}';
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
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
                value: loadingProgress.expectedTotalBytes != null
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
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: (MediaQuery.of(ctx).size.width - 48) / 2,
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1.2,
            ),
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
                    color: selected
                        ? ColorManager.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
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
}