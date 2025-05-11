// lib/presentation/resources/router/router.dart

import 'package:bird_restaurant/presentation/screens/add_resturant_info/view.dart';
import 'package:bird_restaurant/presentation/screens/signin/view.dart';
import 'package:flutter/material.dart';

import '../../screens/application_status/view.dart';
import '../../screens/homePage/view.dart';
import '../../screens/otp_screen/view.dart';
import '../../screens/restaurant_details_3/view.dart';
import '../../screens/restaurant_profile/view.dart';
import '../../screens/resturant_details_2/view.dart';
import '../../screens/splashScreen/view.dart';

class Routes {
  static const String splash = '/'; // Add splash as default route
  static const String signin = '/signin';
  static const String otp = '/otp';
  static const String detailsAdd = '/detailsAdd';
  static const String detailsAdd2 = '/detailsAdd2';
  static const String detailsAdd3 = '/detailsAdd3';
  static const String applicationStatus = '/applicationStatus';
  static const String profile = '/profile';
  static const String homePage = '/home';
  static const String blank = '/blank';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    final name = routeSettings.name;
    
    if (name == null) {
      return unDefinedRoute();
    }
    
    try {
      switch (name) {
        case Routes.splash:
        case '/':
          return MaterialPageRoute(builder: (_) => const SplashView());
          
        case Routes.signin:
        case '/signin':
          return MaterialPageRoute(builder: (_) => const LoginView());

        case Routes.otp:
        case '/otp':
          final String? phoneNumber = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => OtpView(mobileNumber: phoneNumber),
            settings: routeSettings, 
          );

        case Routes.detailsAdd:
        case '/detailsAdd':
          return MaterialPageRoute(builder: (_) => const RestaurantDetailsAddView());

        case Routes.detailsAdd2:
        case '/detailsAdd2':
          return MaterialPageRoute(builder: (_) => const RestaurantCategoryView());

        case Routes.detailsAdd3:
        case '/detailsAdd3':
          return MaterialPageRoute(builder: (_) => const RestaurantDocumentsSubmitView());

        case Routes.applicationStatus:
        case '/applicationStatus':
          final String? mobileNumber = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => ApplicationStatusView(mobileNumber: mobileNumber ?? ''),
            settings: routeSettings,
          );

        case Routes.profile:
        case '/profile':
          return MaterialPageRoute(builder: (_) => const RestaurantProfileView());

        case Routes.homePage:
        case '/home':
          return MaterialPageRoute(builder: (_) => const HomeView());

        default:
          return unDefinedRoute();
      }
    } catch (e) {
      debugPrint('Error in RouteGenerator: $e');
      return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "Page Not Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginView()),
                    );
                  },
                  child: Text('Go to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
