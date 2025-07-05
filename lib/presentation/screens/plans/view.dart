// lib/presentation/plan_selection/view/plan_selection_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/plan_card.dart';
import '../../../ui_components/payment_method_dialog.dart';
import '../../../ui_components/subscription_success_dialog.dart';
import '../../../ui_components/subscription_management_dialog.dart';
import '../../../models/plan_model.dart';
import '../../../services/subscription_plans_service.dart';
import '../../../services/token_service.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../../services/restaurant_info_service.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:bird_restaurant/constants/api_constants.dart';
import 'package:bird_restaurant/utils/time_utils.dart';

class PlanSelectionView extends StatelessWidget {
  const PlanSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanSelectionBloc()..add(LoadPlansEvent()),
      child: const PlanSelectionScreen(),
    );
  }
}

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, String>? _restaurantInfo;
  String? _errorMessage;
  bool _hasCheckedSubscription = false;
  bool _hasValidSubscription = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
    _checkActiveSubscription();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final info = await RestaurantInfoService.getRestaurantInfo();
      setState(() {
        _restaurantInfo = info;
      });
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
      setState(() {
        _errorMessage = 'Error loading restaurant info: $e';
      });
    }
  }

  Future<void> _checkActiveSubscription() async {
    try {
      final partnerId = await TokenService.getUserId();
      if (partnerId == null) {
        debugPrint('No partner ID found, allowing access to plans');
        setState(() {
          _hasCheckedSubscription = true;
          _hasValidSubscription = false;
        });
        return;
      }

      final activeSubscription = await SubscriptionPlansService.getActiveSubscription(partnerId);
      
      if (activeSubscription != null) {
        // User has active subscription, allow them to stay on plans page
        setState(() {
          _hasCheckedSubscription = true;
          _hasValidSubscription = true;
        });
        // Don't automatically show dialog - let user choose to view their subscription
      } else {
        // No active subscription, allow access to plans
        setState(() {
          _hasCheckedSubscription = true;
          _hasValidSubscription = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      // On error, allow access to plans
      setState(() {
        _hasCheckedSubscription = true;
        _hasValidSubscription = false;
      });
    }
  }

  void _showActivePlanDialog(Map<String, dynamic> activeSubscription) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionManagementDialog(
        subscriptionData: activeSubscription,
        onViewPlans: () {
          Navigator.of(context).pop(); // Close the dialog
          // Stay on the plans page to view other plans
        },
        onGoToHome: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        },
        onRenewSubscription: () {
          Navigator.of(context).pop(); // Close the dialog
          // Stay on the plans page to renew
        },
        onUpgradeSubscription: () {
          Navigator.of(context).pop(); // Close the dialog
          // Stay on the plans page to upgrade
        },
      ),
    );
  }

  void _openSidebar() {
    try {
      _scaffoldKey.currentState?.openDrawer();
    } catch (e) {
      debugPrint('Error opening sidebar: $e');
    }
  }

  void _showPaymentMethodDialog(BuildContext context, PlanModel plan) {
    debugPrint('PlanSelectionView: Showing payment method dialog for plan: ${plan.title}');
    
    // Get the bloc reference before showing dialog
    final bloc = context.read<PlanSelectionBloc>();
    
    // Show confirmation dialog for users with active subscriptions
    if (_hasValidSubscription) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.upgrade,
                color: ColorManager.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Upgrade Subscription',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'You are about to upgrade to the ${plan.title} plan for ₹${plan.price.toStringAsFixed(2)}/month. This will replace your current subscription.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentMethodDialogInternal(context, plan, bloc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _showPaymentMethodDialogInternal(context, plan, bloc);
    }
  }

  void _showPaymentMethodDialogInternal(BuildContext context, PlanModel plan, PlanSelectionBloc bloc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentMethodDialog(
        planName: plan.title,
        amount: plan.price,
        onPaymentMethodSelected: (paymentMethod) {
          debugPrint('PlanSelectionView: Payment method selected: $paymentMethod');
          _createSubscription(context, plan, paymentMethod, bloc);
        },
      ),
    );
  }

  void _createSubscription(BuildContext context, PlanModel plan, String paymentMethod, PlanSelectionBloc bloc) {
    debugPrint('PlanSelectionView: Creating subscription for plan ${plan.id} with payment method $paymentMethod');
    try {
      bloc.add(
        CreateSubscriptionEvent(
          planId: plan.id,
          amount: plan.price,
          paymentMethod: paymentMethod,
        ),
      );
      debugPrint('PlanSelectionView: CreateSubscriptionEvent dispatched successfully');
    } catch (e) {
      debugPrint('PlanSelectionView: Error dispatching CreateSubscriptionEvent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, Map<String, dynamic> subscriptionData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionSuccessDialog(
        subscriptionData: subscriptionData,
        onGoToHome: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking subscription
    if (!_hasCheckedSubscription) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Subscription Plans'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: ColorManager.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Checking subscription status...',
                style: TextStyle(
                  fontSize: FontSize.s16,
                  color: ColorManager.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if there's a critical error
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'An error occurred',
                  style: TextStyle(
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.bold,
                    color: ColorManager.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: FontSize.s14,
                    color: ColorManager.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _loadRestaurantInfo();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Allow normal back behavior for all users
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        drawer: SidebarDrawer(
          activePage: 'plan',
          restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
          restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Choose your plan',
          restaurantImageUrl: _restaurantInfo?['imageUrl'],
        ),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _openSidebar,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.menu_rounded,
                    color: Colors.black87,
                    size: 24.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Subscription Plans',
                  style: TextStyle(
                    fontFamily: FontConstants.fontFamily,
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (_hasValidSubscription)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: () async {
                    try {
                      final partnerId = await TokenService.getUserId();
                      if (partnerId != null) {
                        final activeSubscription = await SubscriptionPlansService.getActiveSubscription(partnerId);
                        if (activeSubscription != null && mounted) {
                          _showActivePlanDialog(activeSubscription);
                        }
                      }
                    } catch (e) {
                      debugPrint('Error showing subscription details: $e');
                    }
                  },
                  icon: Icon(
                    Icons.subscriptions,
                    color: ColorManager.primary,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<PlanSelectionBloc, PlanSelectionState>(
            listener: (context, state) {
              try {
                if (state is SubscriptionCreated) {
                  _showSuccessDialog(context, state.subscriptionData);
                } else if (state is SubscriptionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('PlanSelectionView: Error in bloc listener: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            builder: (context, state) {
              // Add debug logging
              debugPrint('PlanSelectionView: Current state is ${state.runtimeType}');
              
              if (state is PlanSelectionLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primary,
                  ),
                );
              }
              
              if (state is PlanSelectionError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: FontSize.s18,
                          fontWeight: FontWeightManager.bold,
                          color: ColorManager.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          color: ColorManager.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              if (state is PlanSelectionLoaded || state is SubscriptionCreating || state is SubscriptionError || state is SubscriptionCreated) {
                List<PlanModel> plans;
                String? selectedPlanId;
                
                try {
                  if (state is PlanSelectionLoaded) {
                    plans = state.plans;
                    selectedPlanId = state.selectedPlanId;
                    debugPrint('PlanSelectionView: Loaded ${plans.length} plans');
                  } else if (state is SubscriptionCreating) {
                    plans = state.plans;
                    selectedPlanId = state.selectedPlanId;
                    debugPrint('PlanSelectionView: Creating subscription with ${plans.length} plans');
                  } else if (state is SubscriptionError) {
                    plans = state.plans;
                    selectedPlanId = state.selectedPlanId;
                    debugPrint('PlanSelectionView: Subscription error with ${plans.length} plans');
                  } else if (state is SubscriptionCreated) {
                    plans = state.plans;
                    selectedPlanId = state.selectedPlanId;
                    debugPrint('PlanSelectionView: Subscription created with ${plans.length} plans');
                  } else {
                    plans = [];
                    selectedPlanId = null;
                    debugPrint('PlanSelectionView: Unknown state, using empty plans');
                  }
                } catch (e) {
                  debugPrint('PlanSelectionView: Error accessing state data: $e');
                  plans = [];
                  selectedPlanId = null;
                }
                
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show current subscription status if user has one
                          if (_hasValidSubscription) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorManager.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: ColorManager.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'You have an active subscription',
                                          style: TextStyle(
                                            fontSize: FontSize.s16,
                                            fontWeight: FontWeightManager.semiBold,
                                            color: ColorManager.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap the subscription icon in the top right to view details',
                                          style: TextStyle(
                                            fontSize: FontSize.s14,
                                            color: ColorManager.textGrey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              fontSize: FontSize.s22,
                              fontWeight: FontWeightManager.bold,
                              color: ColorManager.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasValidSubscription 
                              ? 'View other plans or upgrade your current subscription'
                              : 'Select the best plan for your business',
                            style: TextStyle(
                              fontSize: FontSize.s16,
                              color: ColorManager.textGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 24),
                          
                          // Plans list
                          ...plans.map((plan) {
                            try {
                              // Validate plan data before rendering
                              if (plan.id.isEmpty || plan.title.isEmpty) {
                                debugPrint('PlanSelectionView: Invalid plan data detected: ${plan.id} - ${plan.title}');
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Invalid plan data',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                );
                              }
                              
                              return PlanCard(
                                plan: plan,
                                isSelected: selectedPlanId == plan.id,
                                onTap: () {
                                  try {
                                    // Get bloc reference before showing dialog
                                    final bloc = context.read<PlanSelectionBloc>();
                                    
                                    bloc.add(
                                      SelectPlanEvent(plan.id),
                                    );
                                    // Show payment method dialog
                                    _showPaymentMethodDialog(context, plan);
                                  } catch (e) {
                                    debugPrint('PlanSelectionView: Error handling plan tap: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error selecting plan: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              );
                            } catch (e) {
                              debugPrint('PlanSelectionView: Error rendering plan card: $e');
                              return Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Error loading plan: $e',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    ),
                    
                    // Loading overlay for subscription creation
                    if (state is SubscriptionCreating)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: ColorManager.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Creating Subscription...',
                                  style: TextStyle(
                                    fontSize: FontSize.s16,
                                    fontWeight: FontWeightManager.medium,
                                    color: ColorManager.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              
              // Default case - should not reach here but just in case
              return const Center(
                child: Text('No plans available'),
              );
            },
          ),
        ),
      ),
    );
  }
}

