// lib/presentation/screens/order_action_result/view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../resources/router/router.dart';
import '../chat/state.dart' show OrderDetails; // reuse shared model
import '../../../services/order_service.dart';
import '../../../utils/time_utils.dart';

class OrderActionResultView extends StatefulWidget {
  final String orderId;
  final String action; // 'accepted' or 'cancelled'
  final bool isSuccess;

  const OrderActionResultView({
    Key? key,
    required this.orderId,
    required this.action,
    required this.isSuccess,
  }) : super(key: key);

  @override
  State<OrderActionResultView> createState() => _OrderActionResultViewState();
}

class _OrderActionResultViewState extends State<OrderActionResultView> {
  bool _loading = true;
  String? _error;
  OrderDetails? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final partnerId = await OrderService.getPartnerId();
      if (partnerId == null || partnerId.isEmpty) {
        throw Exception('Partner ID not found');
      }
      final res = await OrderService.getOrderDetails(
        partnerId: partnerId,
        orderId: widget.orderId,
      );
      setState(() {
        _details = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        elevation: 0,
        title: Text(
          'Order Action Result',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeightManager.semiBold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.orders,
            (route) => false,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _loading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Fetching order details...'),
                  ],
                )
              : _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                      ],
                    )
                  : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: widget.isSuccess 
                      ? (widget.action == 'accepted' ? Colors.green[50] : Colors.red[50])
                      : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isSuccess 
                      ? (widget.action == 'accepted' ? Icons.check_circle : Icons.cancel)
                      : Icons.error,
                  size: 60,
                  color: widget.isSuccess 
                      ? (widget.action == 'accepted' ? Colors.green[600] : Colors.red[600])
                      : Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                widget.isSuccess 
                    ? (widget.action == 'accepted' ? 'Order Accepted!' : 'Order Cancelled!')
                    : 'Action Failed',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeightManager.bold,
                  color: widget.isSuccess 
                      ? (widget.action == 'accepted' ? Colors.green[700] : Colors.red[700])
                      : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                widget.isSuccess 
                    ? (widget.action == 'accepted' 
                        ? 'Order #${widget.orderId} has been accepted and confirmed'
                        : 'Order #${widget.orderId} has been cancelled')
                    : 'Failed to process order action. Please try again.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Status details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoRow('Order ID', '#${_details?.orderId ?? widget.orderId}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Customer', _details?.userName ?? '-'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Status', _details != null ? OrderService.formatOrderStatus(_details!.orderStatus) : (widget.isSuccess ? (widget.action == 'accepted' ? 'CONFIRMED' : 'CANCELLED') : 'FAILED')),
                    const SizedBox(height: 8),
                    _buildInfoRow('Total', _details?.totalAmount ?? '-'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Delivery Fees', _details?.deliveryFees ?? '0.00'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Address', _details?.deliveryAddress ?? '-'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Date & Time', _details?.datetime != null ? TimeUtils.formatStatusTimelineDate(_details!.datetime!) : '-'),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.orders,
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Orders',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeightManager.semiBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.homePage,
                        (route) => false,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: ColorManager.primary),
                      ),
                      child: Text(
                        'Go Home',
                        style: GoogleFonts.poppins(
                          color: ColorManager.primary,
                          fontWeight: FontWeightManager.semiBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeightManager.medium,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeightManager.semiBold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
} 