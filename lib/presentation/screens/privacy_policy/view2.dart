// lib/presentation/screens/privacy_policy/view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../resources/colors.dart';
import '../../resources/font.dart';

class PrivacyPolicyView2 extends StatefulWidget {
  const PrivacyPolicyView2({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyView2> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView2>
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
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ColorManager.background,
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with back button and title
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
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: ColorManager.primary,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              'Privacy Policy',
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
              Icons.privacy_tip,
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
            title: '1. About Bird',
            content: 'Bird is a food delivery application that allows customers to place orders and communicate directly with restaurants via real-time chat. Our goal is to provide a simple, transparent, and user-friendly delivery experience.',
          ),
          
          _buildSection(
            title: '2. Information We Collect',
            content: '''For Customers:
• Personal Information: Name, phone number, email (optional), delivery location
• Chat Data: Messages exchanged with restaurants after order placement
• Order Information: Order history, restaurant preferences, delivery method
• Device Information: IP address, device ID, operating system version, app usage data
• Optional: Profile picture (if uploaded), reviews or feedback

For Restaurants:
• Business Information: Restaurant name, phone number, email address, location
• Menu and Order Data: Menu listings, order records, delivery status
• Chat Data: Communication with customers
• Device Information: Same as above''',
          ),
          
          _buildSection(
            title: '3. How We Use Your Information',
            content: '''• To process and manage food orders
• To facilitate real-time communication between customers and restaurants
• To improve application performance and user experience
• To personalize services based on user preferences
• To ensure account security and prevent unauthorized access''',
          ),
          
          _buildSection(
            title: '4. Information Sharing and Disclosure',
            content: '''We do not sell or rent your personal information to third parties.

We may share data in the following circumstances:
• With restaurants you place orders with, for the purpose of delivery and communication
• With third-party service providers such as analytics and infrastructure tools (only limited and non-sensitive data)
• When legally required to do so under applicable law or in response to legal process''',
          ),
          
          _buildSection(
            title: '5. Data Security',
            content: 'We implement reasonable security measures to protect your data from unauthorized access, disclosure, or misuse. These measures include secure servers, encrypted communication channels, and access control. However, no system can be completely secure. You use Bird at your own risk.',
          ),
          
          _buildSection(
            title: '6. Your Rights and Choices',
            content: '''• You may edit or delete your personal profile at any time
• You may request deletion of your account and related data
• You have control over permissions such as location access and notifications
• Chat history is retained to support communication and delivery history''',
          ),
          
          _buildSection(
            title: '7. Use of Third-Party Services',
            content: '''Bird may use third-party services for:
• Real-time messaging infrastructure
• App analytics (e.g., Firebase, Google Analytics)
• Basic tracking of optional payment confirmations

These third-party providers operate under their own privacy policies. We encourage users to review those separately.''',
          ),
          
          _buildSection(
            title: '8. Children\'s Privacy',
            content: 'Bird is not designed for users under the age of 5. We do not knowingly collect personal information from children. If we discover such information has been collected, we will take steps to delete it promptly.',
          ),
          
          _buildSection(
            title: '9. Changes to This Policy',
            content: 'This Privacy Policy may be updated from time to time. We will notify users of any material changes by updating the policy within the app and/or on our website. Continued use of the application after updates indicates your acceptance of the revised policy.',
          ),
          
          _buildSection(
            title: '10. Contact Us',
            content: '''For questions or concerns about this Privacy Policy, please contact us at:

Email: env.bird@gmail.com
Website: www.bird.delivery''',
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
                  Icons.privacy_tip,
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
                      'Privacy Policy for Bird',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s20,
                        fontWeight: FontWeightManager.bold,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'Better Instant Real-Time Deliveries',
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
            'At Bird, we respect your privacy and are committed to protecting the personal information you share with us. This Privacy Policy describes how we collect, use, and protect your information when you use our platform—whether as a customer or a restaurant partner.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: ColorManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bird - Better Instant Real-Time Deliveries',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.primary,
                  ),
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