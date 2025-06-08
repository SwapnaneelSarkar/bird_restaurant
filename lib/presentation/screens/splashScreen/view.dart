// lib/presentation/screens/splash/view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import '../../resources/router/router.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _loadingAnimationController;
  late AnimationController _backgroundAnimationController;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _loadingOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  
  // Particle animation variables
  final List<ParticleModel> _particles = [];
  final Random _random = Random();
  late Timer _particleTimer;

  @override
  void initState() {
    super.initState();
    
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
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
    
    // Initialize loading animation
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _loadingOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Initialize background animation
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Generate initial particles
    _generateParticles();
    
    // Start animation sequence
    _startAnimationSequence();
    
    // Start particle animation timer
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateParticles();
      if (mounted) setState(() {});
    });
    
    // Check authentication after animations
    Future.delayed(const Duration(milliseconds: 3500), () {
      _checkAuthentication();
    });
  }
  
  void _generateParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(ParticleModel(
        position: Offset(
          _random.nextDouble() * 400 - 200,
          _random.nextDouble() * 400 - 200,
        ),
        size: _random.nextDouble() * 10 + 5,
        opacity: _random.nextDouble() * 0.7 + 0.3,
        speed: _random.nextDouble() * 1.5 + 0.5,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }
  }
  
  void _updateParticles() {
    for (var particle in _particles) {
      particle.position = Offset(
        particle.position.dx + cos(particle.angle) * particle.speed,
        particle.position.dy + sin(particle.angle) * particle.speed,
      );
      
      // Reset particles that go too far
      if (particle.position.dx.abs() > 220 || particle.position.dy.abs() > 220) {
        particle.position = Offset(
          _random.nextDouble() * 100 - 50,
          _random.nextDouble() * 100 - 50,
        );
        particle.angle = _random.nextDouble() * 2 * pi;
      }
      
      // Slightly vary opacity for twinkling effect
      particle.opacity = max(0.2, min(0.8, particle.opacity + (_random.nextDouble() * 0.1 - 0.05)));
    }
  }
  
  void _startAnimationSequence() {
    // Start background animation
    _backgroundAnimationController.forward();
    
    // Start logo animation after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoAnimationController.forward();
    });
    
    // Start text animation after logo
    Future.delayed(const Duration(milliseconds: 700), () {
      _textAnimationController.forward();
    });
    
    // Start loading animation after text
    Future.delayed(const Duration(milliseconds: 1400), () {
      _loadingAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _loadingAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _particleTimer.cancel();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final mobileNumber = prefs.getString('mobile');
      
      debugPrint('Token: ${token != null ? 'exists' : 'null'}');
      debugPrint('Mobile: $mobileNumber');
      
      // If no token or mobile number, go to login
      if (token == null || token.isEmpty || mobileNumber == null || mobileNumber.isEmpty) {
        debugPrint('No token or mobile, going to sign in');
        _navigateToLoginScreen();
        return;
      }

      // Set up headers with token
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Call API to check application status
      final uri = Uri.parse('https://api.bird.delivery/api/partner/getDetailsByMobile?mobile=$mobileNumber');
      debugPrint('Calling API: $uri');
      
      final response = await http.get(uri, headers: headers);
      debugPrint('Response status: ${response.statusCode}');

      // If unauthorized, go to login
      if (response.statusCode == 401) {
        debugPrint('Unauthorized, going to sign in');
        _navigateToLoginScreen();
        return;
      }

      // If successful response, check the status
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Response data: $data');
        
        if (data['status'] == 'SUCCESS') {
          final restaurantData = data['data'];
          final status = restaurantData['status'];
          debugPrint('Application status: $status');
          
          // If approved (status = 1), go to home
          if (status == 1) {
            debugPrint('Approved, going to home');
            _navigateToHomeScreen();
            return;
          }
          // If pending (status = 2) or rejected (status = 7), go to application status
          else if (status == 2 || status == 7) {
            debugPrint('Pending/Rejected, going to application status');
            _navigateToHomeScreen();
            return;
          }
          // For any other status, go to application status
          else {
            debugPrint('Other status, going to application status');
            _navigateToApplicationStatusScreen(mobileNumber);
            return;
          }
        }
      }
      
      // For any other case, go to sign in
      debugPrint('Default case, going to sign in');
      _navigateToLoginScreen();
      
    } catch (e, stackTrace) {
      debugPrint('Error checking authentication: $e');
      debugPrint('Stack trace: $stackTrace');
      // If there's any error, default to sign in
      _navigateToLoginScreen();
    }
  }

  void _navigateToLoginScreen() {
    Navigator.of(context).pushReplacementNamed(Routes.signin);
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushReplacementNamed(Routes.homePage);
  }

  void _navigateToApplicationStatusScreen(String mobileNumber) {
    Navigator.of(context).pushReplacementNamed(
      Routes.applicationStatus,
      arguments: mobileNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/login.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.75),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Animated background gradient
            AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0 * _backgroundAnimation.value,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
            
            // Particles
            Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(
                  painter: ParticlePainter(particles: _particles),
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo with white container
                    FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            width: size.width * 0.3,
                            height: size.width * 0.3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(80),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Animated text
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: Text(
                          'BIRD PARTNER',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Slogan with fade animation
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: Text(
                          'Delivering Excellence',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Additional slogan
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Partner with us for success',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Custom Loading Animation
                    FadeTransition(
                      opacity: _loadingOpacityAnimation,
                      child: Column(
                        children: [
                          // Dot animation container
                          Container(
                            height: 50,
                            width: 120,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const DotPulseLoader(
                              dotSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Text animation
                          const TextLoadingAnimation(
                            text: 'LOADING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Version number
                    FadeTransition(
                      opacity: _loadingOpacityAnimation,
                      child: Text(
                        'v1.0.0',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

