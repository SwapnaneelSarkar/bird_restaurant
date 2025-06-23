// lib/presentation/resources/router/router.dart - UPDATED WITH LEGAL PAGES

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
import 'package:bird_restaurant/presentation/screens/privacy_policy/view.dart'; // Add this import
import 'package:bird_restaurant/presentation/screens/terms_conditions/view.dart'; // Add this import
import 'package:bird_restaurant/presentation/screens/contact_us/view.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/chat_services.dart'; // Import polling service
import '../../../services/subscription_lock_service.dart';
import '../../../ui_components/subscription_lock_dialog.dart';
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
  static const String privacy = '/privacy'; // Add privacy route
  static const String terms = '/terms'; // Add terms route
  static const String contact = '/contact'; // Add contact route
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
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const AttributesScreen(),
            'Attributes Management',
            '/attributes',
          );

        case Routes.addProduct:
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const AddProductScreen(),
            'Add Product',
            '/addProduct',
          );

        case Routes.orders:
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const OrdersScreen(),
            'Orders Management',
            '/orders',
          );

        case Routes.editMenu:
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const EditMenuView(),
            'Products Management',
            '/editMenu',
          );

        case Routes.plan:
          return MaterialPageRoute(builder: (_) => const PlanSelectionView());
        
        case Routes.reviews:
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const ReviewsView(partnerId: '',),
            'Reviews',
            '/reviews',
          );

        case Routes.chat:
          final String? orderId = routeSettings.arguments as String?;
          return _createSubscriptionProtectedRoute(
            routeSettings,
            BlocProvider<ChatBloc>(
              create: (context) => ChatBloc(chatService: PollingChatService()), // Use polling service
              child: ChatView(orderId: orderId ?? ''),
            ),
            'Chat',
            '/chat',
          );

        case Routes.chatList:
          return _createSubscriptionProtectedRoute(
            routeSettings,
            const ChatListView(),
            'Chat List',
            '/chatList',
          );

        // Add new legal pages routes
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

        default:
          return unDefinedRoute();
      }
    } catch (e) {
      debugPrint('❌ Route generation error for route $name: $e');
      return unDefinedRoute();
    }
  }

  // Helper method to create subscription-protected routes
  static MaterialPageRoute _createSubscriptionProtectedRoute(
    RouteSettings routeSettings,
    Widget child,
    String pageName,
    String routeName,
  ) {
    return MaterialPageRoute(
      builder: (context) => SubscriptionProtectedWidget(
        child: child,
        pageName: pageName,
        routeName: routeName,
      ),
      settings: routeSettings,
    );
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

// Widget to handle subscription protection
class SubscriptionProtectedWidget extends StatefulWidget {
  final Widget child;
  final String pageName;
  final String routeName;

  const SubscriptionProtectedWidget({
    Key? key,
    required this.child,
    required this.pageName,
    required this.routeName,
  }) : super(key: key);

  @override
  State<SubscriptionProtectedWidget> createState() => _SubscriptionProtectedWidgetState();
}

class _SubscriptionProtectedWidgetState extends State<SubscriptionProtectedWidget> {
  bool _hasCheckedSubscription = false;
  bool _hasValidSubscription = false;
  bool _hasShownSubscriptionDialog = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final canAccess = await SubscriptionLockService.canAccessPage(widget.routeName);
      
      if (mounted) {
        setState(() {
          _hasValidSubscription = canAccess;
          _hasCheckedSubscription = true;
        });
        
        if (!canAccess && !_hasShownSubscriptionDialog) {
          _showSubscriptionDialog();
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _hasCheckedSubscription = true;
          _hasValidSubscription = false;
        });
        if (!_hasShownSubscriptionDialog) {
          _showSubscriptionDialog();
        }
      }
    }
  }

  void _showSubscriptionDialog() {
    if (_hasShownSubscriptionDialog) return;
    
    _hasShownSubscriptionDialog = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final subscriptionStatus = await SubscriptionLockService.getSubscriptionStatus();
          
          if (mounted) {
            if (subscriptionStatus['status'] == 'PENDING') {
              // Show pending subscription dialog - NO ACCESS ALLOWED
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => PendingSubscriptionLockDialog(
                  pageName: widget.pageName,
                  planName: subscriptionStatus['planName'] ?? 'Subscription',
                  endDate: subscriptionStatus['endDate'] ?? 'Unknown',
                  onGoBack: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
              );
            } else {
              // Show subscription required dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SubscriptionLockDialog(
                  pageName: widget.pageName,
                  onGoToPlans: () {
                    Navigator.of(context).pop();
                    // Use safe navigation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        try {
                          Navigator.of(context).pushNamed('/plan');
                        } catch (e) {
                          debugPrint('Error navigating to plans from router dialog: $e');
                          // Fallback navigation
                          try {
                            Navigator.of(context).pushNamedAndRemoveUntil('/plan', (route) => false);
                          } catch (fallbackError) {
                            debugPrint('Fallback navigation also failed: $fallbackError');
                          }
                        }
                      }
                    });
                  },
                  onGoBack: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error showing subscription dialog: $e');
          // Fallback to basic subscription dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => SubscriptionLockDialog(
                pageName: widget.pageName,
                onGoToPlans: () {
                  Navigator.of(context).pop();
                  // Use safe navigation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      try {
                        Navigator.of(context).pushNamed('/plan');
                      } catch (e) {
                        debugPrint('Error navigating to plans from router dialog: $e');
                        // Fallback navigation
                        try {
                          Navigator.of(context).pushNamedAndRemoveUntil('/plan', (route) => false);
                        } catch (fallbackError) {
                          debugPrint('Fallback navigation also failed: $fallbackError');
                        }
                      }
                    }
                  });
                },
                onGoBack: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedSubscription) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.pageName),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFFE17A47),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking subscription status...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasValidSubscription) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.pageName),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: const Color(0xFFE17A47).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Subscription Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please subscribe to access ${widget.pageName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/plan');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE17A47),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}