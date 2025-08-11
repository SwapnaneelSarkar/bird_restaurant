import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class DeliveryPartnerOnboardingView extends StatefulWidget {
  final String? deliveryPartnerId;
  final String? phone;
  const DeliveryPartnerOnboardingView({Key? key, this.deliveryPartnerId, this.phone}) : super(key: key);

  @override
  State<DeliveryPartnerOnboardingView> createState() => _DeliveryPartnerOnboardingViewState();
}

class _DeliveryPartnerOnboardingViewState extends State<DeliveryPartnerOnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  String? _vehicleType;
  File? _licenseFile;
  File? _vehicleDocFile;
  bool _loading = false;
  double? _latitude;
  double? _longitude;

  final List<String> _vehicleTypes = ['Bike', 'Scooter', 'Car', 'Auto', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isLicense) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLicense) {
          _licenseFile = File(picked.path);
        } else {
          _vehicleDocFile = File(picked.path);
        }
      });
    }
  }



  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.'), backgroundColor: Colors.red),
      );
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied.'), backgroundColor: Colors.red),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.'), backgroundColor: Colors.red),
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseFile == null || _vehicleDocFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload both license and vehicle documents.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fetch your current location.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    final result = await DeliveryPartnerAuthService.updateDeliveryPartnerProfile(
      deliveryPartnerId: widget.deliveryPartnerId ?? '',
      name: _nameController.text,
      email: _emailController.text,
      vehicleNumber: _vehicleNumberController.text,
      vehicleType: _vehicleType ?? '',
      latitude: _latitude!,
      longitude: _longitude!,
      licensePhoto: _licenseFile,
      vehicleDocument: _vehicleDocFile,
    );
    setState(() => _loading = false);
    if (result['success']) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.deliveryPartnerAuthSuccess, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _asteriskLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.poppins(fontSize: 15, color: ColorManager.black, fontWeight: FontWeightManager.medium),
        children: [
          TextSpan(
            text: ' *',
            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeightManager.semiBold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Onboarding', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold)),
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
                    Text('Complete your profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeightManager.semiBold, color: ColorManager.primary)),
                    SizedBox(height: h * 0.03),
                    _asteriskLabel('Name'),
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
                    _asteriskLabel('Email'),
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
                    _asteriskLabel('Vehicle Type'),
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
                        hintText: 'Select vehicle type',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Vehicle type is required' : null,
                    ),
                    SizedBox(height: h * 0.02),
                    _asteriskLabel('Vehicle Number'),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: _vehicleNumberController,
                      decoration: InputDecoration(
                        hintText: 'Enter vehicle number',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Vehicle number is required' : null,
                    ),
                    SizedBox(height: h * 0.02),
                    _asteriskLabel('License Photo'),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickFile(true),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _licenseFile != null ? ColorManager.primary : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 14),
                            Icon(Icons.upload_file, color: ColorManager.primary),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _licenseFile != null ? _licenseFile!.path.split('/').last : 'Upload License Photo',
                                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
                              ),
                            ),
                            if (_licenseFile != null)
                              Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 14),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    _asteriskLabel('Vehicle Document'),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _pickFile(false),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _vehicleDocFile != null ? ColorManager.primary : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 14),
                            Icon(Icons.upload_file, color: ColorManager.primary),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _vehicleDocFile != null ? _vehicleDocFile!.path.split('/').last : 'Upload Vehicle Document',
                                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
                              ),
                            ),
                            if (_vehicleDocFile != null)
                              Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 14),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    _asteriskLabel('Current Location'),
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
                          onPressed: _getCurrentLocation,
                          icon: Icon(Icons.my_location, color: Colors.white, size: 20),
                          label: Text('Fetch', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeightManager.semiBold)),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.04),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Submit', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold, fontSize: 17)),
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