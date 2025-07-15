import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'package:bird_restaurant/services/location_services.dart';
import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class DeliveryPartnerProfileEditView extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const DeliveryPartnerProfileEditView({Key? key, this.profile}) : super(key: key);

  @override
  State<DeliveryPartnerProfileEditView> createState() => _DeliveryPartnerProfileEditViewState();
}

class _DeliveryPartnerProfileEditViewState extends State<DeliveryPartnerProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _vehicleNumberController;
  String? _vehicleType;
  double? _latitude;
  double? _longitude;
  bool _loading = false;

  final List<String> _vehicleTypes = ['Bike', 'Scooter', 'Car', 'Auto', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile ?? {};
    _nameController = TextEditingController(text: p['name'] ?? '');
    _emailController = TextEditingController(text: p['email'] ?? '');
    _vehicleNumberController = TextEditingController(text: p['vehicle_number'] ?? '');
    _vehicleType = p['vehicle_type'] ?? _vehicleTypes.first;
    _latitude = double.tryParse(p['current_latitude']?.toString() ?? '') ?? null;
    _longitude = double.tryParse(p['current_longitude']?.toString() ?? '') ?? null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _loading = true);
    try {
      final loc = await LocationService().getCurrentPosition();
      setState(() {
        _loading = false;
        if (loc != null) {
          _latitude = loc.latitude;
          _longitude = loc.longitude;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not fetch location. Please check permissions and try again.'), backgroundColor: Colors.red),
          );
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: '
            ' [31m${e.toString()} [0m'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fetch your current location.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    final result = await DeliveryPartnerAuthService.updateDeliveryPartnerProfile(
      deliveryPartnerId: widget.profile?['delivery_partner_id'] ?? '',
      name: _nameController.text,
      email: _emailController.text,
      vehicleNumber: _vehicleNumberController.text,
      vehicleType: _vehicleType ?? '',
      latitude: _latitude!,
      longitude: _longitude!,
      licensePhoto: null,
      vehicleDocument: null,
    );
    setState(() => _loading = false);
    if (result['success']) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold)),
        backgroundColor: ColorManager.primary,
        elevation: 1,
      ),
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.03),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit your profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeightManager.semiBold, color: ColorManager.primary)),
                    SizedBox(height: h * 0.03),
                    Text('Name', style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    SizedBox(height: h * 0.02),
                    Text('Email', style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                    ),
                    SizedBox(height: h * 0.02),
                    Text('Vehicle Type', style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium)),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      items: _vehicleTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: GoogleFonts.poppins()),
                      )).toList(),
                      onChanged: (val) => setState(() => _vehicleType = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    Text('Vehicle Number', style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: _vehicleNumberController,
                      maxLength: 10,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter vehicle number',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vehicle number is required';
                        if (v.length != 10) return 'Vehicle number must be 10 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: h * 0.02),
                    Text('Current Location', style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: (_latitude != null && _longitude != null) ? ColorManager.primary : Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (_latitude != null && _longitude != null)
                                  ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                                  : 'Location not set',
                              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: _loading ? null : _fetchCurrentLocation,
                          icon: Icon(Icons.my_location, color: Colors.white, size: 20),
                          label: Text('Fetch', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeightManager.semiBold)),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.04),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeightManager.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 