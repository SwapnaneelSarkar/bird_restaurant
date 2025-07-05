import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../../../../services/delivery_partner_services/delivery_partner_orders_service.dart';
import '../../../../services/location_services.dart';
import '../../../resources/colors.dart';
import '../../../resources/font.dart';
import 'package:intl/intl.dart';

class DeliveryPartnerOrderDetailsView extends StatefulWidget {
  const DeliveryPartnerOrderDetailsView({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerOrderDetailsView> createState() => _DeliveryPartnerOrderDetailsViewState();
}

class _DeliveryPartnerOrderDetailsViewState extends State<DeliveryPartnerOrderDetailsView> {
  String? orderId;
  Future<Map<String, dynamic>?>? _orderFuture;
  Future<Map<String, dynamic>?>? _userFuture;
  Future<Map<String, dynamic>?>? _restaurantFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderId = ModalRoute.of(context)?.settings.arguments as String?;
    if (orderId != null) {
      _orderFuture = _fetchOrder(orderId!);
    }
  }

  Future<Map<String, dynamic>?> _fetchOrder(String id) async {
    final result = await DeliveryPartnerOrdersService.fetchOrderDetailsById(id);
    if (result['success'] == true) {
      final data = result['data'];
      // Fetch user details if user_id is available
      if (data['user_id'] != null && data['user_id'].toString().isNotEmpty) {
        _userFuture = _fetchUser(data['user_id']);
      }
      // Fetch restaurant details if partner_id is available
      if (data['partner_id'] != null && data['partner_id'].toString().isNotEmpty) {
        _restaurantFuture = _fetchRestaurant(data['partner_id']);
      }
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final result = await DeliveryPartnerOrdersService.fetchUserDetails(userId);
    if (result['success'] == true) {
      return result['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRestaurant(String partnerId) async {
    final result = await DeliveryPartnerOrdersService.fetchRestaurantDetails(partnerId);
    if (result['success'] == true) {
      return result['data'];
    }
    return null;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _navigateToLocation(double latitude, double longitude, String label) async {
    print('[Navigation] Attempting to navigate to: $latitude, $longitude');
    
    // First try maps_launcher package (most reliable)
    try {
      print('[Navigation] Trying maps_launcher...');
      await MapsLauncher.launchCoordinates(latitude, longitude, label);
      print('[Navigation] Successfully launched with maps_launcher');
      return;
    } catch (e) {
      print('[Navigation] maps_launcher failed: $e');
    }
    
    // Fallback to url_launcher with multiple URL schemes
    final urls = [
      'https://www.google.com/maps/search/$latitude,$longitude',
      'https://maps.google.com/maps?q=$latitude,$longitude',
      'geo:$latitude,$longitude',
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    ];
    
    for (String url in urls) {
      try {
        print('[Navigation] Trying URL: $url');
        final uri = Uri.parse(url);
        
        // Try to launch directly without checking canLaunchUrl
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('[Navigation] Launch result for $url: $result');
        
        if (result) {
          print('[Navigation] Successfully launched navigation with: $url');
          return;
        }
      } catch (e) {
        print('[Navigation] Error with URL $url: $e');
        continue;
      }
    }
    
    // If all attempts fail, show user-friendly dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text('Navigation Help'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to open navigation automatically.',
                  style: GoogleFonts.poppins(fontWeight: FontWeightManager.medium),
                ),
                SizedBox(height: 12),
                Text(
                  'You can manually navigate by:',
                  style: GoogleFonts.poppins(fontSize: FontSize.s14),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Opening Google Maps',
                  style: GoogleFonts.poppins(fontSize: FontSize.s12, color: Colors.grey[600]),
                ),
                Text(
                  '2. Searching for: $latitude, $longitude',
                  style: GoogleFonts.poppins(fontSize: FontSize.s12, color: Colors.grey[600]),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coordinates: $latitude, $longitude',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s12,
                      fontWeight: FontWeightManager.medium,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Try to open Google Maps in browser as final fallback
                  launchUrl(
                    Uri.parse('https://www.google.com/maps/search/$latitude,$longitude'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text('Open in Browser'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showMarkAsDeliveredDialog(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              SizedBox(width: 12),
              Text(
                'Mark as Delivered',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeightManager.semiBold,
                  fontSize: FontSize.s18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this order as delivered?',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The order will be marked as completed.',
                        style: GoogleFonts.poppins(
                          fontSize: FontSize.s12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsDelivered(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Mark as Delivered',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeightManager.semiBold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsDelivered(String orderId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Updating order status...',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final result = await DeliveryPartnerOrdersService.updateOrderStatus(orderId, 'DELIVERED');
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Order marked as delivered successfully!',
                    style: GoogleFonts.poppins(fontWeight: FontWeightManager.medium),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate back to dashboard
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    result['message'] ?? 'Failed to update order status',
                    style: GoogleFonts.poppins(fontWeight: FontWeightManager.medium),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Error: $e',
                  style: GoogleFonts.poppins(fontWeight: FontWeightManager.medium),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'READY_FOR_DELIVERY':
        return Colors.orange;
      case 'OUT_FOR_DELIVERY':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = ColorManager.primary;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeightManager.semiBold
          )
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: ColorManager.background,
      body: orderId == null
          ? const Center(child: Text('No order ID provided'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading order details...'),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading order details',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Order not found',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                final order = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Order #${order['order_id']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: FontSize.s20,
                                      fontWeight: FontWeightManager.bold,
                                      color: primary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['order_status'] ?? '').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(order['order_status'] ?? ''),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                order['order_status'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(order['order_status'] ?? ''),
                                  fontWeight: FontWeightManager.semiBold,
                                  fontSize: FontSize.s14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // From & To Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[50]!,
                              Colors.green[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.route, color: Colors.blue[700], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery Route',
                                  style: GoogleFonts.poppins(
                                    fontSize: FontSize.s18,
                                    fontWeight: FontWeightManager.semiBold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // From (Restaurant)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FROM',
                                        style: GoogleFonts.poppins(
                                          fontSize: FontSize.s12,
                                          fontWeight: FontWeightManager.medium,
                                          color: Colors.grey[600],
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: _restaurantFuture,
                                        builder: (context, restaurantSnapshot) {
                                          if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                                            return Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading restaurant...',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: FontSize.s14,
                                                    fontWeight: FontWeightManager.medium,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else if (restaurantSnapshot.hasError || !restaurantSnapshot.hasData) {
                                            return Text(
                                              'Restaurant details unavailable',
                                              style: GoogleFonts.poppins(
                                                fontSize: FontSize.s14,
                                                fontWeight: FontWeightManager.medium,
                                                color: Colors.red[600],
                                              ),
                                            );
                                          } else {
                                            final restaurant = restaurantSnapshot.data!;
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  restaurant['restaurant_name'] ?? 'Unknown Restaurant',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: FontSize.s16,
                                                    fontWeight: FontWeightManager.semiBold,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                                                                 Text(
                                                   restaurant['address'] ?? 'Address not available',
                                                   style: GoogleFonts.poppins(
                                                     fontSize: FontSize.s12,
                                                     color: Colors.grey[600],
                                                   ),
                                                   maxLines: 2,
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Route Line
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Container(
                                width: 2,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue[300],
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // To (Delivery Address)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TO',
                                        style: GoogleFonts.poppins(
                                          fontSize: FontSize.s12,
                                          fontWeight: FontWeightManager.medium,
                                          color: Colors.grey[600],
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Delivery Address',
                                        style: GoogleFonts.poppins(
                                          fontSize: FontSize.s16,
                                          fontWeight: FontWeightManager.semiBold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                                                             Text(
                                         order['address'] ?? 'Address not available',
                                         style: GoogleFonts.poppins(
                                           fontSize: FontSize.s12,
                                           color: Colors.grey[600],
                                         ),
                                         maxLines: 2,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Navigation Buttons
                            Column(
                              children: [
                                // Navigate to Restaurant Button
                                SizedBox(
                                  width: double.infinity,
                                  child: FutureBuilder<Map<String, dynamic>?>(
                                    future: _restaurantFuture,
                                    builder: (context, restaurantSnapshot) {
                                      final hasRestaurantCoords = restaurantSnapshot.hasData && 
                                          restaurantSnapshot.data!['latitude'] != null && 
                                          restaurantSnapshot.data!['longitude'] != null;
                                      
                                      return ElevatedButton.icon(
                                        onPressed: hasRestaurantCoords ? () {
                                          final restaurant = restaurantSnapshot.data!;
                                          final lat = double.tryParse(restaurant['latitude'].toString());
                                          final lng = double.tryParse(restaurant['longitude'].toString());
                                          if (lat != null && lng != null) {
                                            _navigateToLocation(lat, lng, 'Restaurant');
                                          }
                                        } : null,
                                        icon: Icon(
                                          Icons.store,
                                          color: hasRestaurantCoords ? Colors.white : Colors.grey[400],
                                          size: 20,
                                        ),
                                        label: Text(
                                          'Navigate to Restaurant',
                                          style: GoogleFonts.poppins(
                                            color: hasRestaurantCoords ? Colors.white : Colors.grey[400],
                                            fontWeight: FontWeightManager.semiBold,
                                            fontSize: FontSize.s14,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasRestaurantCoords ? Colors.green[600] : Colors.grey[300],
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: hasRestaurantCoords ? 3 : 0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Navigate to Delivery Location Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (order['latitude'] != null && order['longitude'] != null) ? () {
                                      final lat = double.tryParse(order['latitude'].toString());
                                      final lng = double.tryParse(order['longitude'].toString());
                                      if (lat != null && lng != null) {
                                        _navigateToLocation(lat, lng, 'Delivery Location');
                                      }
                                    } : null,
                                    icon: Icon(
                                      Icons.location_on,
                                      color: (order['latitude'] != null && order['longitude'] != null) 
                                          ? Colors.white 
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Navigate to Delivery Location',
                                      style: GoogleFonts.poppins(
                                        color: (order['latitude'] != null && order['longitude'] != null) 
                                            ? Colors.white 
                                            : Colors.grey[400],
                                        fontWeight: FontWeightManager.semiBold,
                                        fontSize: FontSize.s14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (order['latitude'] != null && order['longitude'] != null) 
                                          ? Colors.red[600] 
                                          : Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: (order['latitude'] != null && order['longitude'] != null) ? 3 : 0,
                                    ),
                                  ),
                                ),
                                
                                // Disclaimer for missing coordinates
                                if (order['latitude'] == null || order['longitude'] == null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange[700],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This order doesn\'t have valid location coordinates for navigation.',
                                            style: GoogleFonts.poppins(
                                              fontSize: FontSize.s12,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeightManager.medium,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Restaurant Information Section
                      _SectionHeader(title: 'Restaurant Information', icon: Icons.store, color: Colors.green[700]!),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _restaurantFuture,
                          builder: (context, restaurantSnapshot) {
                            if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.store, color: Colors.green[700], size: 20),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      'Restaurant',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeightManager.medium,
                                        fontSize: FontSize.s14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Loading...',
                                          style: GoogleFonts.poppins(
                                            fontSize: FontSize.s14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            } else if (restaurantSnapshot.hasError || !restaurantSnapshot.hasData) {
                              return _DetailRow(
                                label: 'Restaurant',
                                value: 'Error loading restaurant details',
                                icon: Icons.store,
                                iconColor: Colors.red[700]!,
                              );
                            } else {
                              final restaurant = restaurantSnapshot.data!;
                              return Column(
                                children: [
                                  _DetailRow(
                                    label: 'Restaurant Name',
                                    value: restaurant['restaurant_name'] ?? 'Unknown',
                                    icon: Icons.store,
                                    iconColor: Colors.green[700]!,
                                  ),
                                  const Divider(height: 24),
                                  _DetailRow(
                                    label: 'Restaurant Address',
                                    value: restaurant['address'] ?? 'Unknown',
                                    icon: Icons.location_on,
                                    iconColor: Colors.blue[700]!,
                                  ),
                                  const Divider(height: 24),
                                  _DetailRow(
                                    label: 'Restaurant Phone',
                                    value: restaurant['mobile'] ?? 'Unknown',
                                    icon: Icons.phone,
                                    iconColor: Colors.orange[700]!,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Delivery Information Section
                      _SectionHeader(title: 'Delivery Information', icon: Icons.location_on, color: primary),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Delivery Address',
                              value: order['address'] ?? '-',
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                            ),
                            if (order['latitude'] != null && order['longitude'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                label: 'Coordinates',
                                value: '${order['latitude']}, ${order['longitude']}',
                                icon: Icons.gps_fixed,
                                iconColor: Colors.blue,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Order Details Section
                      _SectionHeader(title: 'Order Details', icon: Icons.shopping_cart, color: Colors.green[700]!),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Total Price',
                              value: '₹${order['total_price'] ?? '0.00'}',
                              icon: Icons.attach_money,
                              iconColor: Colors.amber[800]!,
                              isHighlighted: true,
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              label: 'Created At',
                              value: _formatDate(order['created_at']),
                              icon: Icons.schedule,
                              iconColor: Colors.grey[600]!,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Customer Information Section
                      _SectionHeader(title: 'Customer Information', icon: Icons.person, color: Colors.blue[700]!),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            if (order['user_id'] != null && order['user_id'].toString().isNotEmpty) ...[
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _userFuture,
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.person, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            'Customer',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeightManager.medium,
                                              fontSize: FontSize.s14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Loading...',
                                                style: GoogleFonts.poppins(
                                                  fontSize: FontSize.s14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                                    return _DetailRow(
                                      label: 'Customer',
                                      value: 'Error loading user details',
                                      icon: Icons.person,
                                      iconColor: Colors.red[700]!,
                                    );
                                  } else {
                                    final user = userSnapshot.data!;
                                    return Column(
                                      children: [
                                        _DetailRow(
                                          label: 'Customer Name',
                                          value: user['username'] ?? 'Unknown',
                                          icon: Icons.person,
                                          iconColor: Colors.blue[700]!,
                                        ),
                                        const Divider(height: 24),
                                        _DetailRow(
                                          label: 'Customer Phone',
                                          value: user['mobile'] ?? 'Unknown',
                                          icon: Icons.phone,
                                          iconColor: Colors.green[700]!,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ] else ...[
                              _DetailRow(
                                label: 'Customer',
                                value: 'No user information',
                                icon: Icons.person,
                                iconColor: Colors.grey[600]!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // IDs Information Section
                      _SectionHeader(title: 'IDs Information', icon: Icons.info, color: Colors.blue[700]!),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'Partner ID',
                              value: order['partner_id'] ?? '-',
                              icon: Icons.store,
                              iconColor: Colors.green[700]!,
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              label: 'Delivery Partner ID',
                              value: (order['delivery_partner_id'] != null && order['delivery_partner_id'].toString().isNotEmpty) 
                                  ? order['delivery_partner_id'] 
                                  : 'Not Assigned',
                              icon: Icons.delivery_dining,
                              iconColor: (order['delivery_partner_id'] != null && order['delivery_partner_id'].toString().isNotEmpty)
                                  ? Colors.orange[700]!
                                  : Colors.grey[600]!,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Mark as Delivered Button
                      if (order['order_status'] != 'DELIVERED' && order['order_status'] != 'CANCELLED')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showMarkAsDeliveredDialog(order['order_id']),
                            icon: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            label: Text(
                              'Mark as Delivered',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeightManager.semiBold,
                                fontSize: FontSize.s16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.semiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final bool isHighlighted;
  
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.isHighlighted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon!, color: iconColor ?? Colors.grey[600], size: 20),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeightManager.medium,
              fontSize: FontSize.s14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: isHighlighted ? FontWeightManager.semiBold : FontWeightManager.regular,
              color: isHighlighted ? ColorManager.primary : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 