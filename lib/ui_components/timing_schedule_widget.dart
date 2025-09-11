// lib/ui_components/timing_schedule_widget.dart
import 'package:flutter/material.dart';
import '../presentation/screens/add_product/state.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class TimingScheduleWidget extends StatefulWidget {
  final TimingSchedule timingSchedule;
  final Function(String day, bool enabled, String start, String end) onDayScheduleChanged;
  final bool timingEnabled;
  final Function(bool) onTimingEnabledChanged;
  final String timezone;
  final Function(String) onTimezoneChanged;
  final String? timingError;

  const TimingScheduleWidget({
    Key? key,
    required this.timingSchedule,
    required this.onDayScheduleChanged,
    required this.timingEnabled,
    required this.onTimingEnabledChanged,
    required this.timezone,
    required this.onTimezoneChanged,
    this.timingError,
  }) : super(key: key);

  @override
  State<TimingScheduleWidget> createState() => _TimingScheduleWidgetState();
}

class _TimingScheduleWidgetState extends State<TimingScheduleWidget> {
  final List<String> days = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> timezones = [
    'Asia/Kolkata',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Australia/Sydney',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timing Enabled Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enable Timing Schedule',
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.medium,
                color: ColorManager.black,
              ),
            ),
            Switch(
              value: widget.timingEnabled,
              onChanged: widget.onTimingEnabledChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF5D5FEF),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (widget.timingEnabled) ...[
          // Timezone Selection
          Text(
            'Timezone',
            style: TextStyle(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              value: widget.timezone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: timezones.map((timezone) {
                return DropdownMenuItem(
                  value: timezone,
                  child: Text(timezone),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.onTimezoneChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Days Schedule
          Text(
            'Weekly Schedule',
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set availability for each day of the week',
            style: TextStyle(
              fontSize: FontSize.s12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Days List
          ...days.map((day) => _buildDayScheduleItem(day)).toList(),
          
          // Timing Error Display
          if (widget.timingError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.timingError!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: FontSize.s12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDayScheduleItem(String day) {
    DaySchedule schedule;
    switch (day.toLowerCase()) {
      case 'monday':
        schedule = widget.timingSchedule.monday;
        break;
      case 'tuesday':
        schedule = widget.timingSchedule.tuesday;
        break;
      case 'wednesday':
        schedule = widget.timingSchedule.wednesday;
        break;
      case 'thursday':
        schedule = widget.timingSchedule.thursday;
        break;
      case 'friday':
        schedule = widget.timingSchedule.friday;
        break;
      case 'saturday':
        schedule = widget.timingSchedule.saturday;
        break;
      case 'sunday':
        schedule = widget.timingSchedule.sunday;
        break;
      default:
        schedule = DaySchedule(enabled: false, start: '09:00', end: '22:00');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header with Toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.medium,
                    color: ColorManager.black,
                  ),
                ),
              ),
              Switch(
                value: schedule.enabled,
                onChanged: (value) {
                  widget.onDayScheduleChanged(day.toLowerCase(), value, schedule.start, schedule.end);
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF5D5FEF),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[300],
              ),
            ],
          ),
          
          if (schedule.enabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Start Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: FontSize.s12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTimePickerField(
                        schedule.start,
                        (time) {
                          widget.onDayScheduleChanged(day.toLowerCase(), schedule.enabled, time, schedule.end);
                          // Trigger validation after time change
                          Future.delayed(const Duration(milliseconds: 100), () {
                            // This will be handled by the parent widget
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // End Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: TextStyle(
                          fontSize: FontSize.s12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTimePickerField(
                        schedule.end,
                        (time) {
                          widget.onDayScheduleChanged(day.toLowerCase(), schedule.enabled, schedule.start, time);
                          // Trigger validation after time change
                          Future.delayed(const Duration(milliseconds: 100), () {
                            // This will be handled by the parent widget
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerField(String currentTime, Function(String) onTimeChanged) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTimeString(currentTime),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,
                  hourMinuteTextColor: ColorManager.black,
                  hourMinuteColor: Colors.grey[200],
                  dialHandColor: const Color(0xFFCD6E32),
                  dialBackgroundColor: Colors.grey[100],
                  dialTextColor: ColorManager.black,
                  entryModeIconColor: ColorManager.black,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(timeString);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              color: Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              currentTime,
              style: TextStyle(
                fontSize: FontSize.s12,
                color: ColorManager.black,
                fontWeight: FontWeightManager.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string: $e');
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }
} 