import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../resources/colors.dart';
import '../../../resources/font.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/delivery_partner_services/delivery_partner_orders_service.dart';
import '../../../../models/order_model.dart';
import 'package:lottie/lottie.dart';

class DeliveryPartnerDashboardView extends StatefulWidget {
  const DeliveryPartnerDashboardView({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerDashboardView> createState() => _DeliveryPartnerDashboardViewState();
}

class _DeliveryPartnerDashboardViewState extends State<DeliveryPartnerDashboardView> {
  late Future<List<DeliveryPartnerOrder>> _availableOrdersFuture;
  late Future<List<DeliveryPartnerOrder>> _assignedOrdersFuture;

  @override
  void initState() {
    super.initState();
    _availableOrdersFuture = DeliveryPartnerOrdersService.fetchAvailableOrders();
    _assignedOrdersFuture = DeliveryPartnerOrdersService.fetchAssignedOrders();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final primary = ColorManager.primary;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.delivery_dining, color: primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Delivery Dashboard',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeightManager.semiBold,
                fontSize: FontSize.s18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/deliveryPartnerProfile'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(Icons.person, color: primary, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeightManager.medium,
                      fontSize: FontSize.s14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Available Orders', icon: Icons.list_alt, color: primary),
              FutureBuilder<List<DeliveryPartnerOrder>>(
                future: _availableOrdersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: SizedBox(
                      height: 80,
                      width: 80,
                      child: LottieWidget(),
                    ));
                  } else if (snapshot.hasError) {
                    return _EmptySection(text: 'Failed to load orders.');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: snapshot.data!.where((order) => order != null).map((order) => _OrderCard(
                        order: {
                          'id': order.orderId,
                          'pickup': order.address,
                          'drop': order.address, // No drop in API, using address for both
                          'payment': order.paymentMode ?? 'Unknown',
                          'status': order.orderStatus,
                          'total_price': order.totalPrice,
                          'delivery_fees': order.deliveryFees,
                        },
                        primary: primary,
                        showAccept: true,
                        showApiFields: true,
                      )).toList(),
                    );
                  } else {
                    return _EmptySection(text: 'No available orders.');
                  }
                },
              ),
              SizedBox(height: h * 0.03),
              _SectionHeader(title: 'Assigned Orders', icon: Icons.assignment_turned_in, color: Colors.green[700]!),
              FutureBuilder<List<DeliveryPartnerOrder>>(
                future: _assignedOrdersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: SizedBox(
                      height: 80,
                      width: 80,
                      child: LottieWidget(),
                    ));
                  } else if (snapshot.hasError) {
                    return _EmptySection(text: 'Failed to load assigned orders.');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: snapshot.data!.where((order) => order != null).map((order) => _OrderCard(
                        order: {
                          'id': order.orderId,
                          'pickup': order.address,
                          'drop': order.address, // No drop in API, using address for both
                          'payment': order.paymentMode ?? 'Unknown',
                          'status': order.orderStatus,
                          'total_price': order.totalPrice,
                          'delivery_fees': order.deliveryFees,
                        },
                        primary: primary,
                        showAccept: false,
                        showApiFields: true,
                      )).toList(),
                    );
                  } else {
                    return _EmptySection(text: 'No assigned orders.');
                  }
                },
              ),
              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
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

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.grey[500],
            fontSize: FontSize.s14,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, String> order;
  final Color primary;
  final bool showAccept;
  final bool showApiFields;
  const _OrderCard({required this.order, required this.primary, required this.showAccept, this.showApiFields = false});

  Color _statusColor(String status) {
    switch (status) {
      case 'Assigned':
        return Colors.orange;
      case 'Out for Delivery':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _paymentColor(String payment) {
    if (payment == 'Online') return Colors.green[700]!;
    return Colors.orange[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: primary.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: primary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Order #${order['id']}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeightManager.medium,
                      fontSize: FontSize.s14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: order['status'] ?? '', color: _statusColor(order['status'] ?? '')),
              ],
            ),
            if (showApiFields) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.amber[800], size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Total: ₹${order['total_price']}',
                      style: GoogleFonts.poppins(fontSize: FontSize.s14, fontWeight: FontWeightManager.medium),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.delivery_dining, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Delivery: ₹${order['delivery_fees']}',
                      style: GoogleFonts.poppins(fontSize: FontSize.s14, fontWeight: FontWeightManager.medium),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.store, color: Colors.green[700], size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['pickup'] ?? '',
                    style: GoogleFonts.poppins(fontSize: FontSize.s14, fontWeight: FontWeightManager.medium),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[700], size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['drop'] ?? '',
                    style: GoogleFonts.poppins(fontSize: FontSize.s14, fontWeight: FontWeightManager.medium),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.payment, color: _paymentColor(order['payment'] ?? ''), size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: _PaymentChip(payment: order['payment'] ?? '', color: _paymentColor(order['payment'] ?? '')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (showAccept)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    'Accept Order',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                  onPressed: () {},
                ),
              ),
            if (!showAccept)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions, color: primary, size: 20),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(order['drop'] ?? '')}&origin=${Uri.encodeComponent(order['pickup'] ?? '')}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          'Navigate',
                          style: GoogleFonts.poppins(
                            color: primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeightManager.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: Text(
                        'Mark as Delivered',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeightManager.semiBold,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeightManager.medium,
          fontSize: FontSize.s12,
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String payment;
  final Color color;
  const _PaymentChip({required this.payment, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(payment == 'Online' ? Icons.credit_card : Icons.money, color: color, size: 15),
          const SizedBox(width: 4),
          Text(
            payment,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeightManager.medium,
              fontSize: FontSize.s12,
            ),
          ),
        ],
      ),
    );
  }
}

class LottieWidget extends StatelessWidget {
  const LottieWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Lottie.asset('assets/lottie/loading.json', fit: BoxFit.contain);
  }
} 