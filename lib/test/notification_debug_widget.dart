// lib/test/notification_debug_widget.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationDebugWidget extends StatelessWidget {
  const NotificationDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification Service Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test buttons
            ElevatedButton(
              onPressed: () async {
                await NotificationService().quickTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🚀 Quick Test',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testNotificationService();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🧪 Run Comprehensive Test',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testRealNotification();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '📱 Test Real Notification',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testActionableNewOrderNotification();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🔔 Test Actionable Notification',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testOrderActionNavigation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🧭 Test Navigation',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testOrderAcceptance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '✅ Test Order Acceptance',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().checkForStoredNotificationAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🔍 Check Stored Actions',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testNotificationActions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🔘 Test Action Buttons',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testCompleteActionFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🔄 Test Complete Flow',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testDuplicatePrevention();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🔄 Test Duplicate Prevention',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () async {
                await NotificationService().testApiStatusUpdate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🌐 Test API Call',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () {
                NotificationService().clearProcessedNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Processed notifications cache cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '🧹 Clear Notification Cache',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () {
                final count = NotificationService().getProcessedNotificationsCount();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Processed notifications: $count'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                '📊 Show Cache Count',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Run Comprehensive Test to check all components\n'
              '2. Test Actionable Notification to send a test notification\n'
              '3. Test Navigation to check if OrderAction page opens\n'
              '4. Test API Call to verify status updates work\n'
              '5. Clear Cache if you see duplicate notifications\n'
              '6. Check debug logs in console for detailed information',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
} 