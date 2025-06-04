// lib/presentation/screens/chat/view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_services.dart';
import '../../../ui_components/universal_widget/topbar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import 'bloc.dart';
import 'event.dart';
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

  @override
  void initState() {
    super.initState();
    // Remove the listener that was causing issues
    // We'll handle typing in the onChanged callback instead
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTyping(String text) {
    // Handle typing directly in the text field's onChanged
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
              // Ignore if bloc is disposed
            }
          }
        });
      }
    } catch (e) {
      // Ignore context errors during disposal
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(chatService: ChatService())
        ..add(LoadChatData(widget.orderId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<ChatBloc, chat_state.ChatState>(
          listener: (context, state) {
            if (state is chat_state.ChatLoaded) {
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
            
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
          builder: (context, state) {
            if (state is chat_state.ChatLoading) {
              return _buildLoadingState();
            } else if (state is chat_state.ChatLoaded) {
              return _buildChatContent(context, state);
            } else if (state is chat_state.ChatError) {
              return _buildErrorState(context, state);
            }
            
            return const SizedBox.shrink();
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
          _buildHeader(context),
          _buildOrderHeader(state.orderInfo),
          Expanded(
            child: _buildMessagesList(context, state.messages),
          ),
          _buildMessageInput(context, state.isSendingMessage),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            margin: const EdgeInsets.only(right: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.green,
                ),
                SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
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
    return Container(
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
    );
  }

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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.035),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(chat_state.ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.012,
      ),
      child: Row(
        mainAxisAlignment: message.isUserMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isUserMessage) const Spacer(),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment: message.isUserMessage 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.038,
                    vertical: MediaQuery.of(context).size.height * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUserMessage 
                        ? const Color(0xFFE17A47)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.038,
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      fontWeight: FontWeightManager.regular,
                      color: message.isUserMessage 
                          ? Colors.white 
                          : ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.028,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade500,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
          if (!message.isUserMessage) const Spacer(),
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
                onChanged: _handleTyping, // Handle typing here instead of listener
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
        context.read<ChatBloc>().add(SendMessage(message));
        _messageController.clear();
        
        // Stop typing
        if (_isTyping) {
          _isTyping = false;
          context.read<ChatBloc>().add(const StopTyping());
        }
      } catch (e) {
        // Handle any context errors gracefully
        debugPrint('Error sending message: $e');
      }
    }
  }
}