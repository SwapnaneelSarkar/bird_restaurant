import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class ActivePlanDialog extends StatelessWidget {
  final String planName;
  final String planDescription;
  final String endDate;
  final String dialogTitle;
  final String dialogMessage;
  final VoidCallback onGoToHome;

  const ActivePlanDialog({
    Key? key,
    required this.planName,
    required this.planDescription,
    required this.endDate,
    this.dialogTitle = 'Active Plan Found!',
    this.dialogMessage = 'You already have an active subscription plan.',
    required this.onGoToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, immediately go to home
        onGoToHome();
        return false; // Prevent dialog from being dismissed normally
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.primary.withOpacity(0.1),
                      ColorManager.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Info Icon with enhanced styling
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: ColorManager.primary,
                        size: 48,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title with enhanced typography
                                         Text(
                       dialogTitle,
                       style: TextStyle(
                         fontSize: FontSize.s25,
                         fontWeight: FontWeightManager.bold,
                         color: ColorManager.black,
                         letterSpacing: -0.5,
                       ),
                       textAlign: TextAlign.center,
                     ),
                    
                    const SizedBox(height: 12),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                                             child: Text(
                         'ACTIVE',
                         style: TextStyle(
                           fontSize: FontSize.s12,
                           fontWeight: FontWeightManager.bold,
                           color: Colors.green,
                           letterSpacing: 0.5,
                         ),
                       ),
                    ),
                  ],
                ),
              ),
              
              // Content area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Message
                                             Text(
                         dialogMessage,
                         style: TextStyle(
                           fontSize: FontSize.s14,
                           color: ColorManager.textGrey,
                           height: 1.4,
                         ),
                         textAlign: TextAlign.center,
                       ),
                      
                      const SizedBox(height: 24),
                      
                      // Plan Details with enhanced card design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ColorManager.primary.withOpacity(0.08),
                              ColorManager.primary.withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ColorManager.primary.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ColorManager.primary.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Plan name with special highlighting
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorManager.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plan Name',
                                    style: TextStyle(
                                      fontSize: FontSize.s12,
                                      fontWeight: FontWeightManager.medium,
                                      color: ColorManager.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    planName,
                                    style: TextStyle(
                                      fontSize: FontSize.s18,
                                      fontWeight: FontWeightManager.bold,
                                      color: ColorManager.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Other details
                            _buildEnhancedDetailRow('Description', planDescription),
                            const SizedBox(height: 12),
                            _buildEnhancedDetailRow('Valid Until', endDate),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Go to Home Button with enhanced styling
                      _buildEnhancedHomeButton(
                        'Go to Home',
                        onGoToHome,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
                             label,
               style: TextStyle(
                 fontSize: FontSize.s12,
                 fontWeight: FontWeightManager.medium,
                 color: ColorManager.textGrey,
                 letterSpacing: 0.3,
               ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
                             value,
               style: TextStyle(
                 fontSize: FontSize.s12,
                 fontWeight: FontWeightManager.semiBold,
                 color: ColorManager.black,
               ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEnhancedHomeButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary,
            ColorManager.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeightManager.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 