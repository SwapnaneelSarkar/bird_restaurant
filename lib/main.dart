// lib/main.dart
import 'package:bird_restaurant/firebase_options.dart';
import 'package:bird_restaurant/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'dart:ui';

import 'presentation/resources/router/router.dart';
import 'presentation/screens/reviewPage/bloc.dart';
import 'presentation/screens/signin/bloc.dart';
import 'presentation/screens/chat/bloc.dart'; // Add this import

// Global error handler
void _handleError(Object error, StackTrace stackTrace) {
  developer.log('🚨 GLOBAL ERROR: $error', name: 'BirdRestaurant');
  developer.log('📚 Stack trace: $stackTrace', name: 'BirdRestaurant');
  
  // Log to console for debugging
  debugPrint('🚨 GLOBAL ERROR: $error');
  debugPrint('📚 Stack trace: $stackTrace');
}

void main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('🚨 FLUTTER ERROR: ${details.exception}', name: 'BirdRestaurant');
    developer.log('📚 Stack trace: ${details.stack}', name: 'BirdRestaurant');
    debugPrint('🚨 FLUTTER ERROR: ${details.exception}');
    debugPrint('📚 Stack trace: ${details.stack}');
  };

  // Set up unhandled exception handler
  PlatformDispatcher.instance.onError = (error, stack) {
    _handleError(error, stack);
    return true;
  };

  try {
    developer.log('🚀 Starting Bird Restaurant app...', name: 'BirdRestaurant');
    debugPrint('🚀 Starting Bird Restaurant app...');
    
    WidgetsFlutterBinding.ensureInitialized();
    developer.log('✅ WidgetsFlutterBinding initialized', name: 'BirdRestaurant');
    
    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('✅ Firebase initialized successfully', name: 'BirdRestaurant');
    } catch (e) {
      developer.log('❌ Firebase initialization failed: $e', name: 'BirdRestaurant');
      debugPrint('❌ Firebase initialization failed: $e');
      // Continue without Firebase if it fails
    }
    
    // Initialize notification service with better error handling
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      developer.log('✅ NotificationService initialized in main', name: 'BirdRestaurant');
    } catch (e) {
      developer.log('❌ Error initializing NotificationService in main: $e', name: 'BirdRestaurant');
      debugPrint('❌ Error initializing NotificationService in main: $e');
      // Don't crash the app if notification service fails to initialize
    }
    
    // allow SVGs to use their own color filters instead of Flutter's default
    svg.cacheColorFilterOverride = false;
    
    developer.log('✅ All services initialized, running app...', name: 'BirdRestaurant');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    developer.log('🚨 CRITICAL ERROR during app initialization: $e', name: 'BirdRestaurant');
    developer.log('📚 Stack trace: $stackTrace', name: 'BirdRestaurant');
    debugPrint('🚨 CRITICAL ERROR during app initialization: $e');
    debugPrint('📚 Stack trace: $stackTrace');
    
    // Show error screen instead of crashing
    runApp(const ErrorApp());
  }
}

// Error app widget to show when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
                const SizedBox(height: 20),
                Text(
                  'App Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The app failed to initialize properly. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(),
        ),
        BlocProvider<ReviewBloc>(  // Add this provider
          create: (_) => ReviewBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bird Partner',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        initialRoute: Routes.splash, // Set splash screen as initial route
        onGenerateRoute: RouteGenerator.getRoute,
        builder: (context, child) {
          // Add error boundary widget only
          return ErrorBoundary(child: child!);
        },
      ),
    );
  }
}

// Error boundary widget to catch widget tree errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Error? _error;

  @override
  void initState() {
    super.initState();
    // Set up error handling for this widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception as Error?;
      });
      developer.log('🚨 WIDGET ERROR: ${details.exception}', name: 'BirdRestaurant');
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
                const SizedBox(height: 20),
                Text(
                  'Widget Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A widget error occurred. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}

// // lib/main.dart
// import 'package:bird_restaurant/test/view.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Chat Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const ChatView1(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }