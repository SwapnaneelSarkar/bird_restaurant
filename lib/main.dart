// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'presentation/resources/router/router.dart';
import 'presentation/screens/signin/bloc.dart';
import 'services/chat_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // allow SVGs to use their own color filters instead of Flutter's default
  svg.cacheColorFilterOverride = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Chat service provider for global access
        ChangeNotifierProvider<ChatService>(
          create: (_) => ChatService(),
          lazy: false, // Create immediately
        ),
        // Login bloc provider
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(),
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