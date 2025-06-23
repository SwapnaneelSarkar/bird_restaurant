// lib/presentation/screens/chat/view.dart - FIXED VERSION WITH WHATSAPP-STYLE MESSAGE LAYOUT

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ui_components/universal_widget/order_widgets.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import 'bloc.dart';
import 'event.dart';
import 'event.dart' as chat_event;
import 'state.dart' as chat_state;

class ChatView extends StatefulWidget {
  final String orderId;
  
  const ChatView({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  int _previousMessageCount = 0;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    
    // Load chat data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatBloc>().add(LoadChatData(widget.orderId));
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
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTyping(String text) {
    if (!mounted) return;
    
    try {
      final chatBloc = context.read<ChatBloc>();
      
      if (text.isNotEmpty && !_isTyping) {
        _isTyping = true;
        chatBloc.add(const StartTyping());
      } else if (text.isEmpty && _isTyping) {
        _isTyping = false;
        chatBloc.add(const StopTyping());
      }
      
      // Reset typing timer
      _typingTimer?.cancel();
      if (text.isNotEmpty) {
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (_isTyping && mounted) {
            _isTyping = false;
            try {
              chatBloc.add(const StopTyping());
            } catch (e) {
              debugPrint('Error stopping typing: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error handling typing: $e');
    }
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
      debugPrint('ChatView: 📱 New messages detected (${messages.length} vs $_previousMessageCount), scrolling to bottom');
      _scrollToBottom();
    }
    _previousMessageCount = messages.length;
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
              return false; // Don't trigger listener for message updates
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
        
        // NEW: Add this listener for status updates
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
              debugPrint('ChatView: Status update successful, showing success snackbar');
              
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
              debugPrint('ChatView: Status update successful, refreshing view');
              
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
              debugPrint('ChatView: Status update failed, showing snackbar: ${state.lastUpdateMessage}');
              
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
          }
          
          return _buildLoadingState(); // Show loading for initial state
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
          const Expanded(
            child: AppBackHeader(title: 'Chat'),
          ),
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isConnected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  state.isConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: state.isConnected ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatBloc>().add(const RefreshChat());
            },
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
              Text(
                'Order ${orderInfo.orderId}',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.048,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
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

// 3. Add this new method to your _ChatViewState class:

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


// Updated _buildMessagesList method
Widget _buildMessagesList(BuildContext context, List<chat_state.ChatMessage> messages) {
  if (messages.isEmpty) {
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
    padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      return _buildMessageBubble(message);
    },
  );
}

// Updated _buildMessageBubble method

Widget _buildMessageBubble(chat_state.ChatMessage message) {
  debugPrint('ChatView: 🎯 Rendering message:');
  debugPrint('  - Content: ${message.message}');
  debugPrint('  - isUserMessage: ${message.isUserMessage}');
  debugPrint('  - isRead: ${message.isRead}'); // NEW: Log read status
  debugPrint('  - Should appear on: ${message.isUserMessage ? 'RIGHT (Partner)' : 'LEFT (Customer)'}');
  
  final screenWidth = MediaQuery.of(context).size.width;
  
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
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.11,
              height: MediaQuery.of(context).size.width * 0.11,
              decoration: BoxDecoration(
                color: isSending 
                    ? Colors.grey.shade400 
                    : const Color(0xFFE17A47),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isSending
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width * 0.035,
                        height: MediaQuery.of(context).size.width * 0.035,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && mounted) {
      try {
        debugPrint('ChatView: 📤 Sending message: $message');
        context.read<ChatBloc>().add(SendMessage(message));
        _messageController.clear();
        
        // Stop typing
        if (_isTyping) {
          _isTyping = false;
          context.read<ChatBloc>().add(const StopTyping());
        }
        
        // Ensure we scroll to bottom after sending
        _shouldAutoScroll = true;
        _scrollToBottom();
        
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