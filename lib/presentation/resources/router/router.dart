// lib/presentation/resources/router/router.dart - FIXED VERSION

import 'package:bird_restaurant/presentation/partner_selection/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/auth_success/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/otp/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/signin/view.dart';
import 'package:bird_restaurant/presentation/screens/add_product/view.dart';
import 'package:bird_restaurant/presentation/screens/add_resturant_info/view.dart';
import 'package:bird_restaurant/presentation/screens/attributes/view.dart';
import 'package:bird_restaurant/presentation/screens/chat/view.dart';
import 'package:bird_restaurant/presentation/screens/chat_list/view.dart';
import 'package:bird_restaurant/presentation/screens/item_list/view.dart';
import 'package:bird_restaurant/presentation/screens/orders/view.dart';
import 'package:bird_restaurant/presentation/screens/plans/view.dart';
import 'package:bird_restaurant/presentation/screens/reviewPage/view.dart';
import 'package:bird_restaurant/presentation/screens/signin/view.dart';
import 'package:bird_restaurant/presentation/screens/privacy_policy/view.dart';
import 'package:bird_restaurant/presentation/screens/terms_conditions/view.dart';
import 'package:bird_restaurant/presentation/screens/contact_us/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/dashboard/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/profile/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/onboarding/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/order_details/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/chat_services.dart';
import '../../screens/application_status/view.dart';
import '../../screens/chat/bloc.dart';
import '../../screens/homePage/view.dart';
import '../../screens/otp_screen/view.dart';
import '../../screens/restaurant_details_3/view.dart';
import '../../screens/restaurant_profile/view.dart';
import '../../screens/resturant_details_2/view.dart';
import '../../screens/splashScreen/view.dart';

class Routes {
  static const String splash = '/';
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
  static const String plan = '/plan';
  static const String chat = '/chat';
  static const String chatList = '/chatList';
  static const String reviews = '/reviews';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String contact = '/contact';

  static const String partnerSelection = '/partnerSelection';

  static const String deliveryPartnerSignin = '/delivery-partner-signin';
  static const String deliveryPartnerOtp = '/delivery-partner-otp';
  static const String deliveryPartnerAuthSuccess = '/delivery-partner-auth-success';
  static const String deliveryPartnerOnboarding = '/delivery-partner-onboarding';

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

        // SUBSCRIPTION-PROTECTED ROUTES - REMOVED SubscriptionProtectedWidget
        case Routes.attributes:
          return MaterialPageRoute(
            builder: (_) => const AttributesScreen(),
            settings: routeSettings,
          );

        case Routes.addProduct:
          return MaterialPageRoute(
            builder: (_) => const AddProductScreen(),
            settings: routeSettings,
          );

        case Routes.orders:
          return MaterialPageRoute(
            builder: (_) => const OrdersScreen(),
            settings: routeSettings,
          );

        case Routes.editMenu:
          return MaterialPageRoute(
            builder: (_) => const EditMenuView(),
            settings: routeSettings,
          );

        case Routes.plan:
          return MaterialPageRoute(builder: (_) => const PlanSelectionView());
        
        case Routes.reviews:
          return MaterialPageRoute(
            builder: (_) => const ReviewsView(partnerId: ''),
            settings: routeSettings,
          );

        case Routes.chat:
          final String? orderId = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => BlocProvider<ChatBloc>(
              create: (context) => ChatBloc(chatService: PollingChatService()),
              child: ChatView(orderId: orderId ?? ''),
            ),
            settings: routeSettings,
          );

        case Routes.chatList:
          return MaterialPageRoute(
            builder: (_) => const ChatListView(),
            settings: routeSettings,
          );

        // NON-SUBSCRIPTION ROUTES
        case Routes.privacy:
          return MaterialPageRoute(
            builder: (_) => const PrivacyPolicyView(),
            settings: routeSettings,
          );

        case Routes.terms:
          return MaterialPageRoute(
            builder: (_) => const TermsConditionsView(),
            settings: routeSettings,
          );

        case Routes.contact:
          return MaterialPageRoute(
            builder: (_) => const ContactUsView(),
            settings: routeSettings,
          );

        case Routes.partnerSelection:
          return MaterialPageRoute(builder: (_) => const PartnerSelectionView());

        case Routes.deliveryPartnerSignin:
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerSigninView());

        case Routes.deliveryPartnerOtp:
          final String? phoneNumber = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => DeliveryPartnerOtpView(mobileNumber: phoneNumber),
            settings: routeSettings,
          );

        case Routes.deliveryPartnerAuthSuccess:
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerDashboardView());

        case Routes.deliveryPartnerOnboarding:
          final args = routeSettings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => DeliveryPartnerOnboardingView(
              deliveryPartnerId: args?['deliveryPartnerId'],
              phone: args?['phone'],
            ),
            settings: routeSettings,
          );

        case '/deliveryPartnerProfile':
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerProfileView());

        case '/deliveryPartnerOrderDetails':
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerOrderDetailsView());

        default:
          return unDefinedRoute();
      }
    } catch (e) {
      debugPrint('❌ Route generation error for route $name: $e');
      return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Route Not Found'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The requested page could not be found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}