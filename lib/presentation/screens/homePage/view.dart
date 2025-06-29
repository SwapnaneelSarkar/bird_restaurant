// lib/presentation/home/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../constants/api_constants.dart';
import '../../../ui_components/universal_widget/nav_bar.dart';
import '../../../ui_components/shimmer_loading.dart';
import '../../../ui_components/subscription_reminder_dialog.dart';
import '../../../ui_components/pending_subscription_dialog.dart';
import '../../resources/colors.dart';
import '../../resources/router/router.dart';
import '../chat/view.dart';
import '../reviewPage/view.dart';

import '../chat_list/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'sidebar/side_bar_opener.dart';
import 'sidebar/sidebar_drawer.dart';
import 'state.dart';
import '../../../models/partner_summary_model.dart';
import '../../../services/restaurant_info_service.dart';
import '../../../services/subscription_plans_service.dart';
import '../../../services/token_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final AnimationController _pageTransitionController;
  late final PageController _pageController;
  late final HomeBloc _homeBloc;
  
  // Restaurant info state
  Map<String, String>? _restaurantInfo;
  bool _isRestaurantInfoLoaded = false;
  
  // Subscription state
  bool _hasCheckedSubscription = false;
  bool _hasShownSubscriptionDialog = false;

  @override
  void initState() {
    super.initState();
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController();
    
    // Create HomeBloc once in initState
    _homeBloc = HomeBloc();
    
    // Load data only once when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeBloc.add(LoadHomeData());
      _loadRestaurantInfo();
      _checkSubscriptionStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeBloc.add(RefreshHomeData());
      }
    });
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _pageController.dispose();
    _homeBloc.close(); // Properly dispose the BLoC
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      
      if (index == 1) {
        // Instead of navigating to a new route, just animate to the chat page
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Navigation methods for stat cards
  void _navigateToOrders(BuildContext context) {
    try {
      Navigator.pushNamed(context, Routes.orders);
    } catch (e) {
      // If route doesn't exist, show coming soon message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders page - Coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToProducts(BuildContext context) {
    try {
      Navigator.pushNamed(context, Routes.editMenu);
    } catch (e) {
      // If route doesn't exist, show coming soon message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products page - Coming soon!'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  void _navigateToReviews(BuildContext context, String? partnerId, String? restaurantName) {
    if (partnerId != null && partnerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewsView(
            partnerId: partnerId,
            partnerName: restaurantName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partner ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      // Force refresh from API to get the latest restaurant info
      final info = await RestaurantInfoService.refreshRestaurantInfo();
      if (mounted) {
        setState(() {
          _restaurantInfo = info;
          _isRestaurantInfoLoaded = true;
        });
        debugPrint('🔄 HomePage: Loaded restaurant info - Name: ${info['name']}, Slogan: ${info['slogan']}, Image: ${info['imageUrl']}');
      }
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscriptionStatus = await SubscriptionPlansService.getSubscriptionStatusForReminder();
      
      if (mounted && subscriptionStatus != null) {
        final hasExpiredPlan = subscriptionStatus['hasExpiredPlan'] as bool;
        final expiredPlanName = subscriptionStatus['expiredPlanName'] as String?;
        final hasPendingSubscription = subscriptionStatus['hasPendingSubscription'] as bool? ?? false;
        final pendingPlanName = subscriptionStatus['pendingPlanName'] as String?;
        
        debugPrint('Subscription dialog check: hasExpiredPlan=$hasExpiredPlan, expiredPlanName=$expiredPlanName, hasPendingSubscription=$hasPendingSubscription, pendingPlanName=$pendingPlanName');
        // Show appropriate dialog based on subscription status
        if (hasPendingSubscription) {
          // Show pending subscription dialog
          _showPendingSubscriptionDialog(pendingPlanName);
        } else if (hasExpiredPlan) {
          // Show expired plan dialog
          _showSubscriptionReminderDialog(true, expiredPlanName);
        }
        
        setState(() {
          _hasCheckedSubscription = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      setState(() {
        _hasCheckedSubscription = true;
      });
    }
  }

  void _showSubscriptionReminderDialog(bool hasExpiredPlan, String? expiredPlanName) {
    if (_hasShownSubscriptionDialog) return;
    
    _hasShownSubscriptionDialog = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SubscriptionReminderDialog(
            hasExpiredPlan: hasExpiredPlan,
            expiredPlanName: expiredPlanName,
            onGoToPlans: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.plan);
            },
            onSkip: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    });
  }

  void _showPendingSubscriptionDialog(String? pendingPlanName) {
    if (_hasShownSubscriptionDialog) return;
    
    _hasShownSubscriptionDialog = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PendingSubscriptionDialog(
            planName: pendingPlanName ?? 'Subscription',
            onGoToHome: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
          // On home page, allow app to quit
          return true;
        } else {
          // On other pages, go to home page
          setState(() {
            _selectedIndex = 0;
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
          return false;
        }
      },
      child: BlocProvider.value(
        value: _homeBloc, // Use the existing BLoC instance
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.grey[50],
          drawer: SidebarDrawer(
            activePage: 'home',
            restaurantName: _restaurantInfo?['name'] ?? 'Restaurant',
            restaurantSlogan: _restaurantInfo?['slogan'] ?? 'Fine Dining',
            restaurantImageUrl: _restaurantInfo?['imageUrl'],
          ),
          appBar: _selectedIndex == 0 ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: SidebarOpener(
              scaffoldKey: _scaffoldKey,
              iconColor: Colors.black87,
              padding: const EdgeInsets.all(12),
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: Image.asset(
                'assets/svg/logo_text.png',
                height: 80,
                semanticLabel: 'Bird Partner Logo',
              ),
            ),
          ) : null,
          body: Stack(
            children: [
              // Page content
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  // Home content
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoading) {
                        return const ShimmerHomeContent();
                      } else if (state is HomeLoaded) {
                        return _buildHomeContent(context, state);
                      } else if (state is HomeError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.message,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _homeBloc.add(LoadHomeData()); // Use the instance variable
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      return const ShimmerHomeContent();
                    },
                  ),
                  // Chat content
                  const ChatListView(),
                ],
              ),
              // Bottom navigation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BottomNavigationWidget(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onBottomNavTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    // Get partner ID and restaurant name for navigation with null safety
    final String? partnerId = state.restaurantData?['partner_id']?.toString();
    final String? restaurantName = state.restaurantData?['restaurant_name']?.toString();

    // Validate critical data
    if (state.restaurantData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Restaurant data not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try refreshing the page',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _homeBloc.add(LoadHomeData());
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Accepting Orders Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accepting Orders',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Toggle to start accepting orders',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: state.isAcceptingOrders,
                    onChanged: (value) {
                      _homeBloc.add(ToggleOrderAcceptance(value));
                    },
                    activeColor: ColorManager.primary,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Stats Row 1
            Row(
              children: [
                Expanded(
                  child: _buildClickableStatCard(
                    'Orders',
                    state.ordersCount.toString(),
                    Colors.orange[50]!,
                    Icons.shopping_bag_outlined,
                    Colors.orange[300]!,
                    () => _navigateToOrders(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildClickableStatCard(
                    'Products',
                    state.productsCount.toString(),
                    Colors.amber[50]!,
                    Icons.restaurant_menu,
                    Colors.amber[300]!,
                    () => _navigateToProducts(context),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats Row 2 - Only Rating (maintaining original layout)
            Row(
              children: [
                Expanded(
                  child: _buildClickableStatCard(
                    'Rating',
                    state.rating.toString(),
                    Colors.yellow[50]!,
                    Icons.star_border,
                    Colors.yellow[600]!,
                    () => _navigateToReviews(context, partnerId, restaurantName),
                  ),
                ),
                const SizedBox(width: 16),
                // Empty space to maintain layout
                const Expanded(child: SizedBox()),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Product Sales Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Sales',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSalesChart(state.salesData),
                ),
              ],
            ),
            
            // Restaurant Information Section
            if (state.restaurantData != null) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurant Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${state.restaurantData?['restaurant_name'] ?? 'Not available'}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Address: ${state.restaurantData?['address'] ?? 'Not available'}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner: ${state.restaurantData?['owner_name'] ?? 'Not available'}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Partner ID: ${state.restaurantData?['partner_id'] ?? 'Not available'}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            // Extra bottom padding for navigation bar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Clickable stat card widget
  Widget _buildClickableStatCard(
    String title, 
    String value, 
    Color bgColor, 
    IconData icon, 
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSalesChart(List<Map<String, dynamic>> salesData) {
    final List<FlSpot> spots = salesData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['sales'].toDouble());
    }).toList();
    
    final List<String> days = salesData.map((data) => data['day'] as String).toList();
    
    // Calculate smart interval based on sales data range
    final double maxSales = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) : 0;
    final double minSales = spots.isNotEmpty ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) : 0;
    final double salesRange = maxSales - minSales;
    
    // Smart interval calculation based on sales range
    double interval = _calculateSmartInterval(salesRange, maxSales);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              },
              interval: interval,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= days.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: ColorManager.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: ColorManager.primary.withOpacity(0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final dayIndex = barSpot.x.toInt();
                final day = dayIndex >= 0 && dayIndex < days.length 
                    ? days[dayIndex] 
                    : '';
                return LineTooltipItem(
                  '$day: ${barSpot.y.toInt()}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Calculates smart interval for Y-axis based on sales range
  /// This ensures the graph looks pleasant with appropriate spacing
  double _calculateSmartInterval(double salesRange, double maxSales) {
    // If all sales are 0, use a small default interval
    if (maxSales == 0) return 100;
    
    // If sales range is very small, use a small interval
    if (salesRange <= 200) return 100;
    
    // For small ranges (200-500), use 200 interval
    if (salesRange <= 500) return 200;
    
    // For medium ranges (500-1000), use 300 interval
    if (salesRange <= 1000) return 300;
    
    // For larger ranges (1000-2000), use 500 interval
    if (salesRange <= 2000) return 500;
    
    // For even larger ranges (2000-5000), use 1000 interval
    if (salesRange <= 5000) return 1000;
    
    // For very large ranges (5000-10000), use 2000 interval
    if (salesRange <= 10000) return 2000;
    
    // For extremely large ranges (10000+), use 5000 interval
    if (salesRange <= 50000) return 5000;
    
    // For massive ranges (50000+), use 10000 interval
    return 10000;
  }
}