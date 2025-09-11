import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../../constants/api_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../../../services/profile_update_service.dart';
import '../resturant_details_2/state.dart';
import 'event.dart';
import 'state.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../constants/enums.dart';
import '../../../utils/build_config.dart';
import '../../../models/country.dart';


class RestaurantProfileBloc
    extends Bloc<RestaurantProfileEvent, RestaurantProfileState> {
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _phoneOtpTimer;

  RestaurantProfileBloc()
      : super(
          RestaurantProfileState(
            hours: [
              const OperationalDay(label: 'Sunday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: false),
              const OperationalDay(label: 'Monday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
              const OperationalDay(label: 'Tuesday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
              const OperationalDay(label: 'Wednesday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
              const OperationalDay(label: 'Thursday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
              const OperationalDay(label: 'Friday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
              const OperationalDay(label: 'Saturday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0), enabled: true),
            ],
          ),
        ) {
    // Initial load
    on<LoadInitialData>(_onLoadInitialData);
    
    // Restaurant types
    on<LoadRestaurantTypesEvent>(_onLoadRestaurantTypes);
    on<RestaurantTypeChanged>(_onRestaurantTypeChanged);
    
    // Image selection
    on<SelectImagePressed>(_onSelectImage);
    on<ImageCropped>(_onImageCropped);
    
    // Owner fields
    on<OwnerNameChanged>((e, emit) {
      // Validate owner name
      String? errorMessage;
      final name = e.value.trim();
      
      if (name.isEmpty) {
        errorMessage = 'Owner name is required';
      } else if (name.length < 2) {
        errorMessage = 'Owner name must be at least 2 characters long';
      } else if (name.length > 50) {
        errorMessage = 'Owner name cannot exceed 50 characters';
      } else if (RegExp(r'[0-9]').hasMatch(name)) {
        errorMessage = 'Owner name cannot contain numbers';
      }
      
      emit(state.copyWith(
        ownerName: e.value,
        submissionMessage: null,
        ownerNameError: errorMessage,
        clearOwnerNameError: errorMessage == null,
      ));
    });
    on<OwnerMobileChanged>((e, emit) {
      // Prevent changes if phone is already verified
      if (state.isPhoneVerified) {
        debugPrint('⚠️ BLOC: Attempted to change verified phone number from "${state.ownerMobile}" to "${e.v}" - BLOCKED');
        return;
      }
      emit(state.copyWith(ownerMobile: e.v, submissionMessage: null, errorMessage: null));
    });
    on<OwnerEmailChanged>((e, emit) => emit(state.copyWith(ownerEmail: e.v, submissionMessage: null, errorMessage: null)));
    on<OwnerAddressChanged>((e, emit) => emit(state.copyWith(ownerAddress: e.v, submissionMessage: null, errorMessage: null)));

    // Restaurant fields
    on<RestaurantNameChanged>((e, emit) {
      // Real-time validation and character tracking
      String? errorMessage;
      final name = e.value.trim();
      
      if (name.isEmpty) {
        errorMessage = 'Restaurant name is required';
      } else if (name.length < 2) {
        errorMessage = 'Restaurant name must be at least 2 characters long';
      } else if (name.length > 30) {
        errorMessage = 'Restaurant name cannot exceed 30 characters';
      }
      // Clear error if validation passes
      
      emit(state.copyWith(
        restaurantName: e.value,
        submissionMessage: null,
        errorMessage: null,
        restaurantNameError: errorMessage,
        clearRestaurantNameError: errorMessage == null,
      ));
    });
    on<DescriptionChanged>((e, emit) => emit(state.copyWith(description: e.v, submissionMessage: null, errorMessage: null)));
    on<CookingTimeChanged>((e, emit) => emit(state.copyWith(cookingTime: e.v, submissionMessage: null, errorMessage: null)));
    on<DeliveryRadiusChanged>((e, emit) => emit(state.copyWith(deliveryRadius: e.v, submissionMessage: null, errorMessage: null)));

    // Location fields
    on<LatitudeChanged>((e, emit) => emit(state.copyWith(latitude: e.v, submissionMessage: null, errorMessage: null)));
    on<LongitudeChanged>((e, emit) => emit(state.copyWith(longitude: e.v, submissionMessage: null, errorMessage: null)));

    // Type
    on<TypeChanged>((e, emit) => emit(state.copyWith(type: e.type, submissionMessage: null, errorMessage: null)));

    // Hours
    on<ToggleDayEnabledEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(enabled: !hours[e.index].enabled);
      emit(state.copyWith(hours: hours, submissionMessage: null, errorMessage: null));
    });
    on<UpdateStartTimeEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(start: e.time);
      emit(state.copyWith(hours: hours, submissionMessage: null, errorMessage: null));
    });
    on<UpdateEndTimeEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(end: e.time);
      emit(state.copyWith(hours: hours, submissionMessage: null, errorMessage: null));
    });

    // Actions
    on<UpdateProfilePressed>(_onUpdateProfile);
    
    // Load initial data immediately
    add(LoadInitialData());
    // Load restaurant types
    add(LoadRestaurantTypesEvent());


    // Add new event
    on<ClearSubmissionMessage>((event, emit) => emit(state.copyWith(submissionMessage: null,submissionSuccess: null, errorMessage: null)));
    on<ToggleCuisineType>(_onToggleCuisineType);
    
    // Phone OTP Verification Events
    on<InitializePhoneOtpEvent>(_onInitializePhoneOtp);
    on<PhoneOtpDigitChanged>(_onPhoneOtpDigitChanged);
    on<SubmitPhoneOtpEvent>(_onSubmitPhoneOtp);
    on<ResendPhoneOtpEvent>(_onResendPhoneOtp);
    on<PhoneOtpTimerTickEvent>(_onPhoneOtpTimerTick);
    on<PhoneOtpVerificationCompleted>(_onPhoneOtpVerificationCompleted);
    on<PhoneOtpVerificationFailed>(_onPhoneOtpVerificationFailed);
    on<PhoneOtpCodeSent>(_onPhoneOtpCodeSent);
    
    // Country Detection Events
    on<AutoDetectCountryRequested>(_onAutoDetectCountryRequested);
    on<CountryChanged>(_onCountryChanged);
    
    // Location Permission Events
    on<CheckLocationPermissionEvent>(_onCheckLocationPermission);
    on<LocationPermissionGranted>(_onLocationPermissionGranted);
    on<LocationPermissionDenied>(_onLocationPermissionDenied);
  }

  Future<void> _onLoadRestaurantTypes(
    LoadRestaurantTypesEvent event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingRestaurantTypes: true));
      
      // Try to get token
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('No token available for restaurant types API call');
        emit(state.copyWith(isLoadingRestaurantTypes: false));
        return;
      }
      
      // Create request to get restaurant types
      final url = Uri.parse('${ApiConstants.baseUrl}/admin/restaurantTypes');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Restaurant Types API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> typesData = responseData['data'];
          final types = typesData.map((item) => Map<String, dynamic>.from(item)).toList();
          
          // Get any saved restaurant type from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final savedRestaurantType = prefs.getString('restaurant_type_name');
          
          // Try to find the matching restaurant type
          Map<String, dynamic>? selectedType;
          if (savedRestaurantType != null && savedRestaurantType.isNotEmpty && types.isNotEmpty) {
            try {
              selectedType = types.firstWhere(
                (type) => type['name'] == savedRestaurantType,
                orElse: () => types.first, // Return first item as fallback
              );
            } catch (e) {
              debugPrint('Error finding selected restaurant type: $e');
              if (types.isNotEmpty) {
                selectedType = types.first;
              }
            }
          } else if (types.isNotEmpty) {
            // If we have data from the API
            final restaurantType = prefs.getString('restaurant_type');
            if (restaurantType != null && restaurantType.isNotEmpty) {
              try {
                selectedType = types.firstWhere(
                  (type) => type['name'] == restaurantType,
                  orElse: () => types.first, // Return first item as fallback
                );
              } catch (e) {
                debugPrint('Error finding restaurant type: $e');
                selectedType = types.first;
              }
            } else {
              // Default to first item if nothing saved
              selectedType = types.first;
            }
          }
          
          emit(state.copyWith(
            restaurantTypes: types,
            selectedRestaurantType: selectedType,
            isLoadingRestaurantTypes: false,
          ));
          
          debugPrint('Loaded ${types.length} restaurant types');
          debugPrint('Selected restaurant type: ${selectedType?['name']}');
        } else {
          emit(state.copyWith(isLoadingRestaurantTypes: false));
          debugPrint('Failed to load restaurant types: ${responseData['message']}');
        }
      } else {
        emit(state.copyWith(isLoadingRestaurantTypes: false));
        debugPrint('Failed to load restaurant types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading restaurant types: $e');
      String errorMessage = 'Failed to load restaurant types';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to server';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid response from server';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timeout: Server took too long to respond';
      }
      
      emit(state.copyWith(
        isLoadingRestaurantTypes: false,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onRestaurantTypeChanged(
    RestaurantTypeChanged event,
    Emitter<RestaurantProfileState> emit,
  ) {
    // Update the selected restaurant type
    emit(state.copyWith(
      selectedRestaurantType: event.restaurantType,
      submissionMessage: null,
      errorMessage: null,
    ));
    debugPrint('Selected restaurant type: ${event.restaurantType['name']}');
  }

  void _onToggleCuisineType(
    ToggleCuisineType event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    final updated = List<CuisineType>.from(state.selectedCuisines);
    if (updated.contains(event.type)) {
      updated.remove(event.type);
    } else {
      updated.add(event.type);
    }
    emit(state.copyWith(
      selectedCuisines: updated,
      submissionMessage: null,
      errorMessage: null,
    ));
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_cuisines', updated.map((e) => e.toString()).toList());
  }



  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      // Get mobile number from TokenService
      final mobile = await TokenService.getMobile();
      
      if (mobile == null || mobile.isEmpty) {
        // Try getting mobile from SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        final prefsMobile = prefs.getString('mobile');
        
        if (prefsMobile != null && prefsMobile.isNotEmpty) {
          // Save to TokenService and use it
          await TokenService.saveMobile(prefsMobile);
          debugPrint('Mobile found in SharedPreferences and saved to TokenService: $prefsMobile');
          
          // Continue with the prefsMobile
          emit(state.copyWith(ownerMobile: prefsMobile));
        } else {
          emit(state.copyWith(
            isLoading: false,
            errorMessage: 'Mobile number not found. Please login again.',
          ));
          return;
        }
      } else {
        // Save mobile number to state
        emit(state.copyWith(ownerMobile: mobile));
      }
      
      // First try to get token from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        // Save token to TokenService for compatibility
        await TokenService.saveToken(token);
        debugPrint('Token found in SharedPreferences and saved to TokenService: ${token.substring(0, min(20, token.length))}...');
      } else {
        debugPrint('No token found in SharedPreferences');
      }
      
      // Try to get user ID from SharedPreferences
      final userId = prefs.getString('user_id');
      if (userId != null && userId.isNotEmpty) {
        // Save user ID to TokenService for compatibility
        await TokenService.saveUserId(userId);
        debugPrint('User ID found in SharedPreferences and saved to TokenService: $userId');
      } else {
        debugPrint('No user ID found in SharedPreferences');
      }
      
      // Fetch restaurant details - use the mobile number we found
      final mobileToUse = state.ownerMobile;
      final response = await _apiServices.getDetailsByMobile(mobileToUse);
      
      if (response.success && response.data != null) {
        final data = response.data;
        debugPrint('Received data from API: ${jsonEncode(data)}');
        
        // Parse operational hours
        List<OperationalDay> updatedHours = List<OperationalDay>.from(state.hours);
        
        // Reset all days to disabled by default
        for (var i = 0; i < updatedHours.length; i++) {
          updatedHours[i] = updatedHours[i].copyWith(enabled: false);
        }
        
        if (data['operational_hours'] != null) {
          try {
            final dynamic operationalHoursData = data['operational_hours'];
            final Map<String, dynamic> hoursJson;
            
            // Handle operational_hours which could be a JSON string or already a Map
            if (operationalHoursData is String) {
              hoursJson = jsonDecode(operationalHoursData);
            } else if (operationalHoursData is Map) {
              hoursJson = Map<String, dynamic>.from(operationalHoursData);
            } else {
              hoursJson = {};
            }
            
            debugPrint('Parsed hours JSON: $hoursJson');
            
            // Map day keys to indices
            final Map<String, int> dayIndices = {
              'sun': 0,
              'mon': 1,
              'tue': 2,
              'wed': 3,
              'thu': 4,
              'fri': 5,
              'sat': 6,
            };
            
            // Process each day in the JSON
            hoursJson.forEach((key, value) {
              final dayKey = key.toLowerCase();
              if (dayIndices.containsKey(dayKey) && value is String) {
                final index = dayIndices[dayKey]!;
                updatedHours[index] = _parseOperationalHours(updatedHours[index], value)
                    .copyWith(enabled: true); // Set day as enabled
                debugPrint('Set hours for $dayKey: $value');
              }
            });
          } catch (e) {
            debugPrint('Error parsing operational hours: $e');
          }
        }
        
        // Determine restaurant type
        RestaurantType restaurantType = RestaurantType.veg;
        if (data['veg_nonveg'] != null) {
          final String vegNonveg = data['veg_nonveg'].toString().toLowerCase();
          if (vegNonveg.contains('non') || vegNonveg == 'nonveg') {
            restaurantType = RestaurantType.nonVeg;
          }
        } else if (data['category'] != null) {
          final String category = data['category'].toString().toLowerCase();
          if (category.contains('non-veg') || 
              category.contains('non veg') ||
              category.contains('nonveg')) {
            restaurantType = RestaurantType.nonVeg;
          }
        }
        
        // Set restaurant image URL if available
        String? imageUrl;
        if (data['restaurant_photos'] != null) {
          if (data['restaurant_photos'] is List && data['restaurant_photos'].isNotEmpty) {
            imageUrl = data['restaurant_photos'][0];
          } else if (data['restaurant_photos'] is String && data['restaurant_photos'].isNotEmpty) {
            // Handle case where restaurant_photos might be a JSON string
            try {
              final decoded = jsonDecode(data['restaurant_photos']);
              if (decoded is List && decoded.isNotEmpty) {
                imageUrl = decoded[0];
              } else if (decoded is String) {
                imageUrl = decoded;
              } else {
                imageUrl = data['restaurant_photos'];
              }
            } catch (e) {
              // If it's not valid JSON, use as is
              imageUrl = data['restaurant_photos'];
            }
          }
        }
        
        // Clean up the image URL if it has the malformed prefix
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Remove malformed prefix if present
          if (imageUrl.contains('https://api.bird.delivery/api/%5B%22')) {
            imageUrl = imageUrl.replaceAll('https://api.bird.delivery/api/%5B%22', '');
          }
          // Remove trailing encoded characters
          if (imageUrl.contains('%22%5D')) {
            imageUrl = imageUrl.replaceAll('%22%5D', '');
          }
          // URL decode any remaining encoded characters
          imageUrl = Uri.decodeFull(imageUrl);
          debugPrint('Cleaned image URL: $imageUrl');
        }
        
        // Check for restaurant_type in the API response
        if (data['restaurant_type'] != null) {
          final restaurantType = data['restaurant_type'].toString();
          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('restaurant_type', restaurantType);
          debugPrint('Saved restaurant_type to SharedPreferences: $restaurantType');
        }
        
        // Load selected cuisines from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final selectedCuisineStrings = prefs.getStringList('selected_cuisines') ?? [];
        final selectedCuisines = selectedCuisineStrings
            .map((e) => CuisineType.values.firstWhere(
                  (ct) => ct.toString() == e,
                  orElse: () => CuisineType.bakery,
                ))
            .toList();
        emit(state.copyWith(selectedCuisines: selectedCuisines));
        
        // Load supercategory from SharedPreferences
        final selectedSupercategoryId = prefs.getString('selected_supercategory_id');
        final selectedSupercategoryName = prefs.getString('selected_supercategory_name');
        
        // Handle null values properly
        final latitudeStr = data['latitude']?.toString() ?? '';
        final longitudeStr = data['longitude']?.toString() ?? '';
        final cookingTimeStr = data['cooking_time']?.toString() ?? '';
        final descriptionStr = data['description']?.toString() ?? '';
        final deliveryRadiusStr = data['delivery_radius']?.toString() ?? ''; // 👈 NEW FIELD FROM API
        
        // Update state with all fetched data
        emit(state.copyWith(
          isLoading: false,
          ownerName: data['owner_name'] ?? '',
          ownerEmail: data['email'] ?? '',
          ownerAddress: data['address'] ?? '',
          restaurantName: data['restaurant_name'] ?? '',
          description: descriptionStr,
          cookingTime: cookingTimeStr,
          deliveryRadius: deliveryRadiusStr, // 👈 NEW FIELD ADDED
          latitude: latitudeStr,
          longitude: longitudeStr,
          type: restaurantType,
          hours: updatedHours,
          restaurantImageUrl: imageUrl,
          selectedSupercategoryId: selectedSupercategoryId,
          selectedSupercategoryName: selectedSupercategoryName,
        ));
        
        debugPrint('State updated with API data');
        debugPrint('Restaurant name: ${state.restaurantName}');
        debugPrint('Owner name: ${state.ownerName}');
        debugPrint('Delivery radius: ${state.deliveryRadius}'); // 👈 NEW DEBUG LOG
        debugPrint('Latitude: ${state.latitude}');
        debugPrint('Longitude: ${state.longitude}');
      } else {
        emit(state.copyWith(
          isLoading: false, 
          errorMessage: response.message ?? 'Failed to load restaurant details'
        ));
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      String errorMessage = 'Failed to load restaurant data';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to server';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid response from server';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timeout: Server took too long to respond';
      }
      
      emit(state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      ));
    }

  }

  OperationalDay _parseOperationalHours(OperationalDay day, String hoursString) {
    // Format expected: "9am - 9pm"
    try {
      final parts = hoursString.split(' - ');
      if (parts.length == 2) {
        final startTime = _parseTimeString(parts[0]);
        final endTime = _parseTimeString(parts[1]);
        
        if (startTime != null && endTime != null) {
          return day.copyWith(
            start: startTime,
            end: endTime,
            enabled: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing hours string: $e');
    }
    return day;
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    // Format expected: "9am", "9.30am", "9pm", "9.30pm"
    try {
      timeStr = timeStr.toLowerCase().trim();
      bool isPM = timeStr.contains('pm');
      
      String timeWithoutAmPm = timeStr
          .replaceAll('am', '')
          .replaceAll('pm', '')
          .trim();
      
      int hour;
      int minute = 0;
      
      // Check if time has minutes (contains a dot)
      if (timeWithoutAmPm.contains('.')) {
        final parts = timeWithoutAmPm.split('.');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      } else {
        hour = int.parse(timeWithoutAmPm);
      }
      
      // Convert to 24-hour format
      if (isPM && hour < 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time string: $e');
      return null;
    }
  }

  Future<void> _onSelectImage(
    SelectImagePressed event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // For restaurant profile, we'll just use the original image
        // The cropping will be handled by the UI if needed
        emit(state.copyWith(imagePath: image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _onImageCropped(
    ImageCropped event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    emit(state.copyWith(imagePath: event.imagePath));
  }

  Future<void> _onUpdateProfile(
    UpdateProfilePressed event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    // Add debug logs
    debugPrint('Update Profile button pressed!');
    debugPrint('Current state: isValid=${state.isValid}, isSubmitting=${state.isSubmitting}');
    debugPrint('Restaurant Name: ${state.restaurantName}');
    debugPrint('Owner Name: ${state.ownerName}');
    debugPrint('Owner Mobile: ${state.ownerMobile}');
    debugPrint('Delivery Radius: ${state.deliveryRadius}'); // 👈 NEW DEBUG LOG
    
    // Validate restaurant name character limit
    if (state.restaurantName.length > 30) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionMessage: 'Store name cannot exceed 30 characters',
      ));
      return;
    }
    
    // Validate owner name
    final ownerName = state.ownerName.trim();
    if (ownerName.isEmpty) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionMessage: 'Owner name is required',
      ));
      return;
    }
    
    if (ownerName.length < 2) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionMessage: 'Owner name must be at least 2 characters long',
      ));
      return;
    }
    
    if (ownerName.length > 50) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionMessage: 'Owner name cannot exceed 50 characters',
      ));
      return;
    }
    
    if (RegExp(r'[0-9]').hasMatch(ownerName)) {
      emit(state.copyWith(
        isSubmitting: false,
        submissionMessage: 'Owner name cannot contain numbers',
      ));
      return;
    }
    
    // Show loading indicator
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    
    try {
      // Convert operational hours to expected format
      final Map<String, String> operationalHours = {};
      
      final Map<int, String> dayMap = {
        0: 'sun',
        1: 'mon',
        2: 'tue',
        3: 'wed',
        4: 'thu',
        5: 'fri',
        6: 'sat',
      };
      
      for (var i = 0; i < state.hours.length; i++) {
        final day = state.hours[i];
        if (day.enabled) {
          final String dayKey = dayMap[i]!;
          final startHour = day.start.hour;
          final startMinute = day.start.minute;
          final endHour = day.end.hour;
          final endMinute = day.end.minute;
          
          // Format time for API (e.g., "9.30am - 9pm")
          String startFormatted = _formatTimeForAPI(startHour, startMinute);
          String endFormatted = _formatTimeForAPI(endHour, endMinute);
          
          operationalHours[dayKey] = '$startFormatted - $endFormatted';
        }
      }
      
      debugPrint('Operational Hours: ${jsonEncode(operationalHours)}');
      
      // Prepare restaurant photos
      List<File>? restaurantPhotos;
      if (state.imagePath != null) {
        restaurantPhotos = [File(state.imagePath!)];
        debugPrint('Image Path: ${state.imagePath}');
      }
      
      // Prepare the veg/nonveg field 
      String vegNonveg = state.type == RestaurantType.veg ? 'veg' : 'non-veg';
      debugPrint('Veg/NonVeg: $vegNonveg');
      
      // Log API call attempt
      debugPrint('Attempting to call API for profile update...');
      
      // Try multiple ways to get token
      String? token;
      String? partnerId;
      
      // First try TokenService
      token = await TokenService.getToken();
      partnerId = await TokenService.getUserId();
      
      // If not found, try SharedPreferences directly
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('token');
        debugPrint('Token retrieved from SharedPreferences: ${token != null ? (token.length > 20 ? token.substring(0, 20) + "..." : token) : "null"}');
        
        // Also save back to TokenService for future use
        if (token != null && token.isNotEmpty) {
          await TokenService.saveToken(token);
        }
      }
      
      if (partnerId == null || partnerId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        partnerId = prefs.getString('user_id');
        debugPrint('User ID retrieved from SharedPreferences: $partnerId');
        
        // Also save back to TokenService for future use
        if (partnerId != null && partnerId.isNotEmpty) {
          await TokenService.saveUserId(partnerId);
        }
      }
      
      // Final check
      if (token == null || token.isEmpty || partnerId == null || partnerId.isEmpty) {
        throw Exception('No token or user ID found. Please login again.');
      }
      
      // Create multipart request
      final url = Uri.parse('${ApiConstants.baseUrl}/partner/updatePartner');
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add all fields
      request.fields['partner_id'] = partnerId.toString();
      request.fields['restaurant_name'] = state.restaurantName;
      request.fields['address'] = state.ownerAddress;
      request.fields['email'] = state.ownerEmail;
      request.fields['operational_hours'] = jsonEncode(operationalHours);
      request.fields['owner_name'] = state.ownerName;
      
      // Add selected restaurant type
      if (state.selectedRestaurantType != null) {
        request.fields['restaurant_type'] = state.selectedRestaurantType!['name'];
        debugPrint('Adding restaurant_type to request: ${state.selectedRestaurantType!['name']}');
      }
      
      // Only add latitude/longitude if they have values
      if (state.latitude.isNotEmpty) {
        request.fields['latitude'] = state.latitude;
      }
      
      if (state.longitude.isNotEmpty) {
        request.fields['longitude'] = state.longitude;
      }
      
      request.fields['veg_nonveg'] = vegNonveg;
      
      if (state.cookingTime.isNotEmpty) {
        request.fields['cooking_time'] = state.cookingTime;
      }
      
      if (state.description.isNotEmpty) {
        request.fields['description'] = state.description;
      }
      
      // 👈 ADD NEW DELIVERY RADIUS FIELD
      if (state.deliveryRadius.isNotEmpty) {
        request.fields['delivery_radius'] = state.deliveryRadius;
        debugPrint('Adding delivery_radius to request: ${state.deliveryRadius}');
      }
      
      // Add files if available
      if (restaurantPhotos != null && restaurantPhotos.isNotEmpty) {
        for (var i = 0; i < restaurantPhotos.length; i++) {
          final file = restaurantPhotos[i];
          final extension = file.path.split('.').last.toLowerCase();
          final contentType = extension == 'png' 
              ? 'image/png' 
              : 'image/jpeg';
          
          request.files.add(
            http.MultipartFile(
              'restaurant_photos',
              file.readAsBytes().asStream(),
              file.lengthSync(),
              filename: 'restaurant_photo_${DateTime.now().millisecondsSinceEpoch}.$extension',
              contentType: MediaType.parse(contentType),
            ),
          );
        }
      }
      
      // Log request details
      debugPrint('Update Partner Request URL: $url');
      debugPrint('Update Partner Request Headers: ${request.headers}');
      debugPrint('Update Partner Request Fields: ${request.fields}');
      
      // Send request
      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);
        
        // Log response
        debugPrint('Update Partner Response Status: ${response.statusCode}');
        debugPrint('Update Partner Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final status = responseBody['status'];
          final message = responseBody['message'] ?? '';
          
          // Save restaurant type to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          if (state.selectedRestaurantType != null) {
            await prefs.setString('restaurant_type_name', state.selectedRestaurantType!['name']);
            debugPrint('Saved restaurant_type_name to SharedPreferences: ${state.selectedRestaurantType!['name']}');
          }

          // Save selected cuisines to SharedPreferences
          await prefs.setStringList('selected_cuisines', state.selectedCuisines.map((e) => e.toString()).toList());
          


          emit(state.copyWith(
            isSubmitting: false,
            submissionSuccess: status == 'SUCCESS',
            submissionMessage: message,
          ));
          
          debugPrint('Profile update success: $message');
          
          // Notify profile update service for real-time updates
          if (status == 'SUCCESS') {
            final profileUpdateService = ProfileUpdateService();
            
            // Update restaurant info service immediately
            RestaurantInfoService.updateRestaurantInfo(
              name: state.restaurantName,
              slogan: state.ownerAddress,
              imageUrl: state.imagePath,
            );
            
            // Notify restaurant details update
            profileUpdateService.notifyRestaurantDetailsUpdated({
              'restaurant_name': state.restaurantName,
              'owner_name': state.ownerName,
              'address': state.ownerAddress,
              'email': state.ownerEmail,
              'description': state.description,
              'cooking_time': state.cookingTime,
              'delivery_radius': state.deliveryRadius,
              'latitude': state.latitude,
              'longitude': state.longitude,
              'restaurant_type': state.selectedRestaurantType?['name'],
            });
            
            // Notify operational hours update
            profileUpdateService.notifyOperationalHoursUpdated(operationalHours);
            
            // Notify restaurant type update
            if (state.selectedRestaurantType != null) {
              profileUpdateService.notifyRestaurantTypeUpdated(state.selectedRestaurantType!['name']);
            }
            
            // Notify image update if image was changed
            if (state.imagePath != null) {
              profileUpdateService.notifyRestaurantImageUpdated(state.imagePath);
            }
            
            debugPrint('🔄 ProfileUpdateService: Notified all profile updates');
          }
        } else {
          throw Exception('API returned error: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      String errorMessage = 'Failed to update profile';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to server';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid response from server';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timeout: Server took too long to respond';
      } else if (e is Exception) {
        errorMessage = 'Server error: ${e.toString()}';
      }
      
      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        errorMessage: errorMessage,
      ));
    }
  }
  
  String _formatTimeForAPI(int hour, int minute) {
    String timeStr;
    
    if (hour == 0) {
      timeStr = '12';
    } else if (hour == 12) {
      timeStr = '12';
    } else if (hour > 12) {
      timeStr = '${hour - 12}';
    } else {
      timeStr = '$hour';
    }
    
    // Add minutes if they are not zero
    if (minute > 0) {
      timeStr += '.${minute.toString().padLeft(2, '0')}';
    }
    
    // Add am/pm
    if (hour == 0) {
      return '${timeStr}am';
    } else if (hour == 12) {
      return '${timeStr}pm';
    } else if (hour > 12) {
      return '${timeStr}pm';
    } else {
      return '${timeStr}am';
    }
  }
  
  // Phone OTP Verification Methods
  Future<void> _onInitializePhoneOtp(InitializePhoneOtpEvent event, Emitter<RestaurantProfileState> emit) async {
    emit(state.copyWith(
      isPhoneVerificationInProgress: true,
      phoneVerificationError: null,
    ));
    
    try {
      // Always combine country code with phone number
      String formattedNumber = '${state.selectedCountry.dialCode}${event.phoneNumber}';
      debugPrint('Combining country code ${state.selectedCountry.dialCode} with phone ${event.phoneNumber} = $formattedNumber');
      
      if (formattedNumber == '+911111111111') {
        debugPrint('Test phone number detected');
        
        if (Platform.isIOS) {
          debugPrint('iOS detected - using test mode');
          emit(state.copyWith(
            phoneVerificationId: 'test-verification-id',
            isPhoneVerificationInProgress: false,
          ));
          _startPhoneOtpTimer(emit);
          return;
        } else {
          await _auth.setSettings(
            appVerificationDisabledForTesting: true,
            forceRecaptchaFlow: false,
          );
        }
      } else {
        debugPrint('Real phone number - using build configuration');
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
          forceRecaptchaFlow: BuildConfig.shouldForceRecaptcha,
        );
      }
      
      debugPrint('Starting Firebase phone verification');
      
      // Store the current emit function to use in callbacks
      final currentEmit = emit;
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Verification completed automatically');
          // Handle verification completed directly
          await _handlePhoneOtpVerificationCompleted(credential.smsCode ?? '', currentEmit);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
          String errorMessage;
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'The provided phone number is not valid.';
          } else if (e.code == 'missing-client-identifier') {
            errorMessage = 'Missing client identifier. Please check your Firebase configuration.';
          } else if (e.code == 'app-not-authorized') {
            errorMessage = 'This app is not authorized to use Firebase Authentication. Please check your Firebase configuration.';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }
          // Handle verification failed directly
          _handlePhoneOtpVerificationFailed(errorMessage, currentEmit);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ Code sent! Verification ID: $verificationId');
          // Handle code sent directly
          _handlePhoneOtpCodeSent(verificationId, currentEmit);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Auto retrieval timeout. Verification ID: $verificationId');
          if (state.phoneVerificationId == null) {
            // Handle code sent directly
            _handlePhoneOtpCodeSent(verificationId, currentEmit);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ Error in _onInitializePhoneOtp: $e');
      String errorMessage = 'Failed to send OTP';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to server';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid response from server';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timeout: Server took too long to respond';
      } else if (e is Exception) {
        errorMessage = 'Verification error: ${e.toString()}';
      }
      
      emit(state.copyWith(
        isPhoneVerificationInProgress: false,
        phoneVerificationError: errorMessage,
      ));
    }
  }

  void _onPhoneOtpDigitChanged(PhoneOtpDigitChanged event, Emitter<RestaurantProfileState> emit) {
    final digits = List<String>.from(state.phoneOtpDigits);
    digits[event.index] = event.digit;
    
    emit(state.copyWith(
      phoneOtpDigits: digits,
    ));
  }

  Future<void> _onSubmitPhoneOtp(SubmitPhoneOtpEvent event, Emitter<RestaurantProfileState> emit) async {
    if (state.phoneVerificationId == null) {
      return;
    }

    emit(state.copyWith(
      isPhoneVerificationInProgress: true,
      phoneVerificationError: null,
    ));

    try {
      final otp = state.phoneOtpDigits.join('');
      debugPrint('Submitting OTP: $otp');

      // For test phone number, skip Firebase verification
      if (state.ownerMobile == '+911111111111') {
        debugPrint('Test phone number - skipping Firebase verification');
        if (otp == '000000' || otp == '123456') {
          debugPrint('✅ Test phone verification successful! Setting isPhoneVerified = true');
          emit(state.copyWith(
            isPhoneVerified: true,
            isPhoneVerificationInProgress: false,
            phoneVerificationError: null,
          ));
          _stopPhoneOtpTimer();
        } else {
          emit(state.copyWith(
            isPhoneVerificationInProgress: false,
            phoneVerificationError: 'Invalid test OTP. Use 000000 or 123456',
          ));
        }
        return;
      }

      // Create credential with Firebase
      final credential = PhoneAuthProvider.credential(
        verificationId: state.phoneVerificationId!,
        smsCode: otp,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful: ${userCredential.user?.uid}');

      // Sign out immediately - we don't want to keep user signed in
      await _auth.signOut();

      debugPrint('✅ Phone verification successful! Setting isPhoneVerified = true');
      emit(state.copyWith(
        isPhoneVerified: true,
        isPhoneVerificationInProgress: false,
        phoneVerificationError: null,
      ));
      _stopPhoneOtpTimer();

    } catch (e) {
      debugPrint('Error submitting OTP: $e');
      String errorMessage = 'Invalid OTP. Please try again.';
      
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.code == 'invalid-verification-id') {
          errorMessage = 'OTP expired. Please request a new one.';
        } else {
          errorMessage = e.message ?? 'Verification failed';
        }
      }
      
      emit(state.copyWith(
        isPhoneVerificationInProgress: false,
        phoneVerificationError: errorMessage,
      ));
    }
  }

  Future<void> _onResendPhoneOtp(ResendPhoneOtpEvent event, Emitter<RestaurantProfileState> emit) async {
    if (state.ownerMobile.isEmpty) {
      emit(state.copyWith(
        phoneVerificationError: 'Phone number is required',
      ));
      return;
    }

    emit(state.copyWith(
      isPhoneVerificationInProgress: true,
      phoneVerificationError: null,
    ));

    try {
      // Reset digits
      emit(state.copyWith(
        phoneOtpDigits: List<String>.filled(6, ''),
      ));

      // Re-initialize OTP - call the method directly instead of using add()
      await _onInitializePhoneOtp(InitializePhoneOtpEvent(state.ownerMobile), emit);
    } catch (e) {
      emit(state.copyWith(
        isPhoneVerificationInProgress: false,
        phoneVerificationError: 'Failed to resend OTP: $e',
      ));
    }
  }

  void _onPhoneOtpTimerTick(PhoneOtpTimerTickEvent event, Emitter<RestaurantProfileState> emit) {
    final sec = state.phoneOtpTimer;
    if (sec > 0) {
      emit(state.copyWith(phoneOtpTimer: sec - 1));
    } else {
      _stopPhoneOtpTimer();
    }
  }

  Future<void> _onPhoneOtpVerificationCompleted(PhoneOtpVerificationCompleted event, Emitter<RestaurantProfileState> emit) async {
    final smsCode = event.smsCode;
    final digits = List<String>.filled(6, '');
    
    for (int i = 0; i < smsCode.length && i < 6; i++) {
      digits[i] = smsCode[i];
    }
    
    emit(state.copyWith(
      phoneOtpDigits: digits,
    ));
    // Call submit OTP directly instead of using add()
    await _onSubmitPhoneOtp(const SubmitPhoneOtpEvent(), emit);
  }

  void _onPhoneOtpVerificationFailed(PhoneOtpVerificationFailed event, Emitter<RestaurantProfileState> emit) {
    emit(state.copyWith(
      isPhoneVerificationInProgress: false,
      phoneVerificationError: event.message,
    ));
  }

  void _onPhoneOtpCodeSent(PhoneOtpCodeSent event, Emitter<RestaurantProfileState> emit) {
    debugPrint('_onPhoneOtpCodeSent called with verificationId: ${event.verificationId}');
    if (event.verificationId.isEmpty) {
      debugPrint('ERROR: Received empty verification ID');
      emit(state.copyWith(
        isPhoneVerificationInProgress: false,
        phoneVerificationError: 'Failed to receive verification ID from Firebase',
      ));
      return;
    }
    
    emit(state.copyWith(
      phoneVerificationId: event.verificationId,
      isPhoneVerificationInProgress: false,
    ));
    _startPhoneOtpTimer(emit);
  }

  void _startPhoneOtpTimer(Emitter<RestaurantProfileState> emit) {
    _phoneOtpTimer?.cancel();
    emit(state.copyWith(phoneOtpTimer: 30));
    _phoneOtpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Use a try-catch to handle potential BLoC closure
      try {
        add(const PhoneOtpTimerTickEvent());
      } catch (e) {
        debugPrint('Timer tick failed - BLoC may be closed: $e');
        _phoneOtpTimer?.cancel();
      }
    });
  }

  void _stopPhoneOtpTimer() {
    _phoneOtpTimer?.cancel();
  }

  @override
  Future<void> close() {
    _phoneOtpTimer?.cancel();
    return super.close();
  }
  
  // Country Detection Methods
  Future<void> _onAutoDetectCountryRequested(AutoDetectCountryRequested event, Emitter<RestaurantProfileState> emit) async {
    emit(state.copyWith(isCountryDetectionInProgress: true));
    
    try {
      // Try using device locale first as a fast path
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      if (locale.countryCode != null) {
        final fromLocale = CountryData.findByCode(locale.countryCode!.toUpperCase());
        if (fromLocale != null) {
          emit(state.copyWith(
            selectedCountry: fromLocale,
            isCountryDetectionInProgress: false,
          ));
          return;
        }
      }

      // Fallback to geolocation + reverse geocoding
      final hasPermission = await _hasLocationPermissionWithoutPrompt();
      if (!hasPermission) {
        emit(state.copyWith(isCountryDetectionInProgress: false));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final isoCountryCode = placemarks.first.isoCountryCode;
        if (isoCountryCode != null) {
          final match = CountryData.findByCode(isoCountryCode.toUpperCase());
          if (match != null) {
            emit(state.copyWith(
              selectedCountry: match,
              isCountryDetectionInProgress: false,
            ));
            return;
          }
        }
      }
      
      // If all else fails, keep the default country
      emit(state.copyWith(isCountryDetectionInProgress: false));
    } catch (e) {
      debugPrint('Auto-detect country failed: $e');
      String errorMessage = 'Failed to detect country';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to location services';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid location data';
      } else if (e is TimeoutException) {
        errorMessage = 'Location request timeout: Service took too long to respond';
      } else if (e is Exception) {
        errorMessage = 'Location error: ${e.toString()}';
      }
      
      emit(state.copyWith(
        isCountryDetectionInProgress: false,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onCountryChanged(CountryChanged event, Emitter<RestaurantProfileState> emit) {
    emit(state.copyWith(selectedCountry: event.country));
  }

  Future<bool> _hasLocationPermissionWithoutPrompt() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
  
  // Location Permission Methods
  Future<void> _onCheckLocationPermission(CheckLocationPermissionEvent event, Emitter<RestaurantProfileState> emit) async {
    emit(state.copyWith(isCountryDetectionInProgress: true));
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          hasLocationPermission: false,
          isCountryDetectionInProgress: false,
          phoneVerificationError: 'Location services are disabled. Please enable location services in your device settings.',
        ));
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        emit(state.copyWith(
          hasLocationPermission: true,
          isCountryDetectionInProgress: false,
        ));
        // Also trigger auto-detect country
        await _onAutoDetectCountryRequested(AutoDetectCountryRequested(), emit);
      } else if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          hasLocationPermission: false,
          isCountryDetectionInProgress: false,
          phoneVerificationError: 'Location permission permanently denied. Please enable location access in your device settings.',
        ));
      } else {
        emit(state.copyWith(
          hasLocationPermission: false,
          isCountryDetectionInProgress: false,
          phoneVerificationError: 'Location permission denied. Location access is required to edit phone number.',
        ));
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      String errorMessage = 'Failed to check location permission';
      
      // Handle specific exception types
      if (e is HttpException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Connection error: Unable to connect to location services';
      } else if (e is FormatException) {
        errorMessage = 'Data format error: Invalid location data';
      } else if (e is TimeoutException) {
        errorMessage = 'Location request timeout: Service took too long to respond';
      } else if (e is Exception) {
        errorMessage = 'Location permission error: ${e.toString()}';
      }
      
      emit(state.copyWith(
        hasLocationPermission: false,
        isCountryDetectionInProgress: false,
        phoneVerificationError: errorMessage,
      ));
    }
  }

  void _onLocationPermissionGranted(LocationPermissionGranted event, Emitter<RestaurantProfileState> emit) {
    emit(state.copyWith(
      hasLocationPermission: true,
      isCountryDetectionInProgress: false,
    ));
  }

  void _onLocationPermissionDenied(LocationPermissionDenied event, Emitter<RestaurantProfileState> emit) {
    emit(state.copyWith(
      hasLocationPermission: false,
      isCountryDetectionInProgress: false,
      phoneVerificationError: event.reason,
    ));
  }

  // Helper methods for Firebase callbacks to avoid using add() in async contexts
  Future<void> _handlePhoneOtpVerificationCompleted(String smsCode, Emitter<RestaurantProfileState> emit) async {
    debugPrint('✅ Phone OTP verification completed with code: $smsCode');
    emit(state.copyWith(
      isPhoneVerified: true,
      isPhoneVerificationInProgress: false,
      phoneVerificationError: null,
    ));
    _stopPhoneOtpTimer();
  }

  void _handlePhoneOtpVerificationFailed(String message, Emitter<RestaurantProfileState> emit) {
    debugPrint('❌ Phone OTP verification failed: $message');
    emit(state.copyWith(
      isPhoneVerificationInProgress: false,
      phoneVerificationError: message,
    ));
  }

  void _handlePhoneOtpCodeSent(String verificationId, Emitter<RestaurantProfileState> emit) {
    debugPrint('✅ Phone OTP code sent with verification ID: $verificationId');
    emit(state.copyWith(
      phoneVerificationId: verificationId,
      isPhoneVerificationInProgress: false,
      phoneVerificationError: null,
    ));
    _startPhoneOtpTimer(emit);
  }
}