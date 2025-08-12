// lib/presentation/screens/delivery_partner_pages/chat/view.dart - ENHANCED WITH ORDER DETAILS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../ui_components/universal_widget/order_widgets.dart';
import '../../../../ui_components/universal_widget/topbar.dart';
import '../../../../presentation/resources/colors.dart';
import '../../../../presentation/resources/font.dart';
import '../../../../services/menu_item_service.dart';
import '../../../../services/delivery_partner_services/delivery_partner_orders_service.dart';
import 'bloc.dart';
import 'event.dart';
import 'event.dart' as chat_event;
import 'state.dart' as chat_state;

class DeliveryPartnerChatView extends StatefulWidget {
  final String orderId;
  final bool isOrderActive;
  final VoidCallback? onOrderDelivered;
  
  const DeliveryPartnerChatView({
    Key? key,
    required this.orderId,
    required this.isOrderActive,
    this.onOrderDelivered,
  }) : super(key: key);

  @override
  State<DeliveryPartnerChatView> createState() => _DeliveryPartnerChatViewState();
}

class _DeliveryPartnerChatViewState extends State<DeliveryPartnerChatView> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _markAsReadDebounceTimer;
  int _previousMessageCount = 0;
  bool _shouldAutoScroll = true;
  bool _hasMarkedAsRead = false;
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    
    // Add observer to listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Load chat data when the widget initializes (immediately)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('DeliveryPartnerChatView: 🚀 Loading chat data immediately for order: ${widget.orderId}');
        context.read<DeliveryPartnerChatBloc>().add(LoadDeliveryPartnerChatData(widget.orderId));
        
        // Mark messages as read after a short delay to ensure chat is loaded
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _markMessagesAsReadOnView();
          }
        });
      }
    });

    // Listen to scroll events to determine if we should auto-scroll
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        
        // If user scrolls up more than 100 pixels from bottom, disable auto-scroll
        // If they scroll back to within 100 pixels of bottom, re-enable auto-scroll
        setState(() {
          _shouldAutoScroll = (maxScroll - currentScroll) < 100;
        });
        
        // Mark messages as read when user scrolls to view them
        _markMessagesAsReadOnScroll();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInBackground = true;
        break;
        
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        
        // Handle app resume in chat bloc
        if (mounted) {
          context.read<DeliveryPartnerChatBloc>().add(const AppResume());
        }
        break;
        
      default:
        break;
    }
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _messageController.dispose();
    _scrollController.dispose();
    _markAsReadDebounceTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_shouldAutoScroll || !_scrollController.hasClients) return;
    
    if (animated) {
      // Use a slight delay to ensure the widget tree is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _checkForNewMessages(List<chat_state.DeliveryPartnerChatMessage> messages) {
    // CRITICAL: Always scroll to bottom when new messages arrive if auto-scroll is enabled
    if (messages.length > _previousMessageCount && _shouldAutoScroll) {
      _scrollToBottom();
    }
    
    _previousMessageCount = messages.length;
  }

  // Mark messages as read when user scrolls to view them
  void _markMessagesAsReadOnScroll() {
    if (!mounted || _hasMarkedAsRead) return;
    
    // Cancel any existing timer
    _markAsReadDebounceTimer?.cancel();
    
    // Debounce the mark as read call to avoid too many API calls
    _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      try {
        final chatBloc = context.read<DeliveryPartnerChatBloc>();
        final currentState = chatBloc.state;
        
        if (currentState is chat_state.DeliveryPartnerChatLoaded && 
            currentState.messages.isNotEmpty &&
            chatBloc.currentRoomId != null) {
          
          // Check if user has scrolled to view unread messages
          final unreadMessages = currentState.messages.where((msg) => 
              !msg.isUserMessage && !msg.isRead).toList();
          
          if (unreadMessages.isNotEmpty) {
            // Mark messages as read via API
            chatBloc.add(MarkAsRead(chatBloc.currentRoomId!));
            _hasMarkedAsRead = true;
          }
        }
      } catch (e) {
        debugPrint('Error marking messages as read: $e');
      }
    });
  }

  // Mark messages as read when the user first views the chat screen
  void _markMessagesAsReadOnView() {
    if (!mounted || _hasMarkedAsRead) return;
    
    try {
      final chatBloc = context.read<DeliveryPartnerChatBloc>();
      
      if (chatBloc.state is chat_state.DeliveryPartnerChatLoaded && 
          chatBloc.currentRoomId != null) {
        // Mark all messages as read via API
        chatBloc.add(MarkAsRead(chatBloc.currentRoomId!));
        _hasMarkedAsRead = true;
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          // Listener for chat errors and message updates
          BlocListener<DeliveryPartnerChatBloc, chat_state.DeliveryPartnerChatState>(
            listenWhen: (previous, current) {
              if (current is chat_state.DeliveryPartnerChatLoaded) {
                _checkForNewMessages(current.messages);
                return false; // Don't trigger listener, but _checkForNewMessages is called
              }
              return current is chat_state.DeliveryPartnerChatError;
            },
            listener: (context, state) {
              if (state is chat_state.DeliveryPartnerChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<DeliveryPartnerChatBloc>().add(LoadDeliveryPartnerChatData(widget.orderId));
                      },
                    ),
                  ),
                );
              }
            },
          ),
          
          // Listener for delivery success
          BlocListener<DeliveryPartnerChatBloc, chat_state.DeliveryPartnerChatState>(
            listenWhen: (previous, current) {
              return current is chat_state.DeliveryPartnerChatSuccess;
            },
            listener: (context, state) {
              if (state is chat_state.DeliveryPartnerChatSuccess) {
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                fontWeight: FontWeightManager.medium,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                
                // Call the callback to refresh dashboard
                if (mounted) {
                  widget.onOrderDelivered?.call();
                  
                  // Navigate back to dashboard with a small delay to ensure UI updates
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              }
            },
          ),
        ],
        child: BlocBuilder<DeliveryPartnerChatBloc, chat_state.DeliveryPartnerChatState>(
          builder: (context, state) {
            // Handle loading state
            if (state is chat_state.DeliveryPartnerChatLoading) {
              return _buildLoadingState();
            } 
            // Handle loaded state
            else if (state is chat_state.DeliveryPartnerChatLoaded) {
              return _buildChatContent(context, state);
            } 
            // Handle error state
            else if (state is chat_state.DeliveryPartnerChatError) {
              return _buildErrorState(context, state);
            } 
            // Handle success state - show loading briefly then navigate
            else if (state is chat_state.DeliveryPartnerChatSuccess) {
              // Show a brief loading state before navigation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // The success listener will handle the navigation
                }
              });
              return _buildLoadingState();
            }
            // Default to loading state
            else {
              return _buildLoadingState();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SafeArea(
      child: Column(
        children: [
          AppBackHeader(title: 'Chat'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading chat...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, chat_state.DeliveryPartnerChatLoaded state) {
    debugPrint('DeliveryPartnerChatView: 🏗️ _buildChatContent called');
    debugPrint('DeliveryPartnerChatView: 🏗️ Order info status: "${state.orderInfo.status}"');
    debugPrint('DeliveryPartnerChatView: 🏗️ Order info orderId: "${state.orderInfo.orderId}"');
    
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, state),
          _buildOrderHeader(state.orderInfo),
          
          // Order details will be shown as a chat bubble in the messages list
          
          Expanded(
            child: _buildMessagesList(context, state.messages, state),
          ),
          
          if (state.isConnected && state.isRefreshing)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorManager.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Syncing messages...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          _buildActionButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, chat_state.DeliveryPartnerChatLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button and title
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _handleBackNavigation(context),
                  child: Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: ColorManager.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: FontSize.s20,
                          fontWeight: FontWeightManager.bold,
                          color: ColorManager.black,
                        ),
                      ),
                      // Customer details
                      if (state.userDetails != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          state.userDetails!.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeightManager.medium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Call button
          if (state.userDetails?.mobile != null) ...[
            GestureDetector(
              onTap: () => _makePhoneCall(state.userDetails!.mobile),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone,
                  color: ColorManager.primary,
                  size: 20,
                ),
              ),
            ),
          ],
          
          // Show Live/Inactive based on isOrderActive
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isOrderActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isOrderActive ? 'Live' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOrderActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(chat_state.ChatOrderInfo orderInfo) {
    return GestureDetector(
      onTap: () => _onOrderHeaderTap(orderInfo),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order ${orderInfo.orderId}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      fontWeight: FontWeightManager.bold,
                      color: ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.028,
                    vertical: MediaQuery.of(context).size.height * 0.004,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.018,
                        height: MediaQuery.of(context).size.width * 0.018,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.018),
                      Text(
                        orderInfo.status,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.033,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.orange,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.004),
            Text(
              '${orderInfo.restaurantName} • Estimated delivery: ${orderInfo.estimatedDelivery}',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.033,
                fontWeight: FontWeightManager.regular,
                color: Colors.grey.shade600,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOrderHeaderTap(chat_state.ChatOrderInfo orderInfo) {
    final chatBloc = context.read<DeliveryPartnerChatBloc>();
    final partnerId = chatBloc.currentPartnerId ?? '';
    final orderId = chatBloc.currentOrderId ?? widget.orderId;

    print('DeliveryPartnerChatView: Tapping order header');
    print('DeliveryPartnerChatView: Partner ID: $partnerId');
    print('DeliveryPartnerChatView: Full Order ID: $orderId');

    if (partnerId.isNotEmpty && orderId.isNotEmpty) {
      // Show the order options bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => OrderOptionsBottomSheet(
          orderId: orderId,
          partnerId: partnerId,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load order options. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBackNavigation(BuildContext context) {
    // Check if there's a previous route in the navigation stack
    if (Navigator.of(context).canPop()) {
      // If there's a previous route, pop normally
      Navigator.of(context).pop();
    } else {
      // If there's no previous route (e.g., navigated from notification), go to home
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/delivery-dashboard', // You might need to adjust this route name
        (route) => false,
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: show a snackbar with the phone number
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call. Phone number: $phoneNumber'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build order details as chat bubble
  Widget _buildOrderDetailsChatBubble(chat_state.OrderDetails orderDetails, Map<String, MenuItem> menuItems) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          
          // Order details bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
              minWidth: MediaQuery.of(context).size.width * 0.15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: ColorManager.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeightManager.bold,
                                    color: ColorManager.black,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                                Text(
                                  '${orderDetails.items.length} items • ${orderDetails.formattedGrandTotal('₹')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Order items (compact version)
                      ...orderDetails.items.take(3).map((item) {
                        final menuItem = menuItems[item.menuId];
                        final itemName = menuItem?.name ?? 'Unknown Item';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x $itemName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeightManager.medium,
                                    color: ColorManager.black,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${(item.itemPrice * item.quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeightManager.bold,
                                  color: ColorManager.primary,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // Show more items indicator if there are more than 3
                      if (orderDetails.items.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '+${orderDetails.items.length - 3} more items',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ),
                      
                      const Divider(height: 12, thickness: 1),
                      
                      // Price summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          Text(
                            orderDetails.formattedTotal('₹'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeightManager.medium,
                              color: ColorManager.black,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                      if (orderDetails.deliveryFeesDouble > 0) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Fee',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                            Text(
                              orderDetails.formattedDeliveryFees('₹'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeightManager.medium,
                                color: ColorManager.black,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeightManager.bold,
                              color: ColorManager.black,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          Text(
                            orderDetails.formattedGrandTotal('₹'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeightManager.bold,
                              color: ColorManager.primary,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Order status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(orderDetails.orderStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(orderDetails.orderStatus).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(orderDetails.orderStatus),
                              color: _getStatusColor(orderDetails.orderStatus),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatOrderStatus(orderDetails.orderStatus),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeightManager.medium,
                                color: _getStatusColor(orderDetails.orderStatus),
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    orderDetails.formattedOrderTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeightManager.regular,
                      color: Colors.grey.shade500,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'READY':
        return Colors.green;
      case 'OUT_FOR_DELIVERY':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PREPARING':
        return Icons.restaurant;
      case 'READY':
        return Icons.done_all;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'READY':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _buildMessagesList(BuildContext context, List<chat_state.DeliveryPartnerChatMessage> messages, chat_state.DeliveryPartnerChatLoaded state) {
    // Show order details as first chat bubble if available
    final hasOrderDetails = state.orderDetails != null;
    final isLoadingOrderDetails = state.isLoadingOrderDetails;
    
    if (messages.isEmpty && !hasOrderDetails && !isLoadingOrderDetails) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your customer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (hasOrderDetails ? 1 : 0),
      itemBuilder: (context, index) {
        // Show order details as the first item
        if (index == 0 && hasOrderDetails) {
          return _buildOrderDetailsChatBubble(state.orderDetails!, state.menuItems);
        }
        
        // Show regular messages (adjust index for order details)
        final messageIndex = hasOrderDetails ? index - 1 : index;
        if (messageIndex >= 0 && messageIndex < messages.length) {
          final message = messages[messageIndex];
          return _buildMessageBubble(message);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageBubble(chat_state.DeliveryPartnerChatMessage message) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        mainAxisAlignment: message.isUserMessage 
            ? MainAxisAlignment.end     // Delivery partner messages on RIGHT
            : MainAxisAlignment.start,  // Customer messages on LEFT
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer avatar on LEFT side (only for customer messages)
          if (!message.isUserMessage) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ],
          
          // Message bubble with proper width constraints
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.75, // Max 75% of screen width
              minWidth: screenWidth * 0.15,  // Min 15% of screen width
            ),
            child: Column(
              crossAxisAlignment: message.isUserMessage 
                  ? CrossAxisAlignment.end    // Delivery partner messages aligned to right
                  : CrossAxisAlignment.start, // Customer messages aligned to left
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUserMessage 
                        ? const Color(0xFF2196F3)  // Blue for delivery partner
                        : Colors.grey.shade100,    // Light grey for customer
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                        message.isUserMessage ? 18 : 4, // Tail effect for incoming
                      ),
                      bottomRight: Radius.circular(
                        message.isUserMessage ? 4 : 18, // Tail effect for outgoing
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeightManager.regular,
                      color: message.isUserMessage 
                          ? Colors.white          // White text for delivery partner messages
                          : ColorManager.black,   // Black text for customer messages
                      fontFamily: FontFamily.Montserrat,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Time and delivery status with READ TICKS
                Padding(
                  padding: EdgeInsets.only(
                    left: message.isUserMessage ? 0 : 8,
                    right: message.isUserMessage ? 8 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeightManager.regular,
                          color: Colors.grey.shade500,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      // Show delivery status only for delivery partner messages (sent by current user)
                      if (message.isUserMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all, // Double check mark for all messages
                          size: 14,
                          // BLUE tick if read, GREY tick if not read
                          color: message.isRead 
                              ? Colors.blue          // BLUE = Read by recipient
                              : Colors.grey.shade500, // GREY = Not read yet
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, chat_state.DeliveryPartnerChatLoaded state) {
    debugPrint('DeliveryPartnerChatView: 🔘 _buildActionButtons called');
    debugPrint('DeliveryPartnerChatView: 🔘 Order status: "${state.orderInfo.status}"');
    debugPrint('DeliveryPartnerChatView: 🔘 Order status lowercase: "${state.orderInfo.status.toLowerCase()}"');
    debugPrint('DeliveryPartnerChatView: 🔘 Contains delivered: ${state.orderInfo.status.toLowerCase().contains('delivered')}');
    debugPrint('DeliveryPartnerChatView: 🔘 Is updating: ${state.isUpdatingOrderStatus}');
    
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Mark as delivered button - show for OUT_FOR_DELIVERY status
          if (state.orderInfo.status.toLowerCase() == 'out for delivery') ...[
            Builder(
              builder: (context) {
                debugPrint('DeliveryPartnerChatView: 🔘 Button condition check - status: "${state.orderInfo.status}"');
                debugPrint('DeliveryPartnerChatView: 🔘 Button should be shown: ${state.orderInfo.status.toLowerCase() == 'out for delivery'}');
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: state.isUpdatingOrderStatus 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.done_all, color: Colors.white),
                    label: Text(
                      state.isUpdatingOrderStatus ? 'Updating...' : 'Mark as Delivered',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeightManager.semiBold,
                        fontSize: FontSize.s16,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    onPressed: state.isUpdatingOrderStatus 
                        ? null 
                        : () => _showMarkAsDeliveredDialog(context, widget.orderId),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          // Read-only indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Read-only mode - You cannot send messages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkAsDeliveredDialog(BuildContext context, String orderId) {
    debugPrint('DeliveryPartnerChatView: 🎯 _showMarkAsDeliveredDialog called with orderId: $orderId');
    
    debugPrint('DeliveryPartnerChatView: 📋 Showing mark as delivered dialog');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              Text(
                'Mark as Delivered',
                style: TextStyle(
                  fontWeight: FontWeightManager.semiBold,
                  fontSize: FontSize.s18,
                  fontFamily: FontFamily.Montserrat,
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
                style: TextStyle(
                  fontSize: FontSize.s14,
                  color: Colors.grey[700],
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The order will be marked as completed.',
                        style: TextStyle(
                          fontSize: FontSize.s12,
                          color: Colors.green[700],
                          fontFamily: FontFamily.Montserrat,
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint('DeliveryPartnerChatView: 🎯 Dialog button clicked for orderId: $orderId');
                
                debugPrint('DeliveryPartnerChatView: 📞 Making direct API call to mark order as delivered');
                
                // Close the dialog first
                Navigator.of(context).pop();
                
                // Show loading indicator
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Marking order as delivered...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
                
                try {
                  // Make the API call directly
                  final response = await DeliveryPartnerOrdersService.updateOrderStatus(orderId, 'DELIVERED');
                  
                  debugPrint('DeliveryPartnerChatView: 📋 API response: $response');
                  
                  // Check if widget is still mounted before accessing context
                  if (!mounted) {
                    debugPrint('DeliveryPartnerChatView: ⚠️ Widget no longer mounted, skipping UI updates');
                    return;
                  }
                  
                  // Hide the loading snackbar safely
                  try {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  } catch (e) {
                    debugPrint('DeliveryPartnerChatView: ⚠️ Could not hide loading snackbar: $e');
                  }
                  
                  if (response['success'] == true) {
                    debugPrint('DeliveryPartnerChatView: ✅ Order marked as delivered successfully');
                    
                    // Show success message safely
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              const Text('Order marked as delivered successfully!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      debugPrint('DeliveryPartnerChatView: ⚠️ Could not show success snackbar: $e');
                    }
                    
                    // Call the callback to refresh dashboard
                    widget.onOrderDelivered?.call();
                    
                    // Navigate back to dashboard
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    debugPrint('DeliveryPartnerChatView: ❌ API returned failure: ${response['message']}');
                    
                    // Show error message safely
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Text(response['message'] ?? 'Failed to mark order as delivered'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      debugPrint('DeliveryPartnerChatView: ⚠️ Could not show error snackbar: $e');
                    }
                  }
                } catch (e) {
                  debugPrint('DeliveryPartnerChatView: ❌ Error marking order as delivered: $e');
                  
                  // Check if widget is still mounted before accessing context
                  if (!mounted) {
                    debugPrint('DeliveryPartnerChatView: ⚠️ Widget no longer mounted, skipping error UI updates');
                    return;
                  }
                  
                  // Hide the loading snackbar safely
                  try {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  } catch (e) {
                    debugPrint('DeliveryPartnerChatView: ⚠️ Could not hide loading snackbar: $e');
                  }
                  
                  // Show error message safely
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text('Error: $e'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e2) {
                    debugPrint('DeliveryPartnerChatView: ⚠️ Could not show error snackbar: $e2');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Mark as Delivered',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeightManager.semiBold,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, chat_state.DeliveryPartnerChatError state) {
    return SafeArea(
      child: Column(
        children: [
          const AppBackHeader(title: 'Chat'),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: MediaQuery.of(context).size.width * 0.12,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey.shade600,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DeliveryPartnerChatBloc>().add(LoadDeliveryPartnerChatData(widget.orderId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.015,
                          ),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.032,
                          fontWeight: FontWeightManager.medium,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}