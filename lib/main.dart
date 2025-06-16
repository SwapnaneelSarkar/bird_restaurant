// lib/main.dart
import 'package:bird_restaurant/firebase_options.dart';
import 'package:bird_restaurant/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';

import 'presentation/resources/router/router.dart';
import 'presentation/screens/reviewPage/bloc.dart';
import 'presentation/screens/signin/bloc.dart';
import 'presentation/screens/chat/bloc.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );
    try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('✅ NotificationService initialized in main');
  } catch (e) {
    debugPrint('❌ Error initializing NotificationService in main: $e');
    // Don't crash the app if notification service fails to initialize
  }
  
  
  // allow SVGs to use their own color filters instead of Flutter's default
  svg.cacheColorFilterOverride = false;
  runApp(const MyApp());
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
      ),
    );
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