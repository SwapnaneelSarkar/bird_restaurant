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
import '../../../services/restaurant_info_service.dart';
import '../../../models/supercategory_model.dart';

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
    
    // New event handlers for supercategory
    on<FetchSupercategoriesEvent>(_onFetchSupercategories);
    on<SupercategoryChanged>(_onSupercategoryChanged);
    
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
        supercategory: state.selectedSupercategory,
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
        supercategory: state.selectedSupercategory,
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
        supercategory: state.selectedSupercategory,
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
        supercategory: state.selectedSupercategory,
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
        supercategory: state.selectedSupercategory,
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
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        emit(state.copyWith(isLocationLoading: false));
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          emit(state.copyWith(isLocationLoading: false));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        emit(state.copyWith(isLocationLoading: false));
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('Current position: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        debugPrint('Address: $address');

        emit(state.copyWith(
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
          isLocationLoading: false,
          isFormValid: _validateForm(
            name: state.name,
            address: address,
            phoneNumber: state.phoneNumber,
            email: state.email,
            supercategory: state.selectedSupercategory,
            restaurantType: state.selectedRestaurantType,
          ),
        ));
        
        _saveData();
      } else {
        debugPrint('No address found for coordinates');
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
    
    // Validate restaurant name character limit
    if (state.name.length > 30) {
      debugPrint('Restaurant name exceeds 30 character limit: ${state.name.length} characters');
      // Don't proceed with navigation, just show validation error
      return;
    }
    
    if (state.isFormValid) {
      debugPrint('Form Data:');
      debugPrint('Name: ${state.name}');
      debugPrint('Address: ${state.address}');
      debugPrint('Phone: ${state.phoneNumber}');
      debugPrint('Email: ${state.email}');
      debugPrint('Latitude: ${state.latitude}');
      debugPrint('Longitude: ${state.longitude}');
      
      // Log supercategory data
      if (state.selectedSupercategory != null) {
        debugPrint('Supercategory: ${state.selectedSupercategory!.name} (ID: ${state.selectedSupercategory!.id})');
      } else {
        debugPrint('Supercategory: Not selected');
      }
      
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

  // New method to fetch supercategories
  Future<void> _onFetchSupercategories(
      FetchSupercategoriesEvent event, Emitter<RestaurantDetailsState> emit) async {
    emit(state.copyWith(isLoadingSupercategories: true));
    
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/supercategories');
      
      // Use existing token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        debugPrint('No token found for supercategories API call');
        emit(state.copyWith(isLoadingSupercategories: false));
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
          final List<dynamic> supercategoriesJson = responseData['data'];
          final supercategories = supercategoriesJson
              .map((json) => SupercategoryModel.fromJson(json))
              .toList();
          
          emit(state.copyWith(
            supercategories: supercategories,
            isLoadingSupercategories: false,
          ));
          
          // Load selected supercategory from shared preferences if available
          final savedSupercategoryId = prefs.getString('selected_supercategory_id');
          
          if (savedSupercategoryId != null && supercategories.isNotEmpty) {
            final savedSupercategory = supercategories.firstWhere(
              (supercategory) => supercategory.id == savedSupercategoryId,
              orElse: () => supercategories.first,
            );
            
            emit(state.copyWith(
              selectedSupercategory: savedSupercategory,
              isFormValid: _validateForm(
                name: state.name,
                address: state.address,
                phoneNumber: state.phoneNumber,
                email: state.email,
                supercategory: savedSupercategory,
                restaurantType: state.selectedRestaurantType,
              ),
            ));
          }
        } else {
          debugPrint('Failed to fetch supercategories: ${responseData['message']}');
        }
      } else {
        debugPrint('Supercategories API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching supercategories: $e');
    }
    
    emit(state.copyWith(isLoadingSupercategories: false));
  }

  // New method to handle supercategory selection
  void _onSupercategoryChanged(
      SupercategoryChanged event, Emitter<RestaurantDetailsState> emit) {
    emit(state.copyWith(
      selectedSupercategory: event.supercategory,
      isFormValid: _validateForm(
        name: state.name,
        address: state.address,
        phoneNumber: state.phoneNumber,
        email: state.email,
        supercategory: event.supercategory,
        restaurantType: state.selectedRestaurantType,
      ),
    ));
    _saveData();
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
                supercategory: state.selectedSupercategory,
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
        supercategory: state.selectedSupercategory,
        restaurantType: event.restaurantType,
      ),
    ));
    _saveData();
  }

  // Update validation function to include supercategory and restaurant type
  bool _validateForm({
    required String name,
    required String address,
    required String phoneNumber,
    required String email,
    SupercategoryModel? supercategory,
    Map<String, dynamic>? restaurantType,
  }) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    return name.isNotEmpty &&
        name.length <= 30 &&
        address.isNotEmpty &&
        email.isNotEmpty &&
        emailRegex.hasMatch(email) &&
        supercategory != null &&
        restaurantType != null;
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
    
    // Fetch supercategories and restaurant types after loading saved data
    add(FetchSupercategoriesEvent());
    add(FetchRestaurantTypesEvent());
  }

  // Update _saveData method to include supercategory and restaurant type
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('restaurant_name', state.name);
    await prefs.setString('restaurant_address', state.address);
    await prefs.setString('restaurant_phone', state.phoneNumber);
    await prefs.setString('restaurant_email', state.email);
    await prefs.setDouble('restaurant_latitude', state.latitude);
    await prefs.setDouble('restaurant_longitude', state.longitude);
    
    // Save supercategory
    if (state.selectedSupercategory != null) {
      await prefs.setString('selected_supercategory_id', state.selectedSupercategory!.id);
      await prefs.setString('selected_supercategory_name', state.selectedSupercategory!.name);
    }
    
    // Save restaurant type
    if (state.selectedRestaurantType != null) {
      await prefs.setInt('restaurant_type_id', state.selectedRestaurantType!['id']);
      await prefs.setString('restaurant_type_name', state.selectedRestaurantType!['name']);
    }
    
    // Update restaurant info service cache
    RestaurantInfoService.updateRestaurantInfo(
      name: state.name,
      slogan: state.address,
    );
    
    debugPrint('Saved restaurant data to SharedPreferences');
    debugPrint('Latitude: ${state.latitude}, Longitude: ${state.longitude}');
  }
}