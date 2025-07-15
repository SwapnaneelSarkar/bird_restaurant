// lib/presentation/screens/contact_us/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/restaurant_info_service.dart';
import '../../resources/colors.dart';
import '../../resources/font.dart';
import '../homePage/sidebar/sidebar_drawer.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({Key? key}) : super(key: key);

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Contact form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
              activePage: 'contact',
              restaurantName: info['name'],
              restaurantSlogan: info['slogan'],
              restaurantImageUrl: info['imageUrl'],
            );
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
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
              'Contact Us',
              style: GoogleFonts.poppins(
                fontSize: FontSize.s22,
                fontWeight: FontWeightManager.bold,
                color: ColorManager.black,
              ),
            ),
          ),
          
          // Contact icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.headset_mic,
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
          
          // Contact methods
          _buildContactMethods(),
                    
          const SizedBox(height: 32),
          
          // Additional info
          _buildAdditionalInfo(),
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
                  Icons.support_agent,
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
                      'Get in Touch',
                      style: GoogleFonts.poppins(
                        fontSize: FontSize.s20,
                        fontWeight: FontWeightManager.bold,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'We\'re here to help you',
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
          
          Text(
            'Have questions, feedback, or need support? We\'d love to hear from you! Our team is dedicated to providing you with the best possible experience on Bird.',
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

  Widget _buildContactMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Methods',
          style: GoogleFonts.poppins(
            fontSize: FontSize.s18,
            fontWeight: FontWeightManager.bold,
            color: ColorManager.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Phone contact
        _buildContactCard(
          icon: Icons.phone,
          title: 'Phone Support',
          subtitle: 'Call us directly for immediate assistance',
          contact: '1111111111',
          onTap: () => _makePhoneCall('1111111111'),
        ),
        
        const SizedBox(height: 16),
        
        // Email contact
        _buildContactCard(
          icon: Icons.email,
          title: 'Email Support',
          subtitle: 'Send us an email for detailed inquiries',
          contact: 'env.bird@gmail.com',
          onTap: () => _sendEmail('env.bird@gmail.com'),
        ),
        
        const SizedBox(height: 16),
        
        // Website contact
        _buildContactCard(
          icon: Icons.language,
          title: 'Visit Our Website',
          subtitle: 'Learn more about Bird services',
          contact: 'www.bird.delivery',
          onTap: () => _openWebsite('https://www.bird.delivery'),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String contact,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(
            color: ColorManager.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: ColorManager.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeightManager.semiBold,
                      color: ColorManager.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s12,
                      fontWeight: FontWeightManager.regular,
                      color: ColorManager.textgrey2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact,
                    style: GoogleFonts.poppins(
                      fontSize: FontSize.s14,
                      fontWeight: FontWeightManager.medium,
                      color: ColorManager.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: ColorManager.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAdditionalInfo() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: ColorManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Support Hours',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '• Monday - Friday: 9:00 AM - 6:00 PM IST\n• Saturday: 10:00 AM - 4:00 PM IST\n• Sunday: Closed (Emergency support available)\n• Average response time: 24-48 hours',
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.regular,
              color: ColorManager.textgrey2,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ColorManager.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'For urgent matters, please call our support line directly.',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s12,
                    fontWeight: FontWeightManager.medium,
                    color: ColorManager.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for contact actions
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar('Could not launch phone dialer');
        // Copy to clipboard as fallback
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        _showSnackBar('Phone number copied to clipboard');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Bird App Support Request',
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar('Could not launch email client');
        // Copy to clipboard as fallback
        await Clipboard.setData(ClipboardData(text: email));
        _showSnackBar('Email address copied to clipboard');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _openWebsite(String url) async {
    final Uri launchUri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch website');
        // Copy to clipboard as fallback
        await Clipboard.setData(ClipboardData(text: url));
        _showSnackBar('Website URL copied to clipboard');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically send the message to your backend
      // For now, we'll just show a success message
      _showSnackBar('Message sent successfully! We\'ll get back to you soon.');
      
      // Clear form
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
          ),
        ),
        backgroundColor: ColorManager.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}