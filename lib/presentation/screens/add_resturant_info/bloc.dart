import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api_constants.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDetailsBloc
    extends Bloc<RestaurantDetailsEvent, RestaurantDetailsState> {
  RestaurantDetailsBloc() : super(RestaurantDetailsState.initial()) {
    on<RestaurantNameChanged>(_onNameChanged);
    on<AddressChanged>(_onAddressChanged);
    on<PhoneNumberChanged>(_onPhoneNumberChanged);
    on<EmailChanged>(_onEmailChanged);
    on<UseCurrentLocationPressed>(_onUseCurrentLocation);
    on<LocationSelected>(_onLocationSelected);
    on<NextPressed>(_onNextPressed);
    on<LoadSavedDataEvent>(_onLoadSavedData);
    
    // New event handlers
    on<FetchRestaurantTypesEvent>(_onFetchRestaurantTypes);
    on<RestaurantTypeChanged>(_onRestaurantTypeChanged);
  }

  void _onNameChanged(
      RestaurantNameChanged event, Emitter<RestaurantDetailsState> emit) {
    final name = event.name;
    emit(state.copyWith(
      name: name,
      isFormValid: _validateForm(
        name: name,
        address: state.address,
        phoneNumber: state.phoneNumber,
        email: state.email,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    _saveData();
  }

  void _onAddressChanged(
      AddressChanged event, Emitter<RestaurantDetailsState> emit) {
    final address = event.address;
    emit(state.copyWith(
      address: address,
      isFormValid: _validateForm(
        name: state.name,
        address: address,
        phoneNumber: state.phoneNumber,
        email: state.email,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    _saveData();
  }

  void _onPhoneNumberChanged(
      PhoneNumberChanged event, Emitter<RestaurantDetailsState> emit) {
    final phone = event.phoneNumber;
    emit(state.copyWith(
      phoneNumber: phone,
      isFormValid: _validateForm(
        name: state.name,
        address: state.address,
        phoneNumber: phone,
        email: state.email,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    _saveData();
  }

  void _onEmailChanged(
      EmailChanged event, Emitter<RestaurantDetailsState> emit) {
    final email = event.email;
    emit(state.copyWith(
      email: email,
      isFormValid: _validateForm(
        name: state.name,
        address: state.address,
        phoneNumber: state.phoneNumber,
        email: email,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    _saveData();
  }
  
  // Handler for the LocationSelected event
  void _onLocationSelected(
      LocationSelected event, Emitter<RestaurantDetailsState> emit) {
    debugPrint('Location selected from picker:');
    debugPrint('Address: ${event.address}');
    debugPrint('Latitude: ${event.latitude}');
    debugPrint('Longitude: ${event.longitude}');
    
    emit(state.copyWith(
      address: event.address,
      latitude: event.latitude,
      longitude: event.longitude,
      isFormValid: _validateForm(
        name: state.name,
        address: event.address,
        phoneNumber: state.phoneNumber,
        email: state.email,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    
    _saveData();
  }

  Future<void> _onUseCurrentLocation(UseCurrentLocationPressed event,
      Emitter<RestaurantDetailsState> emit) async {
    debugPrint('Use current location pressed!');
    emit(state.copyWith(isLocationLoading: true));
    
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        emit(state.copyWith(isLocationLoading: false));
        debugPrint('Location services are disabled.');
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Requested permission: $permission');
        
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(isLocationLoading: false));
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(isLocationLoading: false));
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get current position
      debugPrint('Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('Position: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      debugPrint('Getting address from coordinates...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street ?? ''}, ${place.subLocality ?? ''}, '
            '${place.locality ?? ''}, ${place.postalCode ?? ''}, '
            '${place.administrativeArea ?? ''}, ${place.country ?? ''}';
        
        // Clean up the address by removing empty parts
        address = address.replaceAll(', , ', ', ').replaceAll(', ,', ',').trim();
        if (address.startsWith(', ')) {
          address = address.substring(2);
        }
        if (address.endsWith(', ')) {
          address = address.substring(0, address.length - 2);
        }
        
        debugPrint('Address: $address');
        
        emit(state.copyWith(
          isLocationLoading: false,
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
          isFormValid: _validateForm(
            name: state.name,
            address: address,
            phoneNumber: state.phoneNumber,
            email: state.email,
            restaurantType: state.selectedRestaurantType,
          ),
        ));
        _saveData();
      } else {
        debugPrint('No placemarks found');
        emit(state.copyWith(isLocationLoading: false));
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      emit(state.copyWith(isLocationLoading: false));
    }
  }

  void _onNextPressed(NextPressed event, Emitter<RestaurantDetailsState> emit) {
    // Set isAttemptedSubmit to true regardless of validation state
    emit(state.copyWith(isAttemptedSubmit: true));
    
    if (state.isFormValid) {
      debugPrint('Form Data:');
      debugPrint('Name: ${state.name}');
      debugPrint('Address: ${state.address}');
      debugPrint('Phone: ${state.phoneNumber}');
      debugPrint('Email: ${state.email}');
      debugPrint('Latitude: ${state.latitude}');
      debugPrint('Longitude: ${state.longitude}');
      
      // Log restaurant type data
      if (state.selectedRestaurantType != null) {
        debugPrint('Restaurant Type: ${state.selectedRestaurantType!['name']} (ID: ${state.selectedRestaurantType!['id']})');
      } else {
        debugPrint('Restaurant Type: Not selected');
      }
      
      // The navigation now happens in the UI
    } else {
      debugPrint('Form validation failed');
      // No navigation, just show error messages via the isAttemptedSubmit flag
    }
  }

  // New method to fetch restaurant types
  Future<void> _onFetchRestaurantTypes(
      FetchRestaurantTypesEvent event, Emitter<RestaurantDetailsState> emit) async {
    emit(state.copyWith(isLoadingRestaurantTypes: true));
    
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/admin/restaurantTypes');
      
      // Use existing token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        debugPrint('No token found for restaurant types API call');
        emit(state.copyWith(isLoadingRestaurantTypes: false));
        return;
      }
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final types = List<Map<String, dynamic>>.from(responseData['data']);
          
          emit(state.copyWith(
            restaurantTypes: types,
            isLoadingRestaurantTypes: false,
          ));
          
          // Load selected type from shared preferences if available
          final savedTypeId = prefs.getInt('restaurant_type_id');
          
          if (savedTypeId != null && types.isNotEmpty) {
            final savedType = types.firstWhere(
              (type) => type['id'] == savedTypeId,
              orElse: () => types.first,
            );
            
            emit(state.copyWith(
              selectedRestaurantType: savedType,
              isFormValid: _validateForm(
                name: state.name,
                address: state.address,
                phoneNumber: state.phoneNumber,
                email: state.email,
                restaurantType: savedType,
              ),
            ));
          }
        } else {
          debugPrint('Failed to fetch restaurant types: ${responseData['message']}');
        }
      } else {
        debugPrint('Restaurant types API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching restaurant types: $e');
    }
    
    emit(state.copyWith(isLoadingRestaurantTypes: false));
  }

  // New method to handle restaurant type selection
  void _onRestaurantTypeChanged(
      RestaurantTypeChanged event, Emitter<RestaurantDetailsState> emit) {
    emit(state.copyWith(
      selectedRestaurantType: event.restaurantType,
      isFormValid: _validateForm(
        name: state.name,
        address: state.address,
        phoneNumber: state.phoneNumber,
        email: state.email,
        restaurantType: event.restaurantType,
      ),
    ));
    _saveData();
  }

  // Update validation function to include restaurant type
  bool _validateForm({
    required String name,
    required String address,
    required String phoneNumber,
    required String email,
    Map<String, dynamic>? restaurantType,
  }) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    return name.isNotEmpty &&
        address.isNotEmpty &&
        email.isNotEmpty &&
        emailRegex.hasMatch(email) &&
        restaurantType != null; // Add restaurant type validation
  }

  Future<void> _onLoadSavedData(
      LoadSavedDataEvent event, Emitter<RestaurantDetailsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    
    emit(state.copyWith(
      name: prefs.getString('restaurant_name') ?? '',
      address: prefs.getString('restaurant_address') ?? '',
      phoneNumber: prefs.getString('restaurant_phone') ?? '',
      email: prefs.getString('restaurant_email') ?? '',
      latitude: prefs.getDouble('restaurant_latitude') ?? 0.0,
      longitude: prefs.getDouble('restaurant_longitude') ?? 0.0,
      isDataLoaded: true,
    ));
    
    // Fetch restaurant types after loading saved data
    add(FetchRestaurantTypesEvent());
  }

  // Update _saveData method to include restaurant type
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('restaurant_name', state.name);
    await prefs.setString('restaurant_address', state.address);
    await prefs.setString('restaurant_phone', state.phoneNumber);
    await prefs.setString('restaurant_email', state.email);
    await prefs.setDouble('restaurant_latitude', state.latitude);
    await prefs.setDouble('restaurant_longitude', state.longitude);
    
    // Save restaurant type
    if (state.selectedRestaurantType != null) {
      await prefs.setInt('restaurant_type_id', state.selectedRestaurantType!['id']);
      await prefs.setString('restaurant_type_name', state.selectedRestaurantType!['name']);
    }
    
    debugPrint('Saved restaurant data to SharedPreferences');
    debugPrint('Latitude: ${state.latitude}, Longitude: ${state.longitude}');
  }
}