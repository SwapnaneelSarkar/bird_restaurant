import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../models/order_model.dart';
import '../constants/enums.dart';
import '../presentation/screens/orders/state.dart';

class OrderSummarySlider extends StatefulWidget {
  final OrderStats allTimeStats;
  final TodayOrderSummaryData? todayStats;
  final void Function(OrderStatus, {bool filterByToday}) onFilterTap;
  final OrderStatus? selectedStatus;
  final bool filterByToday;

  const OrderSummarySlider({
    Key? key,
    required this.allTimeStats,
    this.todayStats,
    required this.onFilterTap,
    this.selectedStatus,
    this.filterByToday = false,
  }) : super(key: key);

  @override
  State<OrderSummarySlider> createState() => _OrderSummarySliderState();
}

class _OrderSummarySliderState extends State<OrderSummarySlider>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenHeight < 700;
    
    final tabBarHeight = isTablet ? 56.0 : 48.0;
    final containerHeight = isSmallScreen ? 325.0 : 365.0;
    final cardSpacing = isTablet ? 16.0 : 12.0;
    final rowSpacing = isSmallScreen ? 8.0 : 12.0;
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isTablet ? 24.0 : 20.0,
        horizontal: isTablet ? 16.0 : 8.0,
      ),
      child: Column(
        children: [
          // Enhanced Tab Bar
          Container(
            height: tabBarHeight,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: ColorManager.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(
                fontSize: isTablet ? FontSize.s16 : FontSize.s14,
                fontWeight: FontWeightManager.semiBold,
                fontFamily: FontFamily.Montserrat,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isTablet ? FontSize.s16 : FontSize.s14,
                fontWeight: FontWeightManager.medium,
                fontFamily: FontFamily.Montserrat,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'All Time Stats'),
                Tab(text: 'Today\'s Stats'),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 28.0 : 24.0),
          
          // Enhanced Tab Content with responsive height
          SizedBox(
            height: containerHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTimeStats(cardSpacing, rowSpacing),
                _buildTodayStats(cardSpacing, rowSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeStats(double cardSpacing, double rowSpacing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // First Row - 3 Cards (Total Orders, Pending, Confirmed)
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'Total Orders',
                  count: widget.allTimeStats.total,
                  iconColor: Colors.indigo,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => widget.onFilterTap(OrderStatus.all, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.all && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatsCard(
                  title: 'Pending',
                  count: widget.allTimeStats.pending,
                  iconColor: Colors.orange,
                  icon: Icons.access_time,
                  onTap: () => widget.onFilterTap(OrderStatus.pending, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.pending && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatsCard(
                  title: 'Confirmed',
                  count: widget.allTimeStats.confirmed,
                  iconColor: Colors.blue,
                  icon: Icons.check_circle_outline,
                  onTap: () => widget.onFilterTap(OrderStatus.confirmed, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.confirmed && !widget.filterByToday,
                ),
              ),
            ],
          ),
          
          SizedBox(height: rowSpacing),
          
          // Second Row - 3 Cards (Preparing, Ready, Out for Delivery)
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'Preparing',
                  count: widget.allTimeStats.preparing,
                  iconColor: Colors.purple,
                  icon: Icons.restaurant,
                  onTap: () => widget.onFilterTap(OrderStatus.preparing, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.preparing && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatsCard(
                  title: 'Ready',
                  count: widget.allTimeStats.readyForDelivery,
                  iconColor: Colors.green,
                  icon: Icons.done_all,
                  onTap: () => widget.onFilterTap(OrderStatus.readyForDelivery, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.readyForDelivery && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatsCard(
                  title: 'Out for Delivery',
                  count: widget.allTimeStats.outForDelivery,
                  iconColor: Colors.cyan,
                  icon: Icons.delivery_dining,
                  onTap: () => widget.onFilterTap(OrderStatus.outForDelivery, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.outForDelivery && !widget.filterByToday,
                ),
              ),
            ],
          ),
          
          SizedBox(height: rowSpacing),
          
          // Third Row - 2 Cards (Delivered, Cancelled)
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'Delivered',
                  count: widget.allTimeStats.delivered,
                  iconColor: Colors.teal,
                  icon: Icons.check_circle,
                  onTap: () => widget.onFilterTap(OrderStatus.delivered, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.delivered && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatsCard(
                  title: 'Cancelled',
                  count: widget.allTimeStats.cancelled,
                  iconColor: Colors.red,
                  icon: Icons.cancel_outlined,
                  onTap: () => widget.onFilterTap(OrderStatus.cancelled, filterByToday: false),
                  isSelected: widget.selectedStatus == OrderStatus.cancelled && !widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              // Empty space to maintain alignment
              const Expanded(child: SizedBox()),
            ],
          ),
          
          const SizedBox(height: 16), // Bottom padding to ensure last row is visible
        ],
      ),
    );
  }

  Widget _buildTodayStats(double cardSpacing, double rowSpacing) {
    if (widget.todayStats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No data available for today',
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for today\'s statistics',
              style: TextStyle(
                fontSize: FontSize.s14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final todaySummary = widget.todayStats!.summary;
    final statusBreakdown = todaySummary.statusBreakdown;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // First Row - 3 Cards (Total Orders, Total Revenue, Average Order Value)
          Row(
            children: [
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Total Orders',
                  value: todaySummary.totalOrders.toString(),
                  subtitle: 'Today',
                  iconColor: Colors.indigo,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => widget.onFilterTap(OrderStatus.all, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.all && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Total Revenue',
                  value: '₹${todaySummary.totalRevenue.toStringAsFixed(2)}',
                  subtitle: 'Today',
                  iconColor: Colors.green,
                  icon: Icons.attach_money,
                  onTap: () => widget.onFilterTap(OrderStatus.all, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.all && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Avg Order Value',
                  value: '₹${todaySummary.averageOrderValue.toStringAsFixed(2)}',
                  subtitle: 'Today',
                  iconColor: Colors.amber,
                  icon: Icons.analytics,
                  onTap: () => widget.onFilterTap(OrderStatus.all, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.all && widget.filterByToday,
                ),
              ),
            ],
          ),
          
          SizedBox(height: rowSpacing),
          
          // Second Row - 3 Cards (Completion Rate, Cancellation Rate, Confirmed)
          Row(
            children: [
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Completion Rate',
                  value: '${todaySummary.completionRate.toStringAsFixed(1)}%',
                  subtitle: 'Today',
                  iconColor: Colors.teal,
                  icon: Icons.check_circle,
                  onTap: () => widget.onFilterTap(OrderStatus.delivered, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.delivered && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Cancellation Rate',
                  value: '${todaySummary.cancellationRate.toStringAsFixed(1)}%',
                  subtitle: 'Today',
                  iconColor: Colors.red,
                  icon: Icons.cancel,
                  onTap: () => widget.onFilterTap(OrderStatus.cancelled, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.cancelled && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Confirmed',
                  value: statusBreakdown.confirmed.toString(),
                  subtitle: 'Today',
                  iconColor: Colors.blue,
                  icon: Icons.check_circle_outline,
                  onTap: () => widget.onFilterTap(OrderStatus.confirmed, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.confirmed && widget.filterByToday,
                ),
              ),
            ],
          ),
          
          SizedBox(height: rowSpacing),
          
          // Third Row - 3 Cards (Preparing, Ready, Delivered)
          Row(
            children: [
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Preparing',
                  value: statusBreakdown.preparing.toString(),
                  subtitle: 'Today',
                  iconColor: Colors.purple,
                  icon: Icons.restaurant,
                  onTap: () => widget.onFilterTap(OrderStatus.preparing, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.preparing && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Ready',
                  value: statusBreakdown.readyForDelivery.toString(),
                  subtitle: 'Today',
                  iconColor: Colors.green,
                  icon: Icons.done_all,
                  onTap: () => widget.onFilterTap(OrderStatus.readyForDelivery, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.readyForDelivery && widget.filterByToday,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildTodayStatsCard(
                  title: 'Delivered',
                  value: statusBreakdown.delivered.toString(),
                  subtitle: 'Today',
                  iconColor: Colors.teal,
                  icon: Icons.check_circle,
                  onTap: () => widget.onFilterTap(OrderStatus.delivered, filterByToday: true),
                  isSelected: widget.selectedStatus == OrderStatus.delivered && widget.filterByToday,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16), // Bottom padding to ensure last row is visible
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int count,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108, // Increased to accommodate today's stats content
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? iconColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.s10,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required IconData icon,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108, // Increased to accommodate today's stats content
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? iconColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: FontSize.s14,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.s10,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: FontSize.s10,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 