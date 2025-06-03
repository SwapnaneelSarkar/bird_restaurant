// lib/ui_components/bottom_navigation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/resources/colors.dart';
import '../../presentation/resources/font.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  
  const BottomNavigationWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late List<AnimationController> _iconControllers;
  late List<AnimationController> _indicatorControllers;
  late List<AnimationController> _pressControllers;
  
  @override
  void initState() {
    super.initState();
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _iconControllers = List.generate(
      2,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
      ),
    );

    _indicatorControllers = List.generate(
      2,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _pressControllers = List.generate(
      2,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      ),
    );
    
    // Initialize the selected animations
    if (widget.selectedIndex < _iconControllers.length) {
      _iconControllers[widget.selectedIndex].forward();
      _indicatorControllers[widget.selectedIndex].forward();
    }

    _slideController.forward();
  }

  @override
  void didUpdateWidget(BottomNavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Animate out old selection
      if (oldWidget.selectedIndex < _iconControllers.length) {
        _iconControllers[oldWidget.selectedIndex].reverse();
        _indicatorControllers[oldWidget.selectedIndex].reverse();
      }
      
      // Animate in new selection with bounce effect
      if (widget.selectedIndex < _iconControllers.length) {
        _iconControllers[widget.selectedIndex].forward();
        _indicatorControllers[widget.selectedIndex].forward();
        
        // Add bounce effect for selection
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
      }
      
      // Enhanced haptic feedback for selection change
      HapticFeedback.heavyImpact();
      
      // Subtle ripple effect
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    for (var controller in _indicatorControllers) {
      controller.dispose();
    }
    for (var controller in _pressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideController.value)),
          child: Opacity(
            opacity: _slideController.value,
            child: Container(
              margin: EdgeInsets.only(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                bottom: bottomPadding + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                  stops: [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: ColorManager.primary.withOpacity(0.08),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 78,
                  child: Row(
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: widget.selectedIndex == 0,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chats',
                        isSelected: widget.selectedIndex == 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          _pressControllers[index].forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _scaleController.reverse();
          _pressControllers[index].reverse();
        },
        onTapCancel: () {
          _scaleController.reverse();
          _pressControllers[index].reverse();
        },
        onTap: () {
          // Enhanced haptic feedback sequence
          HapticFeedback.selectionClick();
          Future.delayed(const Duration(milliseconds: 50), () {
            HapticFeedback.lightImpact();
          });
          widget.onItemTapped(index);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _pressControllers[index]]),
          builder: (context, child) {
            final pressValue = _pressControllers[index].value;
            final scaleValue = _scaleController.value;
            
            return Transform.scale(
              scale: 1.0 - (scaleValue * 0.04) - (pressValue * 0.02),
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ColorManager.primary.withOpacity(0.08 + (pressValue * 0.04)),
                            ColorManager.primary.withOpacity(0.04 + (pressValue * 0.02)),
                          ],
                        )
                      : pressValue > 0
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey.withOpacity(0.05 + (pressValue * 0.03)),
                                Colors.grey.withOpacity(0.02 + (pressValue * 0.01)),
                              ],
                            )
                          : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Stack(
                  children: [
                    // Subtle background gradient for selected item
                    if (isSelected)
                      AnimatedBuilder(
                        animation: _indicatorControllers[index],
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    ColorManager.primary.withOpacity(
                                      0.1 * _indicatorControllers[index].value,
                                    ),
                                    ColorManager.primary.withOpacity(
                                      0.05 * _indicatorControllers[index].value,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: ColorManager.primary.withOpacity(
                                    0.2 * _indicatorControllers[index].value,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Enhanced top indicator bar
                    AnimatedBuilder(
                      animation: _indicatorControllers[index],
                      builder: (context, child) {
                        return Positioned(
                          top: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Transform.scale(
                              scaleX: _indicatorControllers[index].value,
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      ColorManager.primary.withOpacity(0.6),
                                      ColorManager.primary,
                                      ColorManager.primary.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorManager.primary.withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Main content with bounce effect
                    Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_iconControllers[index], _bounceController]),
                        builder: (context, child) {
                          final bounceValue = widget.selectedIndex == index 
                              ? _bounceController.value 
                              : 0.0;
                          
                          return Transform.translate(
                            offset: Offset(0, -2 * bounceValue),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 6),
                                
                                // Icon with enhanced animation and bounce
                                Transform.scale(
                                  scale: 1.0 + (_iconControllers[index].value * 0.18) + (bounceValue * 0.1),
                                  child: Icon(
                                    icon,
                                    size: 28,
                                    color: isSelected
                                        ? ColorManager.primary
                                        : ColorManager.black.withOpacity(0.5),
                                  ),
                                ),
                                
                                const SizedBox(height: 6),
                                
                                // Label with enhanced styling and animation
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 150),
                                  style: TextStyle(
                                    fontSize: isSelected ? FontSize.s12 : FontSize.s10,
                                    fontWeight: isSelected
                                        ? FontWeightManager.bold
                                        : FontWeightManager.medium,
                                    color: isSelected
                                        ? ColorManager.primary
                                        : ColorManager.black.withOpacity(0.6),
                                    fontFamily: FontFamily.Montserrat,
                                    letterSpacing: 0.6,
                                    height: 1.1,
                                  ),
                                  child: Text(label),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),


                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}