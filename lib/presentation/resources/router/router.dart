// lib/presentation/resources/router/router.dart - FIXED VERSION

import 'package:bird_restaurant/presentation/partner_selection/view.dart';

import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/otp/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/signin/view.dart';
import 'package:bird_restaurant/presentation/screens/add_product_from_catalog/view.dart';
import 'package:bird_restaurant/presentation/screens/update_product_from_catalog/view.dart';
import 'package:bird_restaurant/presentation/screens/conditional_add_product_wrapper.dart';
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
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/order_details/view.dart';
import 'package:bird_restaurant/presentation/screens/order_details/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/chat/view.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/chat/bloc.dart';
import 'package:bird_restaurant/services/delivery_partner_chat_service.dart';
import 'package:bird_restaurant/test/delivery_partner_chat_test.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partners/view.dart';
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
import 'package:bird_restaurant/presentation/screens/delivery_partners/bloc.dart';
import 'package:bird_restaurant/services/delivery_partners_service.dart';
import 'package:bird_restaurant/presentation/screens/delivery_partner_pages/profile/edit/view.dart';
import 'package:bird_restaurant/presentation/screens/order_action/view.dart';
import 'package:bird_restaurant/presentation/screens/order_action_result/view.dart';
import 'package:bird_restaurant/test/notification_debug_widget.dart';

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
  static const String addProductFromCatalog = '/addProductFromCatalog';
  static const String updateProductFromCatalog = '/updateProductFromCatalog';
  static const String orders = '/orders';
  static const String editMenu = '/editMenu';
  static const String plan = '/plan';
  static const String chat = '/chat';
  static const String chatList = '/chatList';
  static const String reviews = '/reviews';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String contact = '/contact';
  static const String deliveryPartners = '/deliveryPartners';
  static const String orderAction = '/orderAction';
  static const String orderActionResult = '/orderActionResult';
  static const String notificationDebug = '/notificationDebug';

  static const String partnerSelection = '/partnerSelection';

  static const String deliveryPartnerSignin = '/delivery-partner-signin';
  static const String deliveryPartnerOtp = '/delivery-partner-otp';
  static const String deliveryPartnerAuthSuccess = '/delivery-partner-auth-success';
  static const String deliveryPartnerDashboard = '/deliveryPartnerDashboard';
  static const String deliveryPartnerProfile = '/deliveryPartnerProfile';
  static const String deliveryPartnerOrderDetails = '/deliveryPartnerOrderDetails';
  static const String restaurantOrderDetails = '/restaurantOrderDetails';
  static const String deliveryPartnerChat = '/deliveryPartnerChat';
  static const String deliveryPartnerChatTest = '/deliveryPartnerChatTest';
  static const String deliveryPartnerProfileEdit = '/deliveryPartnerProfileEdit';

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
            builder: (_) => const ConditionalAddProductWrapper(),
            settings: routeSettings,
          );

        case Routes.addProductFromCatalog:
          return MaterialPageRoute(
            builder: (_) => const AddProductFromCatalogScreen(),
            settings: routeSettings,
          );

        case Routes.updateProductFromCatalog:
          return MaterialPageRoute(
            builder: (_) => const UpdateProductFromCatalogScreen(),
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
          final args = routeSettings.arguments;
          String orderId = '';
          bool isOrderActive = false;
          if (args is Map<String, dynamic>) {
            orderId = args['orderId'] ?? '';
            isOrderActive = args['isOrderActive'] ?? false;
          } else if (args is String) {
            orderId = args;
          }
          return MaterialPageRoute(
            builder: (_) => BlocProvider<ChatBloc>(
              create: (context) => ChatBloc(chatService: PollingChatService()),
              child: ChatView(orderId: orderId, isOrderActive: isOrderActive),
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

        case Routes.deliveryPartnerDashboard:
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerDashboardView());

        case Routes.deliveryPartnerProfile:
          return MaterialPageRoute(builder: (_) => const DeliveryPartnerProfileView());

        case Routes.deliveryPartnerOrderDetails:
          return MaterialPageRoute(
            builder: (_) => DeliveryPartnerOrderDetailsView(),
            settings: routeSettings,
          );
        case Routes.restaurantOrderDetails:
          return MaterialPageRoute(
            builder: (_) => RestaurantOrderDetailsView(),
            settings: routeSettings,
          );

        case Routes.deliveryPartnerChat:
          final dynamic args = routeSettings.arguments;
          String orderId = '';
          VoidCallback? onOrderDelivered;
          
          if (args is String) {
            orderId = args;
          } else if (args is Map<String, dynamic>) {
            orderId = args['orderId'] ?? '';
            onOrderDelivered = args['onOrderDelivered'];
          }
          
          return MaterialPageRoute(
            builder: (_) => BlocProvider<DeliveryPartnerChatBloc>(
              create: (context) => DeliveryPartnerChatBloc(chatService: DeliveryPartnerChatService()),
              child: DeliveryPartnerChatView(
                orderId: orderId,
                isOrderActive: true,
                onOrderDelivered: onOrderDelivered,
              ),
            ),
            settings: routeSettings,
          );

        case Routes.deliveryPartnerChatTest:
          return MaterialPageRoute(
            builder: (_) => DeliveryPartnerChatTest(),
            settings: routeSettings,
          );

        case Routes.deliveryPartnerProfileEdit:
          final Map<String, dynamic>? profile = routeSettings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => DeliveryPartnerProfileEditView(profile: profile),
            settings: routeSettings,
          );

        case Routes.deliveryPartners:
          return MaterialPageRoute(
            builder: (_) => BlocProvider<DeliveryPartnersBloc>(
              create: (context) => DeliveryPartnersBloc(
                deliveryPartnersService: DeliveryPartnersService(),
              ),
              child: const DeliveryPartnersView(),
            ),
            settings: routeSettings,
          );

        case Routes.orderAction:
          final String? orderId = routeSettings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => OrderActionView(orderId: orderId ?? ''),
            settings: routeSettings,
          );

        case Routes.orderActionResult:
          final Map<String, dynamic>? args = routeSettings.arguments as Map<String, dynamic>?;
          final String orderId = args?['orderId'] as String? ?? '';
          final String action = args?['action'] as String? ?? '';
          final bool isSuccess = args?['isSuccess'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => OrderActionResultView(
              orderId: orderId,
              action: action,
              isSuccess: isSuccess,
            ),
            settings: routeSettings,
          );

        case Routes.notificationDebug:
          return MaterialPageRoute(
            builder: (_) => const NotificationDebugWidget(),
            settings: routeSettings,
          );

        case Routes.blank:
          return unDefinedRoute();

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