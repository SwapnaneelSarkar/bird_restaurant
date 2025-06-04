// lib/presentation/screens/chat_list/view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../models/chat_room_model.dart';
import '../../../ui_components/universal_widget/nav_bar.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../chat/view.dart';
import '../homePage/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({Key? key}) : super(key: key);

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> with TickerProviderStateMixin {
  late ChatListBloc _chatListBloc;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  late AnimationController _searchAnimationController;
  late Animation<double> _searchSlideAnimation;
  late Animation<double> _searchFadeAnimation;
  bool _isSearchExpanded = false;
  
  // Bottom navigation
  int _selectedIndex = 1; // Set to 1 since this is the chat screen

  @override
  void initState() {
    super.initState();
    _chatListBloc = ChatListBloc()..add(const LoadChatRooms());
    
    // Initialize search animations
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _searchFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    // Add listener for search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _chatListBloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    _chatListBloc.add(SearchChatRooms(_searchController.text));
  }

  Future<void> _handleRefresh() async {
    _chatListBloc.add(const RefreshChatRooms());
    return Future.delayed(const Duration(seconds: 1));
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    
    if (_isSearchExpanded) {
      _searchAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchAnimationController.reverse();
      _searchFocusNode.unfocus();
      _searchController.clear();
      _chatListBloc.add(const ClearSearch());
    }
  }

  void _onBottomNavTapped(int index) {
    if (index != _selectedIndex) {
      if (index == 0) {
        // Navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeView(),
          ),
        );
      }
      // If index == 1, we're already on the chat list page, so do nothing
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatListBloc,
      child: BlocConsumer<ChatListBloc, ChatListState>(
        listener: (context, state) {
          // Handle navigation when a chat room is selected
          if (state is ChatListLoaded) {
            // This would be handled by the SelectChatRoom event in the UI
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      Expanded(
                        child: _buildBody(state),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Navigation
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomNavigationWidget(
                    selectedIndex: _selectedIndex,
                    onItemTapped: _onBottomNavTapped,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Chats',
                style: TextStyle(
                  fontSize: FontSize.s20,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleSearch,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isSearchExpanded 
                      ? ColorManager.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isSearchExpanded ? Icons.close : Icons.search,
                  color: _isSearchExpanded 
                      ? ColorManager.primary 
                      : ColorManager.black,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchSlideAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _searchSlideAnimation.value,
            child: FadeTransition(
              opacity: _searchFadeAnimation,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(
                      fontSize: FontSize.s14,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: FontSize.s14,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _chatListBloc.add(const ClearSearch());
                              },
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ChatListState state) {
    if (state is ChatListLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is ChatListError) {
      return _buildErrorState(state.message);
    } else if (state is ChatListEmpty) {
      return _buildEmptyState(state.message);
    } else if (state is ChatListLoaded) {
      if (state.isSearching && state.filteredChatRooms.isEmpty) {
        return _buildSearchEmptyState(state.searchQuery);
      }
      return _buildChatList(state.filteredChatRooms);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildChatList(List<ChatRoom> chatRooms) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: ColorManager.primary,
      backgroundColor: Colors.white,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 120), // Add bottom padding for nav bar
        itemCount: chatRooms.length,
        separatorBuilder: (context, index) => Container(
          height: 0.5,
          color: Colors.grey[200],
          margin: const EdgeInsets.only(left: 80),
        ),
        itemBuilder: (context, index) {
          final chatRoom = chatRooms[index];
          return _buildChatItem(chatRoom);
        },
      ),
    );
  }

  Widget _buildChatItem(ChatRoom chatRoom) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _chatListBloc.add(SelectChatRoom(
            roomId: chatRoom.roomId,
            orderId: chatRoom.orderId,
          ));
          
          // Navigate to chat screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatView(orderId: chatRoom.orderId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: ColorManager.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Chat details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Order ID as title
                        Expanded(
                          child: Text(
                            'Order #${chatRoom.orderId.substring(chatRoom.orderId.length - 8)}',
                            style: TextStyle(
                              fontSize: FontSize.s16,
                              fontWeight: FontWeightManager.semiBold,
                              color: ColorManager.black,
                              fontFamily: FontFamily.Montserrat,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Time
                        Text(
                          chatRoom.formattedTime,
                          style: TextStyle(
                            fontSize: FontSize.s12,
                            color: Colors.grey[600],
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Last message
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatRoom.displayMessage,
                            style: TextStyle(
                              fontSize: FontSize.s14,
                              color: chatRoom.lastMessage.isEmpty 
                                  ? Colors.grey[500]
                                  : Colors.grey[700],
                              fontFamily: FontFamily.Montserrat,
                              fontStyle: chatRoom.lastMessage.isEmpty 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Message indicator (you can add unread count here)
                        if (chatRoom.lastMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 16,
                            ),
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

  Widget _buildEmptyState(String message) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: ColorManager.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Chats Yet',
                    style: TextStyle(
                      fontSize: FontSize.s20,
                      fontWeight: FontWeightManager.semiBold,
                      color: ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Start conversations with your customers when they place orders',
                      style: TextStyle(
                        fontSize: FontSize.s14,
                        color: Colors.grey[600],
                        fontFamily: FontFamily.Montserrat,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleRefresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: FontSize.s14,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: FontSize.s18,
              fontWeight: FontWeightManager.semiBold,
              color: ColorManager.black,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No chats found for "$query".\nTry searching with a different term.',
              style: TextStyle(
                fontSize: FontSize.s14,
                color: Colors.grey[600],
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _chatListBloc.add(const ClearSearch());
            },
            child: Text(
              'Clear Search',
              style: TextStyle(
                color: ColorManager.primary,
                fontSize: FontSize.s14,
                fontWeight: FontWeightManager.medium,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: ColorManager.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: FontSize.s18,
                      fontWeight: FontWeightManager.semiBold,
                      color: ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: FontSize.s14,
                        color: Colors.grey[600],
                        fontFamily: FontFamily.Montserrat,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleRefresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: FontSize.s14,
                            fontWeight: FontWeightManager.medium,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorManager.primary,
                          side: BorderSide(color: ColorManager.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: FontSize.s14,
                            fontWeight: FontWeightManager.medium,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}