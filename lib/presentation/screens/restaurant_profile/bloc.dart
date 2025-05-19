import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/api_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';
import '../resturant_details_2/state.dart';
import 'event.dart';
import 'state.dart';

class RestaurantProfileBloc
    extends Bloc<RestaurantProfileEvent, RestaurantProfileState> {
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _imagePicker = ImagePicker();

  RestaurantProfileBloc()
      : super(
          RestaurantProfileState(
            hours: [
              const OperationalDay(label: 'Sunday', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 21, minute: 0)),
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
    
    // Image selection
    on<SelectImagePressed>(_onSelectImage);
    
    // Owner fields
    on<OwnerNameChanged>((e, emit) => emit(state.copyWith(ownerName: e.value)));
    on<OwnerMobileChanged>((e, emit) => emit(state.copyWith(ownerMobile: e.v)));
    on<OwnerEmailChanged>((e, emit) => emit(state.copyWith(ownerEmail: e.v)));
    on<OwnerAddressChanged>((e, emit) => emit(state.copyWith(ownerAddress: e.v)));

    // Restaurant fields
    on<RestaurantNameChanged>((e, emit) => emit(state.copyWith(restaurantName: e.value)));
    on<DescriptionChanged>((e, emit) => emit(state.copyWith(description: e.v)));
    on<CookingTimeChanged>((e, emit) => emit(state.copyWith(cookingTime: e.v)));

    // Location fields
    on<LatitudeChanged>((e, emit) => emit(state.copyWith(latitude: e.v)));
    on<LongitudeChanged>((e, emit) => emit(state.copyWith(longitude: e.v)));

    // Type
    on<TypeChanged>((e, emit) => emit(state.copyWith(type: e.type)));

    // Hours
    on<ToggleDayEnabledEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(enabled: !hours[e.index].enabled);
      emit(state.copyWith(hours: hours));
    });
    on<UpdateStartTimeEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(start: e.time);
      emit(state.copyWith(hours: hours));
    });
    on<UpdateEndTimeEvent>((e, emit) {
      final hours = List<OperationalDay>.from(state.hours);
      hours[e.index] = hours[e.index].copyWith(end: e.time);
      emit(state.copyWith(hours: hours));
    });

    // Actions
    on<UpdateProfilePressed>(_onUpdateProfile);
    
    // Load initial data immediately
    add(LoadInitialData());
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
        if (data['veg-nonveg'] != null) {
          final String vegNonveg = data['veg-nonveg'].toString().toLowerCase();
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
            imageUrl = data['restaurant_photos'];
          }
        }
        
        // Handle null values properly
        final latitudeStr = data['latitude']?.toString() ?? '';
        final longitudeStr = data['longitude']?.toString() ?? '';
        final cookingTimeStr = data['cooking_time']?.toString() ?? '';
        final descriptionStr = data['description']?.toString() ?? '';
        
        // Update state with all fetched data
        emit(state.copyWith(
          isLoading: false,
          ownerName: data['owner_name'] ?? '',
          ownerEmail: data['email'] ?? '',
          ownerAddress: data['address'] ?? '',
          restaurantName: data['restaurant_name'] ?? '',
          description: descriptionStr,
          cookingTime: cookingTimeStr,
          latitude: latitudeStr,
          longitude: longitudeStr,
          type: restaurantType,
          hours: updatedHours,
          restaurantImageUrl: imageUrl,
        ));
        
        debugPrint('State updated with API data');
        debugPrint('Restaurant name: ${state.restaurantName}');
        debugPrint('Owner name: ${state.ownerName}');
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
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading data: ${e.toString()}',
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
    // Format expected: "9am" or "9pm"
    try {
      timeStr = timeStr.toLowerCase().trim();
      bool isPM = timeStr.contains('pm');
      
      String hourStr = timeStr
          .replaceAll('am', '')
          .replaceAll('pm', '')
          .trim();
      
      int hour = int.parse(hourStr);
      
      // Convert to 24-hour format
      if (isPM && hour < 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: 0);
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
        emit(state.copyWith(imagePath: image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
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
          final endHour = day.end.hour;
          
          // Format time for API (e.g., "9am - 9pm")
          String startFormatted = _formatTimeForAPI(startHour);
          String endFormatted = _formatTimeForAPI(endHour);
          
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
      String vegNonveg = state.type == RestaurantType.veg ? 'veg' : 'non veg';
      debugPrint('Veg/NonVeg: $vegNonveg');
      
      // Prepare category based on veg/nonveg
      String category = state.type == RestaurantType.veg ? 'vegetarian' : 'non-vegetarian';
      debugPrint('Category: $category');
      
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
      request.fields['category'] = category;
      request.fields['operational_hours'] = jsonEncode(operationalHours);
      request.fields['owner_name'] = state.ownerName;
      
      // Only add latitude/longitude if they have values
      if (state.latitude.isNotEmpty) {
        request.fields['latitude'] = state.latitude;
      }
      
      if (state.longitude.isNotEmpty) {
        request.fields['longitude'] = state.longitude;
      }
      
      request.fields['veg-nonveg'] = vegNonveg;
      
      if (state.cookingTime.isNotEmpty) {
        request.fields['cooking_time'] = state.cookingTime;
      }
      
      if (state.description.isNotEmpty) {
        request.fields['description'] = state.description;
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
          
          emit(state.copyWith(
            isSubmitting: false,
            submissionSuccess: status == 'SUCCESS',
            submissionMessage: message,
          ));
          
          debugPrint('Profile update success: $message');
        } else {
          throw Exception('API returned error: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      emit(state.copyWith(
        isSubmitting: false,
        submissionSuccess: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      ));
    }
  }
  
  String _formatTimeForAPI(int hour) {
    if (hour == 0) {
      return '12am';
    } else if (hour == 12) {
      return '12pm';
    } else if (hour > 12) {
      return '${hour - 12}pm';
    } else {
      return '${hour}am';
    }
  }
}