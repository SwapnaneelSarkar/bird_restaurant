// TODO: Updated for delivery partner login routing
// lib/presentation/screens/partner_selection/view.dart

import 'dart:ui';
import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:bird_restaurant/presentation/resources/font.dart';
import 'package:bird_restaurant/presentation/resources/router/router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class PartnerSelectionView extends StatefulWidget {
  const PartnerSelectionView({Key? key}) : super(key: key);

  @override
  State<PartnerSelectionView> createState() => _PartnerSelectionViewState();
}

class _PartnerSelectionViewState extends State<PartnerSelectionView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _gradientController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _gradientColor1 = ColorTween(
      begin: ColorManager.primary.withOpacity(0.10),
      end: ColorManager.primary.withOpacity(0.18),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    _gradientColor2 = ColorTween(
      begin: Colors.orange.withOpacity(0.06),
      end: Colors.deepOrange.withOpacity(0.10),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _navigateToAuth(String partnerType) {
    if (partnerType == 'delivery') {
      Navigator.pushNamed(context, Routes.deliveryPartnerSignin);
    } else {
      Navigator.pushNamed(context, Routes.signin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      _gradientColor1.value ?? ColorManager.primary.withOpacity(0.18),
                      _gradientColor2.value ?? Colors.orange.withOpacity(0.10),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating accent circles
          Positioned(
            left: -size.width * 0.2,
            top: size.height * 0.15,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gradientColor2.value?.withOpacity(0.07) ??
                        Colors.orange.withOpacity(0.07),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            right: -size.width * 0.3,
            bottom: size.height * 0.2,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gradientColor1.value?.withOpacity(0.05) ??
                        ColorManager.primary.withOpacity(0.05),
                  ),
                );
              },
            ),
          ),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.06,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header section
                          Column(
                            children: [
                              SizedBox(height: size.height * 0.08),
                              
                              // Logo section
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ColorManager.primary.withOpacity(0.15),
                                      ColorManager.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorManager.primary.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.business_center,
                                  size: 50,
                                  color: ColorManager.primary,
                                ),
                              ),
                              
                              SizedBox(height: size.height * 0.03),
                              
                              // Welcome text
                              Text(
                                'Welcome to',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeightManager.medium,
                                  color: ColorManager.textgrey2,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // App name
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    ColorManager.primary,
                                    Colors.deepOrange,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'BIRD PARTNER',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeightManager.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Subtitle
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'Choose your partner type to get started',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeightManager.regular,
                                    color: ColorManager.textgrey2.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: size.height * 0.06),
                            ],
                          ),
                          
                          // Partner options section
                          Column(
                            children: [
                              // Restaurant Partner Option
                              _buildPartnerOption(
                                context: context,
                                title: 'Enter as Restaurant Partner',
                                subtitle: 'List your restaurant and reach more customers',
                                icon: Icons.restaurant,
                                onTap: () => _navigateToAuth('restaurant'),
                                delay: 200,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // OR divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            ColorManager.textgrey2.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeightManager.medium,
                                        color: ColorManager.textgrey2.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            ColorManager.textgrey2.withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Delivery Partner Option
                              _buildPartnerOption(
                                context: context,
                                title: 'Enter as Delivery Partner',
                                subtitle: 'Join our delivery network and start earning',
                                icon: Icons.delivery_dining,
                                onTap: () => _navigateToAuth('delivery'),
                                delay: 400,
                              ),
                            ],
                          ),
                          
                          // Footer
                          Column(
                            children: [
                              SizedBox(height: size.height * 0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'By continuing, you agree to our Terms & Conditions',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeightManager.regular,
                                    color: ColorManager.textgrey2.withOpacity(0.6),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.primary.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorManager.primary.withOpacity(0.2),
                            ColorManager.primary.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: ColorManager.primary,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeightManager.semiBold,
                              color: ColorManager.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeightManager.regular,
                              color: ColorManager.textgrey2.withOpacity(0.8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Arrow icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorManager.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: ColorManager.primary.withOpacity(0.8),
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
  }
}