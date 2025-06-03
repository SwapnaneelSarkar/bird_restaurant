// lib/presentation/home/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../constants/api_constants.dart';
import '../../../ui_components/universal_widget/nav_bar.dart';
import '../../resources/colors.dart';
import '../chat/view.dart';

import '../chat_list/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'sidebar/side_bar_opener.dart';
import 'sidebar/sidebar_drawer.dart';
import 'state.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late AnimationController _pageTransitionController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      
      if (index == 1) {
        // Navigate to chat list instead of showing chat content in PageView
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ChatListView(),
          ),
        ).then((_) {
          // Reset to home tab when returning from chat list
          setState(() {
            _selectedIndex = 0;
          });
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      } else {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // Handle restaurant data for sidebar
            String? restaurantName;
            String? restaurantSlogan;
            String? restaurantImageUrl;
            
            if (state is HomeLoaded && state.restaurantData != null) {
              restaurantName = state.restaurantData!['restaurant_name'] as String?;
              restaurantSlogan = state.restaurantData!['address'] as String?;
              
              // Get restaurant image URL - path based on your API response structure
              if (state.restaurantData!['restaurant_photos'] != null) {
                var photos = state.restaurantData!['restaurant_photos'];
                if (photos is List && photos.isNotEmpty) {
                  restaurantImageUrl = photos[0];
                } else if (photos is String) {
                  restaurantImageUrl = photos;
                }
              }
              
              // Alternative fields to check for images
              if (restaurantImageUrl == null && state.restaurantData!['logo_url'] != null) {
                restaurantImageUrl = state.restaurantData!['logo_url'] as String?;
              }
              
              // If we found an image URL, ensure it's a complete URL
              if (restaurantImageUrl != null && !restaurantImageUrl.startsWith('http')) {
                restaurantImageUrl = '${ApiConstants.baseUrl}/$restaurantImageUrl';
              }
            }
            
            return SidebarDrawer(
              activePage: 'home',
              restaurantName: restaurantName,
              restaurantSlogan: restaurantSlogan,
              restaurantImageUrl: restaurantImageUrl,
            );
          },
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
            padding: const EdgeInsets.only(left: 8.0),
            child: SvgPicture.asset(
              'assets/svg/logo_text.svg',
              height: 30,
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
                      return const Center(child: CircularProgressIndicator());
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
                                context.read<HomeBloc>().add(LoadHomeData());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                
                // Chats content
                const ChatView(orderId: '',),
              ],
            ),
            
            // Bottom Navigation
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
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
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
                      context.read<HomeBloc>().add(ToggleOrderAcceptance(value));
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
                  child: _buildStatCard(
                    'Orders',
                    state.ordersCount.toString(),
                    Colors.orange[50]!,
                    Icons.shopping_bag_outlined,
                    Colors.orange[300]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Products',
                    state.productsCount.toString(),
                    Colors.amber[50]!,
                    Icons.restaurant_menu,
                    Colors.amber[300]!,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats Row 2
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tags',
                    state.tagsCount.toString(),
                    Colors.green[50]!,
                    Icons.local_offer_outlined,
                    Colors.green[300]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    state.rating.toString(),
                    Colors.yellow[50]!,
                    Icons.star_border,
                    Colors.yellow[600]!,
                  ),
                ),
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
  
  Widget _buildSalesChart(List<Map<String, dynamic>> salesData) {
    final List<FlSpot> spots = salesData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['sales'].toDouble());
    }).toList();
    
    final List<String> days = salesData.map((data) => data['day'] as String).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 300,
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
              interval: 300,
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
}