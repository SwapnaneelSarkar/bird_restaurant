import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../resources/colors.dart';
import '../../../resources/font.dart';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
import 'package:intl/intl.dart';

class DeliveryPartnerProfileView extends StatefulWidget {
  const DeliveryPartnerProfileView({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerProfileView> createState() => _DeliveryPartnerProfileViewState();
}

class _DeliveryPartnerProfileViewState extends State<DeliveryPartnerProfileView> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final id = await DeliveryPartnerAuthService.getDeliveryPartnerId();
    if (id == null || id.isEmpty) return null;
    final result = await DeliveryPartnerAuthService.fetchDeliveryPartnerDetails(id);
    if (result['success'] == true) {
      return result['data'];
    }
    return null;
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
    } catch (_) {
      return iso;
    }
  }

  Widget _statusBadge(String? status) {
    Color color;
    IconData icon;
    String text = status?.toUpperCase() ?? '-';
    String label = 'Status: ';
    switch (text) {
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.check_circle;
        label += 'ACTIVE';
        break;
      case 'INACTIVE':
        color = Colors.red;
        icon = Icons.cancel;
        label += 'INACTIVE';
        break;
      case 'BLOCKED':
        color = Colors.orange;
        icon = Icons.block;
        label += 'BLOCKED';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label += text;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeightManager.medium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final primary = ColorManager.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeightManager.bold,
                fontSize: FontSize.s18,
              ),
            ),
            Text(
              'Delivery Partner',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeightManager.medium,
                fontSize: FontSize.s12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshProfile,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      backgroundColor: ColorManager.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withOpacity(0.1), primary.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      color: Colors.grey[600],
                      fontWeight: FontWeightManager.medium,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      color: Colors.red[600],
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.person_off,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No profile data found',
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      color: Colors.grey[600],
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        primary.withOpacity(0.8),
                        primary.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delivery_dining,
                              size: 50,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Name + Edit Button Row
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  profile['name'] ?? 'Delivery Partner',
                                  style: GoogleFonts.poppins(
                                    fontSize: FontSize.s25,
                                    fontWeight: FontWeightManager.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white, size: 22),
                                  tooltip: 'Edit Profile',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.deliveryPartnerProfileEdit,
                                      arguments: profile,
                                    ).then((value) {
                                      // Refresh profile after editing
                                      _refreshProfile();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Status Badge (normal size, colored)
                          _statusBadge(profile['status']),
                          const SizedBox(height: 16),
                          
                          // Quick Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _QuickStatCard(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: profile['phone'] ?? '-',
                                color: Colors.blue,
                              ),
                              _QuickStatCard(
                                icon: Icons.email,
                                label: 'Email',
                                value: profile['email'] ?? '-',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content Sections
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Personal Information Card
                      _InfoCard(
                        title: 'Personal Information',
                        icon: Icons.person,
                        iconColor: Colors.blue[700]!,
                        children: [
                          _ProfileDetailRow(
                            icon: Icons.badge,
                            label: 'Partner ID',
                            value: profile['delivery_partner_id'] ?? '-',
                          ),
                          _ProfileDetailRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: profile['phone'] ?? '-',
                          ),
                          _ProfileDetailRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: profile['email'] ?? '-',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Vehicle Information Card
                      _InfoCard(
                        title: 'Vehicle Information',
                        icon: Icons.directions_car,
                        iconColor: Colors.green[700]!,
                        children: [
                          _ProfileDetailRow(
                            icon: Icons.category,
                            label: 'Vehicle Type',
                            value: profile['vehicle_type'] ?? '-',
                          ),
                          _ProfileDetailRow(
                            icon: Icons.confirmation_number,
                            label: 'Vehicle Number',
                            value: profile['vehicle_number'] ?? '-',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Account Information Card
                      _InfoCard(
                        title: 'Account Information',
                        icon: Icons.account_circle,
                        iconColor: Colors.purple[700]!,
                        children: [
                          _ProfileDetailRow(
                            icon: Icons.check_circle,
                            label: 'Available',
                            value: (profile['is_available'] == 1) ? 'Yes' : 'No',
                            valueColor: (profile['is_available'] == 1) ? Colors.green : Colors.red,
                          ),
                          _ProfileDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Created At',
                            value: _formatDate(profile['created_at']),
                          ),
                          _ProfileDetailRow(
                            icon: Icons.update,
                            label: 'Updated At',
                            value: _formatDate(profile['updated_at']),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[600]!, Colors.red[700]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Show confirmation dialog
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red[600], size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeightManager.semiBold,
                                          fontSize: FontSize.s18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    'Are you sure you want to logout?',
                                    style: GoogleFonts.poppins(
                                      fontSize: FontSize.s14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeightManager.medium,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Logout',
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
                            
                            if (shouldLogout == true) {
                              await DeliveryPartnerAuthService.clearDeliveryPartnerAuthData();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, Routes.partnerSelection, (route) => false);
                              }
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeightManager.bold,
                              color: Colors.white,
                              fontSize: FontSize.s16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
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

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: FontSize.s12,
              fontWeight: FontWeightManager.medium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: FontSize.s12,
              fontWeight: FontWeightManager.semiBold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s18,
                    fontWeight: FontWeightManager.semiBold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s12,
                    color: Colors.grey[600],
                    fontWeight: FontWeightManager.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.semiBold,
                    color: valueColor ?? Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 