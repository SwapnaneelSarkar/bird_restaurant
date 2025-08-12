// lib/presentation/screens/terms_conditions/view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/restaurant_info_service.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';
import '../../resources/router/router.dart';

class TermsConditionsView extends StatefulWidget {
  const TermsConditionsView({Key? key}) : super(key: key);

  @override
  State<TermsConditionsView> createState() => _TermsConditionsViewState();
}

class _TermsConditionsViewState extends State<TermsConditionsView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.homePage, (route) => false);
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ColorManager.background,
        drawer: FutureBuilder<Map<String, String>>(
          future: RestaurantInfoService.getRestaurantInfo(),
          builder: (context, snapshot) {
            final info = snapshot.data ?? {};
            return SidebarDrawer(
              activePage: 'terms',
              restaurantName: info['name'],
              restaurantSlogan: info['slogan'],
              restaurantImageUrl: info['imageUrl'],
            );
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with sidebar and title
              _buildCustomAppBar(),
              
              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildContent(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sidebar menu button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu,
                color: ColorManager.primary,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              'Terms & Conditions',
              style: GoogleFonts.poppins(
                fontSize: FontSize.s22,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
          ),
          
          // Bird logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.article_outlined,
              color: ColorManager.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeaderSection(),
          
          const SizedBox(height: 32),
          
          // Content sections
          _buildSection(
            title: '1. Acceptance of Terms',
            content: 'By downloading, accessing, or using the Bird application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our service.',
          ),
          
          _buildSection(
            title: '2. Description of Service',
            content: '''Bird is a food delivery platform that connects customers with restaurant partners. Our service includes:
• Order placement and management
• Real-time communication between customers and restaurants
• Delivery coordination and tracking
• Payment processing (where applicable)
• Customer support and dispute resolution''',
          ),
          
          _buildSection(
            title: '3. User Accounts and Registration',
            content: '''• You must provide accurate, current, and complete information during registration
• You are responsible for maintaining the security of your account credentials
• You must notify us immediately of any unauthorized use of your account
• One account per user/restaurant is permitted
• You must be at least 13 years old to use our service''',
          ),
          
          _buildSection(
            title: '4. Acceptable Use Policy',
            content: '''You agree NOT to use the service to:
• Violate any applicable laws or regulations
• Harass, abuse, or harm other users
• Post false, misleading, or fraudulent information
• Interfere with the proper functioning of the app
• Use automated systems to access the service
• Share inappropriate content in chat communications
• Attempt to bypass security measures''',
          ),
          
          _buildSection(
            title: '5. Privacy and Data Protection',
            content: 'Your privacy is important to us. Our collection, use, and protection of your personal information is governed by our Privacy Policy, which is incorporated into these Terms by reference. By using Bird, you consent to our data practices as described in the Privacy Policy.',
          ),
          
          _buildSection(
            title: '6. Orders and Payments',
            content: '''• All orders are subject to restaurant acceptance
• Prices are set by individual restaurant partners
• Payment methods and processing are handled according to our payment policies
• You are responsible for any taxes applicable to your orders
• Delivery fees may apply and will be clearly disclosed
• Refunds and cancellations are handled according to our refund policy''',
          ),
          
          _buildSection(
            title: '7. Restaurant Partner Responsibilities',
            content: '''Restaurant partners agree to:
• Provide accurate menu information and pricing
• Maintain food safety and quality standards
• Respond promptly to customer communications
• Honor accepted orders in a timely manner
• Comply with all applicable health and safety regulations
• Provide accurate business information and documentation''',
          ),
          
          _buildSection(
            title: '8. Intellectual Property',
            content: '''• Bird and its logos are trademarks of our company
• You retain rights to content you create (reviews, messages)
• You grant us license to use your content for service operation
• Respect the intellectual property rights of others
• Report any suspected intellectual property violations''',
          ),
          
          _buildSection(
            title: '9. Limitation of Liability',
            content: '''• Bird provides the platform "as is" without warranties
• We are not liable for food quality, safety, or delivery issues beyond our control
• Our liability is limited to the maximum extent permitted by law
• We are not responsible for disputes between customers and restaurants
• Use of third-party services is at your own risk''',
          ),
          
          _buildSection(
            title: '10. Dispute Resolution',
            content: '''• First, try to resolve issues through our customer support
• Mediation may be required for certain disputes
• Any legal disputes will be governed by applicable local laws
• Class action waivers may apply where legally permitted
• Arbitration may be required for certain types of disputes''',
          ),
          
          _buildSection(
            title: '11. Service Modifications and Termination',
            content: '''• We may modify, suspend, or terminate the service with notice
• You may terminate your account at any time
• We may suspend accounts for violations of these terms
• Certain provisions survive account termination
• We will provide reasonable notice for major service changes''',
          ),
          
          _buildSection(
            title: '12. Updates to Terms',
            content: 'We may update these Terms and Conditions from time to time. We will notify users of material changes through the app or other communication methods. Continued use of the service after changes constitutes acceptance of the updated terms.',
          ),
          
          _buildSection(
            title: '13. Contact Information',
            content: '''For questions about these Terms and Conditions, please contact us:

Email: env.bird@gmail.com
Website: www.bird.delivery

We aim to respond to all inquiries within 24-48 hours.''',
          ),
          
          // Footer
          const SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primary.withOpacity(0.1),
            ColorManager.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorManager.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s20,
                        fontWeight: FontWeightManager.bold,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'Bird - Better Instant Real-Time Deliveries',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s14,
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildInfoRow('Effective Date:', '5-6-2025'),
          const SizedBox(height: 8),
          _buildInfoRow('Last Updated:', '5-6-2025'),
          
          const SizedBox(height: 20),
          
          Text(
            'These Terms and Conditions ("Terms") govern your use of the Bird food delivery application and services. By accessing or using our platform, you agree to be bound by these Terms.',
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.regular,
              color: ColorManager.textgrey2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s12,
            fontWeight: FontWeightManager.semiBold,
            color: ColorManager.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s12,
            fontWeight: FontWeightManager.regular,
            color: ColorManager.textgrey2,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.bold,
              color: ColorManager.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.regular,
              color: ColorManager.textgrey2,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: ColorManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bird - Better Instant Real-Time Deliveries',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This document was last updated on 5-6-2025',
            style: GoogleFonts.poppins(
              fontSize: FontSize.s12,
              fontWeight: FontWeightManager.regular,
              color: ColorManager.textgrey2,
            ),
          ),
        ],
      ),
    );
  }
}