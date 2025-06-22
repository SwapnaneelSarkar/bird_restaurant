import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class RingtoneTestWidget extends StatefulWidget {
  const RingtoneTestWidget({super.key});

  @override
  State<RingtoneTestWidget> createState() => _RingtoneTestWidgetState();
}

class _RingtoneTestWidgetState extends State<RingtoneTestWidget> {
  final NotificationService _notificationService = NotificationService();
  int _duration = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Ringtone Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Ringtone Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Duration: '),
                        Expanded(
                          child: Slider(
                            value: _duration.toDouble(),
                            min: 5,
                            max: 30,
                            divisions: 25,
                            label: '$_duration seconds',
                            onChanged: (value) {
                              setState(() {
                                _duration = value.round();
                              });
                            },
                          ),
                        ),
                        Text('$_duration s'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _notificationService.isPlayingRingtone
                                ? null
                                : () async {
                                    await _notificationService.playCustomRingtone(
                                      durationSeconds: _duration,
                                    );
                                    setState(() {});
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Ringtone'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _notificationService.isPlayingRingtone
                                ? () async {
                                    await _notificationService.stopRingtone();
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Ringtone'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _notificationService.isPlayingRingtone
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: _notificationService.isPlayingRingtone
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notificationService.isPlayingRingtone
                                    ? 'Ringtone is playing'
                                    : 'Ringtone is stopped',
                                style: TextStyle(
                                  color: _notificationService.isPlayingRingtone
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Note: Custom audio file needed for extended ringtone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Test Buttons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _notificationService.isPlayingRingtone
                              ? null
                              : () async {
                                  await _notificationService.playCustomRingtone(
                                    durationSeconds: 5,
                                  );
                                  setState(() {});
                                },
                          child: const Text('5s Test'),
                        ),
                        ElevatedButton(
                          onPressed: _notificationService.isPlayingRingtone
                              ? null
                              : () async {
                                  await _notificationService.playCustomRingtone(
                                    durationSeconds: 10,
                                  );
                                  setState(() {});
                                },
                          child: const Text('10s Test'),
                        ),
                        ElevatedButton(
                          onPressed: _notificationService.isPlayingRingtone
                              ? null
                              : () async {
                                  await _notificationService.playCustomRingtone(
                                    durationSeconds: 20,
                                  );
                                  setState(() {});
                                },
                          child: const Text('20s Test'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Replace the placeholder audio file in assets/audio/notification_ringtone.ogg with your actual ringtone file\n'
                      '2. Test the ringtone using the controls above\n'
                      '3. The ringtone will automatically play when notifications are received\n'
                      '4. You can manually control the ringtone duration and playback',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔊 Troubleshooting Tips:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Check device volume (media volume)\n'
                            '• Ensure audio file is not silent\n'
                            '• Try "Test Audio Only" button\n'
                            '• Check debug logs for audio state changes\n'
                            '• Make sure audio file is 10-15 seconds long',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Test local notification
                        await _notificationService.testNotification();
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Test audio playback directly
                        await _notificationService.testAudioPlayback();
                      },
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Test Audio Only'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 