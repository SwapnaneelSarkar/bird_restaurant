// lib/ui_components/chat_item_card.dart

import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class ChatItemCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;
  final bool showUnreadIndicator;
  final int unreadCount;

  const ChatItemCard({
    Key? key,
    required this.chatRoom,
    required this.onTap,
    this.showUnreadIndicator = false,
    this.unreadCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: ColorManager.primary.withOpacity(0.1),
        highlightColor: ColorManager.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online status
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary.withOpacity(0.2),
                          ColorManager.primary.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorManager.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: ColorManager.primary,
                      size: 26,
                    ),
                  ),
                  
                  // Online status indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 14),
              
              // Chat details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Order ID as title with customer info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${_getShortOrderId(chatRoom.orderId)}',
                                style: TextStyle(
                                  fontSize: FontSize.s16,
                                  fontWeight: showUnreadIndicator && unreadCount > 0
                                      ? FontWeightManager.bold
                                      : FontWeightManager.semiBold,
                                  color: ColorManager.black,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (chatRoom.userParticipant != null)
                                Text(
                                  'Customer ID: ${_getShortUserId(chatRoom.userParticipant!.userId)}',
                                  style: TextStyle(
                                    fontSize: FontSize.s12,
                                    color: Colors.grey[600],
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        
                        // Time and unread count
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              chatRoom.formattedTime,
                              style: TextStyle(
                                fontSize: FontSize.s12,
                                color: showUnreadIndicator && unreadCount > 0
                                    ? ColorManager.primary
                                    : Colors.grey[600],
                                fontWeight: showUnreadIndicator && unreadCount > 0
                                    ? FontWeightManager.medium
                                    : FontWeightManager.regular,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                            
                            if (showUnreadIndicator && unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorManager.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Last message with status
                    Row(
                      children: [
                        // Message status icon (if it's partner's message)
                        if (chatRoom.lastMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.done, // You can make this dynamic based on message status
                              size: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        
                        Expanded(
                          child: Text(
                            chatRoom.displayMessage,
                            style: TextStyle(
                              fontSize: FontSize.s14,
                              color: chatRoom.lastMessage.isEmpty 
                                  ? Colors.grey[500]
                                  : showUnreadIndicator && unreadCount > 0
                                      ? ColorManager.black
                                      : Colors.grey[700],
                              fontFamily: FontFamily.Montserrat,
                              fontStyle: chatRoom.lastMessage.isEmpty 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                              fontWeight: showUnreadIndicator && unreadCount > 0
                                  ? FontWeightManager.medium
                                  : FontWeightManager.regular,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Chevron indicator
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortOrderId(String orderId) {
    if (orderId.length <= 8) return orderId;
    return orderId.substring(orderId.length - 8);
  }

  String _getShortUserId(String userId) {
    if (userId.length <= 10) return userId;
    return userId.substring(userId.length - 10);
  }
}