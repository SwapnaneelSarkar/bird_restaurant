// lib/presentation/screens/chat/view.dart - ENHANCED WITH ORDER DETAILS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../ui_components/universal_widget/order_widgets.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../../../services/menu_item_service.dart';
import 'bloc.dart';
import 'event.dart';
import 'event.dart' as chat_event;
import 'state.dart' as chat_state;

class ChatView extends StatefulWidget {
  final String orderId;
  final bool isOrderActive;
  
  const ChatView({
    Key? key,
    required this.orderId,
    required this.isOrderActive,
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
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
        debugPrint('ChatView: 🚀 Loading chat data immediately for order: ${widget.orderId}');
        context.read<ChatBloc>().add(LoadChatData(widget.orderId));
        
        // Mark messages as read after a short delay to ensure chat is loaded
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _markMessagesAsReadOnView();
          }
        });
        
        // NEW: Emit typing when chat page opens to trigger blue tick updates for previous messages
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _emitTypingOnPageOpen();
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
          context.read<ChatBloc>().add(const AppResume());
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
    
    // NEW: Stop typing when leaving chat page to clean up typing state
    try {
      if (mounted) {
        context.read<ChatBloc>().add(const StopTyping());
      }
    } catch (e) {
      debugPrint('Error stopping typing on dispose: $e');
    }
    
    _messageController.dispose();
    _scrollController.dispose();
    _markAsReadDebounceTimer?.cancel();
    super.dispose();
  }

  void _handleTyping(String text) {
    // REMOVED: Old typing logic - now using page-based typing instead of text-based typing
    // The typing is now controlled by page open/close and new message events
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

  void _checkForNewMessages(List<chat_state.ChatMessage> messages) {
    // CRITICAL: Always scroll to bottom when new messages arrive if auto-scroll is enabled
    if (messages.length > _previousMessageCount && _shouldAutoScroll) {
      _scrollToBottom();
    }
    
    // NEW: Emit typing when new messages are received to trigger blue tick updates
    if (messages.length > _previousMessageCount) {
      _emitTypingOnNewMessage();
      _hasMarkedAsRead = false;
    }
    
    _previousMessageCount = messages.length;
  }

  // NEW: Emit typing when new message is received to trigger blue tick updates
  void _emitTypingOnNewMessage() {
    debugPrint('ChatView: 🔍 _emitTypingOnNewMessage called');
    debugPrint('ChatView: 🔍 Mounted: $mounted');
    
    if (!mounted) return;
    
    try {
      debugPrint('ChatView: 📡 Adding StartTyping event to bloc');
      final chatBloc = context.read<ChatBloc>();
      chatBloc.add(const StartTyping());
      
      // Stop typing after a short delay to show they finished reading
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          try {
            debugPrint('ChatView: 📡 Adding StopTyping event to bloc (new message timer)');
            chatBloc.add(const StopTyping());
          } catch (e) {
            debugPrint('Error stopping typing after new message: $e');
          }
        } else {
          debugPrint('ChatView: ⚠️ Widget not mounted, skipping stop typing');
        }
      });
      debugPrint('ChatView: ✅ _emitTypingOnNewMessage completed');
    } catch (e) {
      debugPrint('Error emitting typing on new message: $e');
    }
  }

  // NEW: Mark messages as read when user scrolls to view them
  void _markMessagesAsReadOnScroll() {
    if (!mounted || _hasMarkedAsRead) return;
    
    // Cancel any existing timer
    _markAsReadDebounceTimer?.cancel();
    
    // Debounce the mark as read call to avoid too many API calls
    _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      try {
        final chatBloc = context.read<ChatBloc>();
        final currentState = chatBloc.state;
        
        if (currentState is chat_state.ChatLoaded && 
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

  // NEW: Mark messages as read when chat is loaded
  void _markMessagesAsReadOnChatLoad(chat_state.ChatLoaded state) {
    if (!mounted || _hasMarkedAsRead) return;
    
    try {
      final chatBloc = context.read<ChatBloc>();
      
      if (state.messages.isNotEmpty && chatBloc.currentRoomId != null) {
        // Check if there are unread messages
        final unreadMessages = state.messages.where((msg) => 
            !msg.isUserMessage && !msg.isRead).toList();
        
        if (unreadMessages.isNotEmpty) {
          // Mark all messages as read via API
          chatBloc.add(MarkAsRead(chatBloc.currentRoomId!));
          _hasMarkedAsRead = true;
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read on chat load: $e');
    }
  }

  // NEW: Mark messages as read when the user first views the chat screen
  void _markMessagesAsReadOnView() {
    if (!mounted || _hasMarkedAsRead) return;
    
    try {
      final chatBloc = context.read<ChatBloc>();
      
      if (chatBloc.state is chat_state.ChatLoaded && 
          chatBloc.currentRoomId != null) {
        // Mark all messages as read via API
        chatBloc.add(MarkAsRead(chatBloc.currentRoomId!));
        _hasMarkedAsRead = true;
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // NEW: Emit typing when chat page opens to trigger blue tick updates for previous messages
  void _emitTypingOnPageOpen() {
    if (!mounted) return;
    
    try {
      final chatBloc = context.read<ChatBloc>();
      chatBloc.add(const StartTyping());
      
      // Stop typing after a short delay to show they finished reading previous messages
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          try {
            chatBloc.add(const StopTyping());
          } catch (e) {
            // Handle error silently
          }
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          // Existing listener for chat errors and message updates
          BlocListener<ChatBloc, chat_state.ChatState>(
            listenWhen: (previous, current) {
              if (current is chat_state.ChatLoaded) {
                _checkForNewMessages(current.messages);
                
                // Mark messages as read when chat is loaded
                _markMessagesAsReadOnChatLoad(current);
                
                // FIXED: Allow listener to trigger for message updates
                return false; // Still don't trigger listener, but _checkForNewMessages is called
              }
              return current is chat_state.ChatError;
            },
            listener: (context, state) {
              if (state is chat_state.ChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<ChatBloc>().add(LoadChatData(widget.orderId));
                      },
                    ),
                  ),
                );
              }
            },
          ),
          
          // NEW: Add this listener for status update completion
          BlocListener<ChatBloc, chat_state.ChatState>(
            listenWhen: (previous, current) {
              // Listen specifically for status update completion
              if (previous is chat_state.ChatLoaded && current is chat_state.ChatLoaded) {
                return previous.lastUpdateTimestamp != current.lastUpdateTimestamp &&
                       current.lastUpdateSuccess == true;
              }
              return false;
            },
            listener: (context, state) {
              if (state is chat_state.ChatLoaded && state.lastUpdateSuccess == true) {
                // Status was successfully updated - show success snackbar
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Order status updated successfully!',
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
                
                // Refresh the entire chat view
                
                // Reload the chat data to get updated order info
                context.read<ChatBloc>().add(chat_event.LoadChatData(widget.orderId));
                
                // Also reload order details if they exist
                final currentState = state;
                if (currentState.orderDetails != null) {
                  context.read<ChatBloc>().add(chat_event.LoadOrderDetails(
                    orderId: widget.orderId,
                    partnerId: context.read<ChatBloc>().currentPartnerId ?? '',
                  ));
                }
              }
            },
          ),
          
          // NEW: Add listener for status update errors
          BlocListener<ChatBloc, chat_state.ChatState>(
            listenWhen: (previous, current) {
              // Listen specifically for status update errors
              if (previous is chat_state.ChatLoaded && current is chat_state.ChatLoaded) {
                return previous.lastUpdateTimestamp != current.lastUpdateTimestamp &&
                       current.lastUpdateSuccess == false;
              }
              return false;
            },
            listener: (context, state) {
              if (state is chat_state.ChatLoaded && state.lastUpdateSuccess == false && state.lastUpdateMessage != null) {
                // Status update failed - show error snackbar
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.lastUpdateMessage!,
                            style: const TextStyle(
                              fontWeight: FontWeightManager.medium,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ChatBloc, chat_state.ChatState>(
          builder: (context, state) {
            
            if (state is chat_state.ChatLoading) {
              return _buildLoadingState();
            } else if (state is chat_state.ChatLoaded) {
              return _buildChatContent(context, state);
            } else if (state is chat_state.ChatError) {
              return _buildErrorState(context, state);
            } else {
              return _buildLoadingState(); // Show loading for initial state
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

  Widget _buildChatContent(BuildContext context, chat_state.ChatLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, state),
          _buildOrderHeader(state.orderInfo),
          
          // Show status update indicator if updating
          if (state.isUpdatingOrderStatus)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.1),
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
                    'Updating order status...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeightManager.medium,
                    ),
                  ),
                ],
              ),
            ),
          
          // Order details will be shown as a chat bubble in the messages list
          
          Expanded(
            child: _buildMessagesList(context, state.messages),
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
          _buildMessageInput(context, state.isSendingMessage),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, chat_state.ChatLoaded state) {
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
    final chatBloc = context.read<ChatBloc>();
    final partnerId = chatBloc.currentPartnerId ?? '';
    final orderId = chatBloc.currentOrderId ?? widget.orderId;

    print('ChatView: Tapping order header');
    print('ChatView: Partner ID: $partnerId');
    print('ChatView: Full Order ID: $orderId');

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
        '/home', // You might need to adjust this route name
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

  // NEW: Build loading state for order details as chat bubble
  Widget _buildOrderDetailsLoadingChatBubble() {
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
          
          // Loading bubble
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
                  child: Row(
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
                              'Loading Order Details...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeightManager.medium,
                                color: ColorManager.black,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please wait',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Now',
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

  // NEW: Build order details as chat bubble
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

  Widget _buildMessagesList(BuildContext context, List<chat_state.ChatMessage> messages) {
    return BlocBuilder<ChatBloc, chat_state.ChatState>(
      builder: (context, state) {
        if (state is chat_state.ChatLoaded) {
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
              
              // Show loading bubble if order details are loading
              if (index == 0 && isLoadingOrderDetails) {
                return _buildOrderDetailsLoadingChatBubble();
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
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageBubble(chat_state.ChatMessage message) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // NOTE: message_seen is automatically emitted when receive_message is triggered
    // No need to manually mark messages as seen when displayed
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        mainAxisAlignment: message.isUserMessage 
            ? MainAxisAlignment.end     // Partner messages on RIGHT
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
                  ? CrossAxisAlignment.end    // Partner messages aligned to right
                  : CrossAxisAlignment.start, // Customer messages aligned to left
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUserMessage 
                        ? const Color(0xFFE17A47)  // Orange for partner
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
                          ? Colors.white          // White text for partner messages
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
                      // Show delivery status only for partner messages (sent by current user)
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

  Widget _buildMessageInput(BuildContext context, bool isSending) {
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
      child: Row(
        children: [
          // Status change icon button
          GestureDetector(
            onTap: () => _showStatusChangeBottomSheet(context),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.11,
              height: MediaQuery.of(context).size.width * 0.11,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.edit_note,
                  color: Colors.grey.shade600,
                  size: MediaQuery.of(context).size.width * 0.045,
                ),
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.028),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.038,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.055,
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !isSending,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade500,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.012,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                onChanged: _handleTyping,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.028),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.11,
              height: MediaQuery.of(context).size.width * 0.11,
              decoration: BoxDecoration(
                color: const Color(0xFFE17A47),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.045,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, chat_state.ChatError state) {
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
                        context.read<ChatBloc>().add(LoadChatData(widget.orderId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE17A47),
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

  void _showStatusChangeBottomSheet(BuildContext context) {
    final chatBloc = context.read<ChatBloc>();
    final partnerId = chatBloc.currentPartnerId ?? '';
    
    if (partnerId.isNotEmpty && widget.orderId.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatusChangeBottomSheet(
          orderId: widget.orderId,
          partnerId: partnerId,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to change status. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (mounted) {
      try {
        if (message.isNotEmpty) {
          context.read<ChatBloc>().add(SendMessage(message));
          _messageController.clear();
          
          // Ensure we scroll to bottom after sending
          _shouldAutoScroll = true;
          _scrollToBottom();
        } else {
          // Show feedback for empty message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a message to send'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}