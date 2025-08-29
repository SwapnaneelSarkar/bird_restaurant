import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/food_type_model.dart';
import '../../../models/supercategory_model.dart';

import '../../../ui_components/custom_button_locatin.dart';
import '../../../ui_components/custom_button_slim.dart';
import '../../../ui_components/custom_textField.dart';
import '../../../ui_components/proggress_bar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
import '../address bottomSheet/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDetailsAddView extends StatelessWidget {
  const RestaurantDetailsAddView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RestaurantDetailsBloc>(
      create: (_) => RestaurantDetailsBloc()..add(LoadSavedDataEvent()),
      child: const _RestaurantDetailsBody(),
    );
  }
}

class _RestaurantDetailsBody extends StatefulWidget {
  const _RestaurantDetailsBody();

  @override
  State<_RestaurantDetailsBody> createState() => _RestaurantDetailsBodyState();
}

class _RestaurantDetailsBodyState extends State<_RestaurantDetailsBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantDetailsBloc>();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final mq = MediaQuery.of(context);
    final sidePad = w * 0.04;
    final vertPad = h * 0.02;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 50,
        title: Text(
          'Store Details',
          style: TextStyle(
            fontFamily: FontConstants.fontFamily,
            fontSize: FontSize.s16,
            color: ColorManager.black,
            fontWeight: FontWeightManager.semiBold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: const StepProgressBar(
              currentStep: 1,
              totalSteps: 3,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<RestaurantDetailsBloc, RestaurantDetailsState>(
          listener: (context, state) {
            // Update text controllers when saved data is loaded
            if (state.isDataLoaded) {
              _nameCtrl.text = state.name;
              _addressCtrl.text = state.address;
              _phoneCtrl.text = state.phoneNumber;
              _emailCtrl.text = state.email;
            }
            
            // Update address field when location is fetched
            if (state.address.isNotEmpty && !state.isLocationLoading) {
              _addressCtrl.text = state.address;
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.02),
                Text(
                  'Basic Information',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s22,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  'Please provide your store details',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.regular,
                    color: ColorManager.black.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: h * 0.03),

                // Restaurant Name
                RichText(
                  text: TextSpan(
                    text: 'Store Name',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.black,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.01),
                CustomTextField(
                  controller: _nameCtrl,
                  hintText: 'Enter store name (max 30 characters)',
                  maxLength: 30,
                  counterText: '${_nameCtrl.text.length}/30',
                  onChanged: (v) => bloc.add(RestaurantNameChanged(v)),
                ),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isAttemptedSubmit != c.isAttemptedSubmit,
                  builder: (context, state) {
                    if (state.name.isEmpty && state.isAttemptedSubmit) {
                      return Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Store name is required',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: FontSize.s12,
                          ),
                        ),
                      );
                    } else if (state.name.length > 30 && state.isAttemptedSubmit) {
                      return Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Store name cannot exceed 30 characters',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: FontSize.s12,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                SizedBox(height: h * 0.025),

                // Complete Address
                RichText(
                  text: TextSpan(
                    text: 'Complete Address',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.black,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.01),
                CustomTextField(
                  controller: _addressCtrl,
                  hintText: 'Enter complete address',
                  maxLines: 3,
                  onChanged: (v) => bloc.add(AddressChanged(v)),
                ),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isAttemptedSubmit != c.isAttemptedSubmit,
                  builder: (context, state) {
                    return state.address.isEmpty && state.isAttemptedSubmit
                        ? Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'Address is required',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: FontSize.s12,
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),
                SizedBox(height: h * 0.01),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isLocationLoading != c.isLocationLoading,
                  builder: (ctx, st) => Column(
                    children: [
                      CustomButtonSlim(
                        label: st.isLocationLoading ? 'Locating...' : 'Use current location',
                        suffixIcon: Icons.location_on,
                        isOutline: true,
                        onPressed: st.isLocationLoading 
                            ? null 
                            : () {
                                debugPrint('Use current location button pressed!');
                                bloc.add(UseCurrentLocationPressed());
                              },
                      ),
                      SizedBox(height: h * 0.01),
                      CustomButtonSlim(
                        label: 'Select a location',
                        suffixIcon: Icons.map_outlined,
                        isOutline: true,
                        onPressed: st.isLocationLoading 
                            ? null 
                            : () => _showAddressPicker(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.03),

                // Email
                RichText(
                  text: TextSpan(
                    text: 'Email',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.black,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.01),
                CustomTextField(
                  controller: _emailCtrl,
                  hintText: 'Enter Email',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => bloc.add(EmailChanged(v)),
                ),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isAttemptedSubmit != c.isAttemptedSubmit,
                  builder: (context, state) {
                    if (state.email.isEmpty && state.isAttemptedSubmit) {
                      return Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Email is required',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: FontSize.s12,
                          ),
                        ),
                      );
                    } else if (state.email.isNotEmpty && state.isAttemptedSubmit && 
                               !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(state.email)) {
                      return Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Please enter a valid email address',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: FontSize.s12,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                
                // Supercategory - NEW SECTION
                SizedBox(height: h * 0.03),
                
                RichText(
                  text: TextSpan(
                    text: 'Store Category',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.black,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.01),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => 
                    p.supercategories != c.supercategories || 
                    p.selectedSupercategory != c.selectedSupercategory ||
                    p.isLoadingSupercategories != c.isLoadingSupercategories,
                  builder: (context, state) {
                    if (state.isLoadingSupercategories) {
                      return Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorManager.primary,
                          ),
                        ),
                      );
                    }
                    
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SupercategoryModel>(
                          isExpanded: true,
                          value: state.selectedSupercategory,
                          hint: Text(
                            'Select store category',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: FontSize.s14,
                            ),
                          ),
                          items: state.supercategories.map<DropdownMenuItem<SupercategoryModel>>(
                            (SupercategoryModel supercategory) {
                              return DropdownMenuItem<SupercategoryModel>(
                                value: supercategory,
                                child: Text(
                                  supercategory.name,
                                  style: TextStyle(
                                    fontSize: FontSize.s14,
                                    color: ColorManager.black,
                                  ),
                                ),
                              );
                            }
                          ).toList(),
                          onChanged: (SupercategoryModel? selectedSupercategory) {
                            if (selectedSupercategory != null) {
                              context.read<RestaurantDetailsBloc>().add(
                                SupercategoryChanged(selectedSupercategory),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isAttemptedSubmit != c.isAttemptedSubmit,
                  builder: (context, state) {
                    return state.selectedSupercategory == null && state.isAttemptedSubmit
                        ? Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'Store category is required',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: FontSize.s12,
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),

                // Store Type - NEW SECTION
                SizedBox(height: h * 0.03),
                
                RichText(
                  text: TextSpan(
                    text: 'Store Type',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.black,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.01),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => 
                    p.restaurantTypes != c.restaurantTypes || 
                    p.selectedRestaurantType != c.selectedRestaurantType ||
                    p.isLoadingRestaurantTypes != c.isLoadingRestaurantTypes,
                  builder: (context, state) {
                    if (state.isLoadingRestaurantTypes) {
                      return Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorManager.primary,
                          ),
                        ),
                      );
                    }
                    
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
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
                          items: state.restaurantTypes.map<DropdownMenuItem<Map<String, dynamic>>>(
                            (Map<String, dynamic> type) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: type,
                                child: Text(
                                  type['name'] as String,
                                  style: TextStyle(
                                    fontSize: FontSize.s14,
                                    color: ColorManager.black,
                                  ),
                                ),
                              );
                            }
                          ).toList(),
                          onChanged: (Map<String, dynamic>? selectedType) {
                            if (selectedType != null) {
                              context.read<RestaurantDetailsBloc>().add(
                                RestaurantTypeChanged(selectedType),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.isAttemptedSubmit != c.isAttemptedSubmit,
                  builder: (context, state) {
                    return state.selectedRestaurantType == null && state.isAttemptedSubmit
                        ? Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'Store type is required',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: FontSize.s12,
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),



                // Coordinates display for debugging (can be removed in production)
                BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
                  buildWhen: (p, c) => p.latitude != c.latitude || p.longitude != c.longitude,
                  builder: (context, state) {
                    if (state.latitude != 0.0 || state.longitude != 0.0) {
                      return Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Location coordinates saved',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: FontSize.s12,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                SizedBox(height: h * 0.12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.06,
          vertical: h * 0.03,
        ),
        child: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
          buildWhen: (previous, current) => 
            previous.isFormValid != current.isFormValid || 
            previous.isAttemptedSubmit != current.isAttemptedSubmit,
          builder: (context, state) {
            return NextButton(
              label: 'Next',
              suffixIcon: Icons.arrow_forward,
              onPressed: () {
                final bloc = context.read<RestaurantDetailsBloc>();
                bloc.add(NextPressed());
                
                // Only navigate if the form is valid
                if (state.isFormValid) {
                  Navigator.pushNamed(
                    context,
                    Routes.detailsAdd2,
                  );
                }
                // Otherwise, the UI will show validation errors
              },
            );
          },
        ),
      ),
    );
  }
  
  // Method to show the address picker
  Future<void> _showAddressPicker(BuildContext context) async {
    try {
      debugPrint('Showing address picker...');
      
      // Show address picker bottom sheet
      final result = await AddressPickerBottomSheet.show(context);
      
      if (result != null) {
        debugPrint('Address selected from picker:');
        debugPrint('Address: ${result['address']}');
        debugPrint('Sub-address: ${result['subAddress']}');
        debugPrint('Latitude: ${result['latitude']}');
        debugPrint('Longitude: ${result['longitude']}');
        
        // Format the full address
        String fullAddress = result['address'];
        if (result['subAddress'] != null && result['subAddress'].toString().isNotEmpty) {
          fullAddress += ', ${result['subAddress']}';
        }
        
        // Send event to the bloc with the selected address and coordinates
        context.read<RestaurantDetailsBloc>().add(
          LocationSelected(
            address: fullAddress,
            latitude: result['latitude'] ?? 0.0,
            longitude: result['longitude'] ?? 0.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing address picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}