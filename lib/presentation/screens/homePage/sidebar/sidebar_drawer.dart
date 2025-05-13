import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math';

class SidebarDrawer extends StatefulWidget {
  final String? activePage;
  final String? restaurantName;
  final String? restaurantSlogan;

  const SidebarDrawer({
    Key? key,
    this.activePage,
    this.restaurantName,
    this.restaurantSlogan,
  }) : super(key: key);

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  
  // For menu item staggered animation
  late List<Animation<double>> _menuItemAnimations;
  final int _menuItemCount = 11; // Total number of menu items including logout

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with slower duration for more impressive animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    
    // Create slide animation with custom curve for smooth entrance
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint, // More pronounced easing
    ));
    
    // Create fade animation with slight delay
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
    ));
    
    // Create scale animation for subtle zoom effect
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    ));
    
    // Create blur animation for backdrop
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    ));
    
    // Create staggered animations for menu items - with safety checks to ensure intervals don't exceed 1.0
    _menuItemAnimations = List.generate(
      _menuItemCount,
      (index) {
        // Calculate start and end times, capping at 1.0
        final startTime = min(0.2 + (index * 0.05), 0.9);
        final endTime = min(0.6 + (index * 0.05), 1.0);
        
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              startTime, 
              endTime,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
      },
    );
    
    // Start the animation with haptic feedback
    HapticFeedback.lightImpact();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDrawer() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closeDrawer();
        return false;
      },
      child: Stack(
        children: [
          // Blurred and dimmed background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return GestureDetector(
                onTap: _closeDrawer,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(_fadeAnimation.value * 0.5),
                  ),
                ),
              );
            },
          ),
          
          // Sliding, scaling, and fading sidebar
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * _slideAnimation.value,
                  0,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildAnimatedSidebar(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedSidebar() {
    return AnimatedSidebarContent(
      animations: _menuItemAnimations,
      onClose: _closeDrawer,
      activePage: widget.activePage,
      restaurantName: widget.restaurantName ?? 'Spice Garden',
      restaurantSlogan: widget.restaurantSlogan ?? 'Fine Dining Restaurant',
    );
  }
}

// Separate widget for the animated sidebar content
class AnimatedSidebarContent extends StatelessWidget {
  final List<Animation<double>> animations;
  final VoidCallback onClose;
  final String? activePage;
  final String restaurantName;
  final String restaurantSlogan;

  const AnimatedSidebarContent({
    Key? key,
    required this.animations,
    required this.onClose,
    required this.activePage,
    required this.restaurantName,
    required this.restaurantSlogan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.78,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Animated header
            _buildAnimatedHeader(context, animations[0]),
            
            _buildDivider(),
            
            // Animated menu items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildAnimatedMenuItem(
                      animations[1],
                      icon: Icons.home_outlined,
                      title: 'Home',
                      isActive: activePage == 'home',
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[2],
                      icon: Icons.shopping_bag_outlined,
                      title: 'Orders',
                      isActive: activePage == 'orders',
                      onTap: () {
                        Navigator.of(context).pushNamed('/orders');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[3],
                      icon: Icons.inventory_2_outlined,
                      title: 'Products',
                      isActive: activePage == 'products',
                      onTap: () {
                        Navigator.of(context).pushNamed('/products');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[4],
                      icon: Icons.add_circle_outline,
                      title: 'Add Product',
                      isActive: activePage == 'addProduct',
                      onTap: () {
                        Navigator.of(context).pushNamed('/addProduct');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[5],
                      icon: Icons.view_list_outlined,
                      title: 'Add Attributes',
                      isActive: activePage == 'add_attributes',
                      onTap: () {
                        Navigator.of(context).pushNamed('/attributes');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[6],
                      icon: Icons.label_outline,
                      title: 'Restuarant Profile',
                      isActive: activePage == 'profile',
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[7],
                      icon: Icons.language_outlined,
                      title: 'Change Language',
                      isActive: activePage == 'language',
                      onTap: () {
                        Navigator.of(context).pushNamed('/language');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[8],
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      isActive: activePage == 'terms',
                      onTap: () {
                        Navigator.of(context).pushNamed('/terms');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[9],
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      isActive: activePage == 'privacy',
                      onTap: () {
                        Navigator.of(context).pushNamed('/privacy');
                        onClose();
                      },
                    ),
                    _buildAnimatedMenuItem(
                      animations[10],
                      icon: Icons.headset_mic_outlined,
                      title: 'Contact Us',
                      isActive: activePage == 'contact',
                      onTap: () {
                        Navigator.of(context).pushNamed('/contact');
                        onClose();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            _buildDivider(),
            
            // Animated logout button
            _buildAnimatedLogoutButton(context, animations[animations.length - 1]),
            
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                children: [
                  // Logo with subtle rotate animation
                  Transform.rotate(
                    angle: (1 - animation.value) * 0.1, // Subtle rotation
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 64,
                      width: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Restaurant Name
                  Text(
                    restaurantName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Restaurant Slogan
                  Text(
                    restaurantSlogan,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMenuItem(
    Animation<double> animation, {
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    // Colors for active state
    final activeColor = Colors.orange[700];
    final activeBgColor = Colors.orange[50];
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? activeBgColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: isActive ? activeColor : const Color(0xFF505050),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                            color: isActive ? activeColor : const Color(0xFF505050),
                          ),
                        ),
                      ],
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEEEEEE),
    );
  }

  Widget _buildAnimatedLogoutButton(BuildContext context, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleLogout(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 22,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
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

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      // Clear all stored data using SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Navigate to login and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still attempt to navigate even if clearing fails
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}