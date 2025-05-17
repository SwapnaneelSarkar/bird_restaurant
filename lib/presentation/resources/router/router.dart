// lib/presentation/resources/router/router.dart

import 'package:bird_restaurant/presentation/screens/add_product/view.dart';
import 'package:bird_restaurant/presentation/screens/add_resturant_info/view.dart';
import 'package:bird_restaurant/presentation/screens/attributes/view.dart';
import 'package:bird_restaurant/presentation/screens/item_list/view.dart';
import 'package:bird_restaurant/presentation/screens/orders/view.dart';
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

  static const String attributes = '/attributes';
  static const String addProduct = '/addProduct';
  static const String orders = '/orders';
  static const String editMenu = '/editMenu';

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
          return MaterialPageRoute(builder: (_) => const SplashView());
          
        case Routes.signin:
          return MaterialPageRoute(builder: (_) => const LoginView());

        case Routes.otp:
          final String? phoneNumber = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => OtpView(mobileNumber: phoneNumber),
            settings: routeSettings, 
          );

        case Routes.detailsAdd:
          return MaterialPageRoute(builder: (_) => const RestaurantDetailsAddView());

        case Routes.detailsAdd2:
          return MaterialPageRoute(builder: (_) => const RestaurantCategoryView());

        case Routes.detailsAdd3:
          return MaterialPageRoute(builder: (_) => const RestaurantDocumentsSubmitView());

        case Routes.applicationStatus:
          final String? mobileNumber = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => ApplicationStatusView(mobileNumber: mobileNumber ?? ''),
            settings: routeSettings,
          );

        case Routes.profile:
          return MaterialPageRoute(builder: (_) => const RestaurantProfileView());

        case Routes.homePage:
          return MaterialPageRoute(builder: (_) => const HomeView());

        case Routes.attributes:
          return MaterialPageRoute(builder: (_) => const AttributesScreen());

        case Routes.addProduct:
          return MaterialPageRoute(builder: (_) => const AddProductScreen());

        case Routes.orders:
          return MaterialPageRoute(builder: (_) => const OrdersScreen());

        case Routes.editMenu:
          return MaterialPageRoute(builder: (_) => const EditMenuView());
        

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
