// lib/ui_components/country_picker.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/country.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class CountryPickerBottomSheet extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onCountrySelected;

  const CountryPickerBottomSheet({
    Key? key,
    required this.selectedCountry,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  State<CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  String searchQuery = '';
  List<Country> filteredCountries = CountryData.countries;

  @override
  void initState() {
    super.initState();
    filteredCountries = CountryData.countries;
  }

  void _filterCountries(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCountries = CountryData.countries;
      } else {
        filteredCountries = CountryData.countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()) ||
                country.dialCode.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Container(
      height: h * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: w * 0.15,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: h * 0.015),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Text(
              'Select Country',
              style: GoogleFonts.poppins(
                fontSize: FontSize.s20,
                fontWeight: FontWeightManager.semiBold,
                color: ColorManager.textWhite,
              ),
            ),
          ),
          
          SizedBox(height: h * 0.02),
          
          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: h * 0.06,
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
                        Icons.search,
                        color: Colors.white.withOpacity(0.6),
                        size: h * 0.03,
                      ),
                      SizedBox(width: w * 0.02),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.poppins(
                            color: ColorManager.textWhite,
                            fontSize: FontSize.s14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search country or code...',
                            hintStyle: GoogleFonts.poppins(
                              color: ColorManager.textWhite.withOpacity(0.6),
                              fontSize: FontSize.s14,
                            ),
                          ),
                          onChanged: _filterCountries,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: h * 0.02),
          
          // Countries list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;
                
                return GestureDetector(
                  onTap: () {
                    widget.onCountrySelected(country);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: h * 0.01),
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: h * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Flag
                        Text(
                          country.flag,
                          style: TextStyle(fontSize: FontSize.s20),
                        ),
                        
                        SizedBox(width: w * 0.03),
                        
                        // Country name
                        Expanded(
                          child: Text(
                            country.name,
                            style: GoogleFonts.poppins(
                              fontSize: FontSize.s16,
                              fontWeight: isSelected 
                                  ? FontWeightManager.semiBold
                                  : FontWeightManager.regular,
                              color: ColorManager.textWhite,
                            ),
                          ),
                        ),
                        
                        // Dial code
                        Text(
                          country.dialCode,
                          style: GoogleFonts.poppins(
                            fontSize: FontSize.s16,
                            fontWeight: FontWeightManager.medium,
                            color: ColorManager.textWhite.withOpacity(0.8),
                          ),
                        ),
                        
                        if (isSelected) ...[
                          SizedBox(width: w * 0.02),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: h * 0.025,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}