// lib/presentation/screens/restaurant_details/category/bloc.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/enums.dart';
import 'event.dart';
import 'state.dart';

class RestaurantCategoryBloc extends Bloc<RestaurantCategoryEvent, RestaurantCategoryState> {
  RestaurantCategoryBloc() : super(RestaurantCategoryState.initial()) {
    on<ToggleCuisineEvent>(_onToggle);
    on<ToggleDayEnabledEvent>(_onToggleDayEnabled);
    on<UpdateStartTimeEvent>(_onUpdateStartTime);
    on<UpdateEndTimeEvent>(_onUpdateEndTime);
    on<LoadSavedDataEvent>(_onLoadSavedData);
  }

  Future<void> _onToggle(
    ToggleCuisineEvent event,
    Emitter<RestaurantCategoryState> emit,
  ) async {
    final updated = List<CuisineType>.from(state.selected);
    if (updated.contains(event.type)) {
      updated.remove(event.type);
      debugPrint('❌ Removed ${event.type.label}');
    } else {
      updated.add(event.type);
      debugPrint('✅ Added ${event.type.label}');
    }
    emit(state.copyWith(selected: updated));
    await _saveData();
  }

  Future<void> _onToggleDayEnabled(
    ToggleDayEnabledEvent event,
    Emitter<RestaurantCategoryState> emit,
  ) async {
    final updatedDays = List<OperationalDay>.from(state.days);
    final current = updatedDays[event.dayIndex];
    updatedDays[event.dayIndex] = current.copyWith(enabled: !current.enabled);
    emit(state.copyWith(days: updatedDays));
    await _saveData();
  }

  Future<void> _onUpdateStartTime(
    UpdateStartTimeEvent event,
    Emitter<RestaurantCategoryState> emit,
  ) async {
    final updatedDays = List<OperationalDay>.from(state.days);
    updatedDays[event.dayIndex] = 
        updatedDays[event.dayIndex].copyWith(start: event.time);
    emit(state.copyWith(days: updatedDays));
    await _saveData();
  }

  Future<void> _onUpdateEndTime(
    UpdateEndTimeEvent event,
    Emitter<RestaurantCategoryState> emit,
  ) async {
    final updatedDays = List<OperationalDay>.from(state.days);
    updatedDays[event.dayIndex] = 
        updatedDays[event.dayIndex].copyWith(end: event.time);
    emit(state.copyWith(days: updatedDays));
    await _saveData();
  }

  Future<void> _onLoadSavedData(
    LoadSavedDataEvent event,
    Emitter<RestaurantCategoryState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load selected cuisines
    final selectedCuisineStrings = prefs.getStringList('selected_cuisines') ?? [];
    final selectedCuisines = selectedCuisineStrings
        .map((e) => CuisineType.values.firstWhere(
              (ct) => ct.toString() == e,
              orElse: () => CuisineType.bakery, // default fallback
            ))
        .toList();
    
    // Load supercategory information
    final selectedSupercategoryId = prefs.getString('selected_supercategory_id');
    final selectedSupercategoryName = prefs.getString('selected_supercategory_name');
    
    // Load operational days
    final daysJson = prefs.getString('operational_days');
    List<OperationalDay> loadedDays = state.days; // default
    
    if (daysJson != null) {
      final List<dynamic> decodedList = json.decode(daysJson);
      loadedDays = decodedList.map((item) {
        return OperationalDay(
          label: item['label'],
          enabled: item['enabled'],
          start: TimeOfDay(
            hour: item['start']['hour'],
            minute: item['start']['minute'],
          ),
          end: TimeOfDay(
            hour: item['end']['hour'],
            minute: item['end']['minute'],
          ),
        );
      }).toList();
    }
    
    emit(state.copyWith(
      selected: selectedCuisines,
      days: loadedDays,
      selectedSupercategoryId: selectedSupercategoryId,
      selectedSupercategoryName: selectedSupercategoryName,
    ));
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save selected cuisines
    final selectedCuisineStrings = state.selected
        .map((e) => e.toString())
        .toList();
    await prefs.setStringList('selected_cuisines', selectedCuisineStrings);
    
    // Save operational days in the original format for loading
    final daysJson = json.encode(
      state.days.map((day) => {
        'label': day.label,
        'enabled': day.enabled,
        'start': {
          'hour': day.start.hour,
          'minute': day.start.minute,
        },
        'end': {
          'hour': day.end.hour,
          'minute': day.end.minute,
        },
      }).toList()
    );
    await prefs.setString('operational_days', daysJson);
    
    // Save operational hours in the format shown in the photo
    final Map<String, String> operationalHoursMap = {};
    for (var day in state.days) {
      if (day.enabled) {
        final String dayAbbrev = _getDayAbbreviation(day.label);
        final String timeRange = _formatTimeRange(day.start, day.end);
        operationalHoursMap[dayAbbrev] = timeRange;
      }
    }
    
    final operationalHoursJson = json.encode(operationalHoursMap);
    await prefs.setString('operational_hours', operationalHoursJson);
    
    debugPrint('💾 Data saved - Cuisines: ${state.selected.map((e) => e.label).toList()}');
    debugPrint('💾 Operational Hours: $operationalHoursMap');
  }
  
  String _getDayAbbreviation(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'sunday':
        return 'sun';
      case 'monday':
        return 'mon';
      case 'tuesday':
        return 'tue';
      case 'wednesday':
        return 'wed';
      case 'thursday':
        return 'thu';
      case 'friday':
        return 'fri';
      case 'saturday':
        return 'sat';
      default:
        return dayName.substring(0, 3).toLowerCase();
    }
  }
  
  String _formatTimeRange(TimeOfDay start, TimeOfDay end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    
    // Add minutes if they are not zero
    if (time.minute > 0) {
      return '$hour.${time.minute.toString().padLeft(2, '0')}$period';
    } else {
      return '$hour$period';
    }
  }
}