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
    String text = status ?? '-';
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        color = Colors.green;
        break;
      case 'INACTIVE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: color, fontWeight: FontWeightManager.medium, fontSize: FontSize.s14),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeightManager.semiBold,
            fontSize: FontSize.s18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: ColorManager.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile data found'));
          }
          final profile = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture & Name
                CircleAvatar(
                  radius: 44,
                  backgroundColor: primary.withOpacity(0.1),
                  child: const Icon(Icons.account_circle, size: 80),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  profile['name'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s20,
                    fontWeight: FontWeightManager.semiBold,
                    color: primary,
                  ),
                ),
                SizedBox(height: 8),
                _statusBadge(profile['status']),
                SizedBox(height: h * 0.02),
                Divider(color: Colors.grey[300]),
                // Personal Info
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Personal Info', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold, fontSize: FontSize.s16)),
                ),
                SizedBox(height: 8),
                _ProfileDetailRow(label: 'Phone', value: profile['phone'] ?? '-'),
                _ProfileDetailRow(label: 'Email', value: profile['email'] ?? '-'),
                _ProfileDetailRow(label: 'Partner ID', value: profile['delivery_partner_id'] ?? '-'),
                SizedBox(height: h * 0.02),
                Divider(color: Colors.grey[300]),
                // Vehicle Info
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Vehicle Info', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold, fontSize: FontSize.s16)),
                ),
                SizedBox(height: 8),
                _ProfileDetailRow(label: 'Vehicle Type', value: profile['vehicle_type'] ?? '-'),
                _ProfileDetailRow(label: 'Vehicle Number', value: profile['vehicle_number'] ?? '-'),
                SizedBox(height: h * 0.02),
                Divider(color: Colors.grey[300]),
                // Account Info
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Account Info', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold, fontSize: FontSize.s16)),
                ),
                SizedBox(height: 8),
                _ProfileDetailRow(label: 'Available', value: (profile['is_available'] == 1) ? 'Yes' : 'No'),
                _ProfileDetailRow(label: 'Created At', value: _formatDate(profile['created_at'])),
                _ProfileDetailRow(label: 'Updated At', value: _formatDate(profile['updated_at'])),
                SizedBox(height: h * 0.03),
                Divider(color: Colors.grey[300]),
                SizedBox(height: h * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await DeliveryPartnerAuthService.clearDeliveryPartnerAuthData();
                      // ignore: use_build_context_synchronously
                      Navigator.pushNamedAndRemoveUntil(context, Routes.partnerSelection, (route) => false);
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
} 