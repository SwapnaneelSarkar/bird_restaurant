// lib/presentation/plan_selection/view/plan_selection_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/plan_card.dart';
import '../../../ui_components/payment_method_dialog.dart';
import '../../../ui_components/subscription_success_dialog.dart';
import '../../../ui_components/active_plan_dialog.dart';
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
        });
        return;
      }

      final activeSubscription = await SubscriptionPlansService.getActiveSubscription(partnerId);
      
      if (activeSubscription != null) {
        // User has active subscription, show dialog and redirect
        if (mounted) {
          _showActivePlanDialog(activeSubscription);
        }
      } else {
        // No active subscription, allow access to plans
        setState(() {
          _hasCheckedSubscription = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      // On error, allow access to plans
      setState(() {
        _hasCheckedSubscription = true;
      });
    }
  }

  void _showActivePlanDialog(Map<String, dynamic> activeSubscription) {
    final planName = activeSubscription['plan_name']?.toString() ?? 'Unknown Plan';
    final planDescription = activeSubscription['plan_description']?.toString() ?? 'No description available';
    final endDate = activeSubscription['end_date']?.toString() ?? 'Unknown';
    final status = activeSubscription['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    
    // Format the end date for display
    String formattedEndDate = endDate;
    try {
      final date = DateTime.parse(endDate);
      formattedEndDate = '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      debugPrint('Error parsing end date: $e');
    }

    // Determine dialog title and message based on status
    String dialogTitle;
    String dialogMessage;
    
    if (status == 'PENDING') {
      dialogTitle = 'Subscription Pending';
      dialogMessage = 'Your subscription is currently pending approval. You will be notified once it is activated.';
    } else {
      dialogTitle = 'Active Subscription';
      dialogMessage = 'You already have an active subscription.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivePlanDialog(
        planName: planName,
        planDescription: planDescription,
        endDate: formattedEndDate,
        dialogTitle: dialogTitle,
        dialogMessage: dialogMessage,
        onGoToHome: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: SidebarDrawer(
        activePage: 'plan',
        restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
        restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Choose your plan',
        restaurantImageUrl: _restaurantInfo?['imageUrl'],
      ),
      appBar: AppBar(
        leading: null,
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
            Text(
              'Subscription Plans',
              style: TextStyle(
                fontFamily: FontConstants.fontFamily,
                fontSize: FontSize.s18,
                fontWeight: FontWeightManager.semiBold,
                color: ColorManager.black,
              ),
            ),
          ],
        ),
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
                        Text(
                          'Choose Your Plan',
                          style: TextStyle(
                            fontSize: FontSize.s22,
                            fontWeight: FontWeightManager.bold,
                            color: ColorManager.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select the best plan for your business',
                          style: TextStyle(
                            fontSize: FontSize.s16,
                            color: ColorManager.textGrey,
                          ),
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
    );
  }
}

