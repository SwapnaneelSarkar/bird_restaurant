// lib/presentation/screens/splash/view.dart

import 'dart:async';
import 'dart:math';
import 'package:bird_restaurant/services/delivery_partner_services/delivery_partner_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../../resources/colors.dart';
import '../../resources/router/router.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Animation controllers - reduced complexity
  late final AnimationController _logoAnimationController;
  late final AnimationController _textAnimationController;
  late final AnimationController _gradientController;
  late final Animation<Color?> _gradientColor1;
  late final Animation<Color?> _gradientColor2;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  late final AnimationController _typewriterController;
  int _typewriterLength = 0;
  late final AnimationController _versionController;
  late final Animation<Offset> _versionOffset;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  
  // Performance monitoring
  late Timer _performanceTimer;
  int _frameCount = 0;
  DateTime _startTime = DateTime.now();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    developer.log('🎬 SplashView initState started', name: 'BirdRestaurant');
    
    try {
      // Set status bar color
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
      
      _initializeAnimations();
      _startPerformanceMonitoring();
      
      // Check authentication after animations with better timing
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (!_isDisposed) {
          _checkAuthentication();
        }
      });
      
      developer.log('✅ SplashView initState completed', name: 'BirdRestaurant');
    } catch (e, stackTrace) {
      developer.log('❌ Error in SplashView initState: $e', name: 'BirdRestaurant');
      developer.log('📚 Stack trace: $stackTrace', name: 'BirdRestaurant');
      // Continue with basic functionality
    }
  }
  
  void _initializeAnimations() {
    try {
      // Initialize logo animation
      _logoAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      
      _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _logoAnimationController,
          curve: Curves.elasticOut,
        ),
      );
      
      _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _logoAnimationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
      );
      
      // Initialize text animation
      _textAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      
      _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textAnimationController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
        ),
      );
      
      _textSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _textAnimationController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
        ),
      );
      

      
      // Animated gradient background
      _gradientController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat(reverse: true);
      
      _gradientColor1 = ColorTween(
        begin: ColorManager.primary.withOpacity(0.10),
        end: ColorManager.primary.withOpacity(0.18),
      ).animate(CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut));
      
      _gradientColor2 = ColorTween(
        begin: Colors.orange.withOpacity(0.06),
        end: Colors.deepOrange.withOpacity(0.10),
      ).animate(CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut));
      
      // Glowing logo
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      
      _glowAnimation = Tween<double>(begin: 0.08, end: 0.18).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
      );
      
      // Typewriter effect for app name
      _typewriterController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      
      _typewriterController.addListener(() {
        if (mounted && !_isDisposed) {
          setState(() {
            _typewriterLength = (_typewriterController.value * 'BIRD PARTNER'.length)
                .clamp(0, 'BIRD PARTNER'.length).toInt();
          });
        }
      });
      
      _typewriterController.forward();
      
      // Version animation
      _versionController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      
      _versionOffset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(parent: _versionController, curve: Curves.easeOut));
      
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!_isDisposed) {
          _versionController.forward();
        }
      });
      
      // Start animation sequence
      _startAnimationSequence();
      
      developer.log('✅ Animations initialized successfully', name: 'BirdRestaurant');
    } catch (e, stackTrace) {
      developer.log('❌ Error initializing animations: $e', name: 'BirdRestaurant');
      developer.log('📚 Stack trace: $stackTrace', name: 'BirdRestaurant');
    }
  }
  
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDisposed) {
        final elapsed = DateTime.now().difference(_startTime).inSeconds;
        developer.log('📊 Performance check - Elapsed: ${elapsed}s, Frames: $_frameCount', name: 'BirdRestaurant');
        
        // If we've been running for more than 20 seconds, something might be wrong
        if (elapsed > 20) {
          developer.log('⚠️ Splash screen running for too long, forcing navigation', name: 'BirdRestaurant');
          _forceNavigation();
        }
      }
    });
  }
  
  void _forceNavigation() {
    try {
      if (!_isDisposed && mounted) {
        developer.log('🔄 Forcing navigation to signin', name: 'BirdRestaurant');
        Navigator.of(context).pushReplacementNamed(Routes.signin);
      }
    } catch (e) {
      developer.log('❌ Error in force navigation: $e', name: 'BirdRestaurant');
    }
  }
  
  void _startAnimationSequence() {
    try {
      // Start logo animation after a short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isDisposed) {
          _logoAnimationController.forward();
        }
      });
      
      // Start text animation after logo
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!_isDisposed) {
          _textAnimationController.forward();
        }
      });
      

    } catch (e) {
      developer.log('❌ Error in animation sequence: $e', name: 'BirdRestaurant');
    }
  }

  @override
  void dispose() {
    developer.log('🗑️ SplashView dispose called', name: 'BirdRestaurant');
    _isDisposed = true;
    
    try {
      _logoAnimationController.dispose();
      _textAnimationController.dispose();
      _gradientController.dispose();
      _glowController.dispose();
      _typewriterController.dispose();
      _versionController.dispose();
      _performanceTimer.cancel();
    } catch (e) {
      developer.log('❌ Error disposing animations: $e', name: 'BirdRestaurant');
    }
    
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    if (_isDisposed) return;
    
    developer.log('🔐 Starting authentication check', name: 'BirdRestaurant');
    
    try {
      // Check for restaurant partner authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final mobileNumber = prefs.getString('mobile');
      
      // Check for delivery partner authentication
      final isDeliveryPartnerAuthenticated = await DeliveryPartnerAuthService.isDeliveryPartnerAuthenticated();
      
      developer.log('Restaurant Token: ${token != null ? 'exists' : 'null'}', name: 'BirdRestaurant');
      developer.log('Restaurant Mobile: $mobileNumber', name: 'BirdRestaurant');
      developer.log('Delivery Partner Authenticated: $isDeliveryPartnerAuthenticated', name: 'BirdRestaurant');
      
      // If delivery partner is authenticated, navigate to delivery partner home
      if (isDeliveryPartnerAuthenticated) {
        developer.log('✅ Delivery partner authenticated, navigating to delivery partner home', name: 'BirdRestaurant');
        _navigateToDeliveryPartnerHome();
        return;
      }
      
      // If no restaurant token or mobile number, go to partner selection
      if (token == null || token.isEmpty || mobileNumber == null || mobileNumber.isEmpty) {
        developer.log('No restaurant token or mobile, going to partner selection', name: 'BirdRestaurant');
        _navigateToLoginScreen();
        return;
      }

      // Set up headers with token
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Call API to check application status with timeout
      final uri = Uri.parse('https://api.bird.delivery/api/partner/getDetailsByMobile?mobile=$mobileNumber');
      developer.log('Calling API: $uri', name: 'BirdRestaurant');
      
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      
      developer.log('Response status: ${response.statusCode}', name: 'BirdRestaurant');

      // If unauthorized, go to login
      if (response.statusCode == 401) {
        developer.log('Unauthorized, going to sign in', name: 'BirdRestaurant');
        _navigateToLoginScreen();
        return;
      }

      // If successful response, check the status
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Response data: $data', name: 'BirdRestaurant');
        
        if (data['status'] == 'SUCCESS') {
          final restaurantData = data['data'];
          final status = restaurantData['status'];
          developer.log('Application status: $status', name: 'BirdRestaurant');
          
          // If approved (status = 1), go to home
          if (status == 1) {
            developer.log('Approved, going to home', name: 'BirdRestaurant');
            _navigateToHomeScreen();
            return;
          }
          // If pending (status = 2) or rejected (status = 7), go to application status
          else if (status == 2 || status == 7) {
            developer.log('Pending/Rejected, going to application status', name: 'BirdRestaurant');
            _navigateToHomeScreen();
            return;
          }
          // For any other status, go to application status
          else {
            developer.log('Other status, going to application status', name: 'BirdRestaurant');
            _navigateToApplicationStatusScreen(mobileNumber);
            return;
          }
        }
      }
      
      // For any other case, go to sign in
      developer.log('Default case, going to sign in', name: 'BirdRestaurant');
      _navigateToLoginScreen();
      
    } catch (e, stackTrace) {
      developer.log('❌ Error checking authentication: $e', name: 'BirdRestaurant');
      developer.log('📚 Stack trace: $stackTrace', name: 'BirdRestaurant');
      // If there's any error, default to sign in
      _navigateToLoginScreen();
    }
  }

  void _navigateToLoginScreen() {
    if (_isDisposed || !mounted) return;
    
    try {
      developer.log('🔄 Navigating to partner selection screen', name: 'BirdRestaurant');
      Navigator.of(context).pushReplacementNamed(Routes.partnerSelection);
    } catch (e) {
      developer.log('❌ Error navigating to partner selection: $e', name: 'BirdRestaurant');
    }
  }

  void _navigateToHomeScreen() {
    if (_isDisposed || !mounted) return;
    
    try {
      developer.log('🔄 Navigating to home screen', name: 'BirdRestaurant');
      Navigator.of(context).pushReplacementNamed(Routes.homePage);
    } catch (e) {
      developer.log('❌ Error navigating to home: $e', name: 'BirdRestaurant');
    }
  }

  void _navigateToApplicationStatusScreen(String mobileNumber) {
    if (_isDisposed || !mounted) return;
    
    try {
      developer.log('🔄 Navigating to application status screen', name: 'BirdRestaurant');
      Navigator.of(context).pushReplacementNamed(
        Routes.applicationStatus,
        arguments: mobileNumber,
      );
    } catch (e) {
      developer.log('❌ Error navigating to application status: $e', name: 'BirdRestaurant');
    }
  }

  void _navigateToDeliveryPartnerHome() {
    if (_isDisposed || !mounted) return;
    
    try {
      developer.log('🔄 Navigating to delivery partner dashboard', name: 'BirdRestaurant');
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.deliveryPartnerDashboard,
        (route) => false,
      );
    } catch (e) {
      developer.log('❌ Error navigating to delivery partner home: $e', name: 'BirdRestaurant');
    }
  }

  @override
  Widget build(BuildContext context) {
    _frameCount++;
    
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
          // Floating accent circle
          Positioned(
            left: -size.width * 0.2,
            top: size.height * 0.18,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gradientColor2.value?.withOpacity(0.07) ?? Colors.orange.withOpacity(0.07),
                  ),
                );
              },
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with glow
                FadeTransition(
                  opacity: _logoOpacityAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: size.width * 0.3,
                          height: size.width * 0.3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorManager.primary.withOpacity(_glowAnimation.value),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              semanticLabel: 'Bird Partner Logo',
                              errorBuilder: (context, error, stackTrace) {
                                developer.log('❌ Error loading logo image: $error', name: 'BirdRestaurant');
                                return Container(
                                  width: size.width * 0.3,
                                  height: size.width * 0.3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorManager.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    size: size.width * 0.15,
                                    color: ColorManager.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Typewriter app name
                FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Text(
                      'BIRD PARTNER'.substring(0, _typewriterLength),
                      style: GoogleFonts.poppins(
                        color: ColorManager.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Animated slogan
                FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Text(
                      'Delivering Excellence',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700] ?? Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Partner with us for success',
                      style: GoogleFonts.poppins(
                        color: ColorManager.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
                SlideTransition(
                  position: _versionOffset,
                  child: Text(
                    'v1.0.0',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400] ?? Colors.grey,
                      fontSize: 12,
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
}

// Particle model for animated particles
class ParticleModel {
  Offset position;
  double size;
  double opacity;
  double speed;
  double angle;
  
  ParticleModel({
    required this.position,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.angle,
  });
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  
  ParticlePainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        center + particle.position,
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Custom Dot Pulse Loader Animation
class DotPulseLoader extends StatefulWidget {
  final double dotSize;
  final Color color;
  final Duration duration;

  const DotPulseLoader({
    Key? key, 
    this.dotSize = 12.0, 
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<DotPulseLoader> createState() => _DotPulseLoaderState();
}

class _DotPulseLoaderState extends State<DotPulseLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    // Create 3 animation controllers for the 3 dots
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat(),
    );
    
    // Stagger the start of each animation
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted && _controllers[i].isAnimating) {
          _controllers[i].forward();
        }
      });
    }
    
    // Create animations for each dot
    _animations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          weight: 30,
        ),
      ]).animate(controller);
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _animations[index].value,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
// Alternative Custom Loading Animation

// Wave Loading Animation
class WaveLoader extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const WaveLoader({
    Key? key,
    this.color = Colors.white,
    this.size = 40.0,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size * 3.5,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              animation: _controller,
              color: widget.color,
            ),
            size: Size(widget.size * 3.5, widget.size),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  
  _WavePainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.2),
          color,
          color.withOpacity(0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    
    final centerY = size.height / 2;
    final waveHeight = size.height * 0.3;
    final frequency = 2.0;
    final path = Path();
    
    path.moveTo(0, centerY);
    
    for (double x = 0; x < size.width; x++) {
      final relativeX = x / size.width;
      final phase = animation.value * 2 * pi;
      final y = centerY + sin((relativeX * frequency * pi) + phase) * waveHeight;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, centerY);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}

// Text Loading Animation
class TextLoadingAnimation extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const TextLoadingAnimation({
    Key? key,
    required this.text,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  }) : super(key: key);
  
  @override
  State<TextLoadingAnimation> createState() => _TextLoadingAnimationState();
}

class _TextLoadingAnimationState extends State<TextLoadingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final List<Animation<double>> _letterAnimations = [];
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 150),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Create animations for each letter
    final letterCount = widget.text.length;
    for (int i = 0; i < letterCount; i++) {
      final start = i / letterCount;
      final end = (i + 1) / letterCount;
      
      _letterAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          ),
        ),
      );
    }
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.text.length,
              (index) {
                return Transform.translate(
                  offset: Offset(0, sin(_letterAnimations[index].value * pi) * 5),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      widget.text[index],
                      style: widget.style,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

