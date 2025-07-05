import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/delivery_partner_services/delivery_partner_orders_service.dart';
import '../../../../services/location_services.dart';
import '../../../resources/colors.dart';
import '../../../resources/font.dart';

class DeliveryPartnerOrderDetailsView extends StatefulWidget {
  const DeliveryPartnerOrderDetailsView({Key? key}) : super(key: key);

  @override
  State<DeliveryPartnerOrderDetailsView> createState() => _DeliveryPartnerOrderDetailsViewState();
}

class _DeliveryPartnerOrderDetailsViewState extends State<DeliveryPartnerOrderDetailsView> {
  String? orderId;
  Future<Map<String, dynamic>?>? _orderFuture;
  String? decodedAddress;
  bool isDecoding = false;

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
      _decodeAddress(data);
      return data;
    }
    return null;
  }

  void _decodeAddress(Map<String, dynamic> data) async {
    setState(() { isDecoding = true; });
    final lat = double.tryParse(data['latitude'] ?? '');
    final lng = double.tryParse(data['longitude'] ?? '');
    if (lat != null && lng != null) {
      final address = await LocationService().getAddressFromCoordinates(lat, lng);
      setState(() {
        decodedAddress = address;
        isDecoding = false;
      });
    } else {
      setState(() { isDecoding = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = ColorManager.primary;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: Text('Order Details', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeightManager.semiBold)),
      ),
      backgroundColor: ColorManager.background,
      body: orderId == null
          ? const Center(child: Text('No order ID provided'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading order details'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Order not found'));
                }
                final order = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Order ID', value: order['order_id'] ?? '-'),
                      _DetailRow(label: 'Status', value: order['order_status'] ?? '-'),
                      _DetailRow(label: 'Total Price', value: order['total_price'] ?? '-'),
                      _DetailRow(label: 'Created At', value: order['created_at'] ?? '-'),
                      _DetailRow(label: 'Partner ID', value: order['partner_id'] ?? '-'),
                      _DetailRow(label: 'User ID', value: order['user_id'] ?? '-'),
                      _DetailRow(label: 'Delivery Partner ID', value: order['delivery_partner_id'] ?? '-'),
                      const SizedBox(height: 16),
                      Text('Delivery Address:', style: GoogleFonts.poppins(fontWeight: FontWeightManager.semiBold)),
                      Row(
                        children: [
                          Expanded(child: Text(order['address'] ?? '-', style: GoogleFonts.poppins())),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: (order['latitude'] != null && order['longitude'] != null)
                                ? () {
                                    // TODO: Implement Google Maps navigation
                                  }
                                : null,
                            tooltip: 'Navigate',
                          ),
                        ],
                      ),
                      if (isDecoding) const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                      if (decodedAddress != null && decodedAddress!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Decoded Address: $decodedAddress', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeightManager.medium))),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }
} 