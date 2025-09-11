import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/universal_widget/order_widgets.dart';
import '../chat/bloc.dart';
import '../chat/event.dart';
import '../chat/state.dart';
import '../../../services/token_service.dart';
import '../../resources/router/router.dart';

class RestaurantOrderDetailsView extends StatefulWidget {
  const RestaurantOrderDetailsView({Key? key}) : super(key: key);

  @override
  State<RestaurantOrderDetailsView> createState() => _RestaurantOrderDetailsViewState();
}

class _RestaurantOrderDetailsViewState extends State<RestaurantOrderDetailsView> {
  String? orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderId = ModalRoute.of(context)?.settings.arguments as String?;
    print('RestaurantOrderDetailsView: Received orderId: $orderId');
  }

  Future<String?> _loadPartnerId() async {
    try {
      final userId = await TokenService.getUserId();
      print('RestaurantOrderDetailsView: Loaded partner ID: $userId');
      return userId;
    } catch (e) {
      print('RestaurantOrderDetailsView: Error loading partner ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.homePage,
          (route) => false,
        );
        return false;
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (orderId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Order Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Order Not Found',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The order you\'re looking for could not be found.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _loadPartnerId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Order Details',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFE17A47)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Order Details',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load order details',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final partnerId = snapshot.data!;
        print('RestaurantOrderDetailsView: Creating ChatBloc with partnerId: $partnerId');

        return BlocProvider<ChatBloc>(
          create: (context) {
            final bloc = ChatBloc();
            print('RestaurantOrderDetailsView: ChatBloc created, dispatching LoadOrderDetails');
            bloc.add(LoadOrderDetails(
              orderId: orderId!,
              partnerId: partnerId,
            ));
            return bloc;
          },
          child: BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              print('RestaurantOrderDetailsView: State changed to: ${state.runtimeType}');
            },
            child: OrderDetailsWidget(),
          ),
        );
      },
    );
  }
} 