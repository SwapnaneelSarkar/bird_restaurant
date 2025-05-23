import 'package:bird_restaurant/presentation/resources/colors.dart';
import 'package:flutter/material.dart';
import '../../../models/plan_model.dart';
import '../presentation/resources/font.dart';
import 'plan_button.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCard({
    Key? key,
    required this.plan,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Main card container
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: plan.isPopular ? const Color(0xFFFDF2E9) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: plan.isPopular 
                    ? const Color(0xFFE67E22)
                    : const Color(0xFFE5E7EB),
                width: plan.isPopular ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: plan.isPopular 
                      ? const Color(0xFFE67E22).withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: plan.isPopular ? 16 : 8,
                  offset: const Offset(0, 2),
                  spreadRadius: plan.isPopular ? 1 : 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top spacing to account for title in border
                  const SizedBox(height: 12),
                  
                  // Plan description
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: FontSize.s12,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Features list
                  ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE67E22).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: FontSize.s12,
                              color: const Color(0xFF374151),
                              height: 1.3,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  const SizedBox(height: 20),
                  
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${plan.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeightManager.bold,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 4),
                        child: Text(
                          '/month',
                          style: TextStyle(
                            fontSize: FontSize.s12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeightManager.medium,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Select button
                  PlanButton(
                    text: plan.buttonText,
                    onTap: onTap,
                    isPopular: plan.isPopular,
                  ),
                ],
              ),
            ),
          ),
          
          // Title positioned in the border
          Positioned(
            left: 20,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: plan.isPopular ? const Color(0xFFFDF2E9) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: plan.isPopular ? Border.all(
                  color: const Color(0xFFE67E22),
                  width: 1,
                ) : null,
              ),
              child: Text(
                plan.title,
                style: TextStyle(
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.bold,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          
          // Popular badge positioned on the right
          if (plan.isPopular)
            Positioned(
              right: 20,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE67E22).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: FontSize.s10,
                    fontWeight: FontWeightManager.semiBold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}