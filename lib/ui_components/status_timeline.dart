import 'package:flutter/material.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';
import '../presentation/screens/application_status/state.dart';

class StatusTimelineItem extends StatelessWidget {
  final StatusStep step;
  final bool isLast;

  const StatusTimelineItem({
    Key? key,
    required this.step,
    this.isLast = false,
  }) : super(key: key);

  IconData get _icon {
    switch (step.type) {
      case StatusType.submitted:
        return Icons.check_circle;
      case StatusType.underReview:
        // If the step is completed (which happens when application is approved),
        // show a check icon instead of clock
        return step.isCompleted ? Icons.check_circle : Icons.access_time;
      case StatusType.activation:
        return Icons.storefront;
      case StatusType.approved:
        return Icons.check_circle;
      case StatusType.rejected:
        return Icons.cancel;
    }
  }

  Color get _color {
    if (step.isRejected) return Colors.red;
    if (step.isCompleted) return Colors.green;
    if (step.isCurrent) return ColorManager.primary;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + vertical line
            Column(
              children: [
                Icon(_icon, color: _color, size: 24),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.only(top: 4),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s16,
                      fontWeight: step.isCurrent
                          ? FontWeightManager.semiBold
                          : FontWeightManager.medium,
                      color: step.isRejected
                          ? Colors.red
                          : step.isCurrent
                              ? ColorManager.black
                              : Colors.grey.shade700,
                    ),
                  ),
                  if (step.date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(step.date!),
                      style: TextStyle(
                        fontFamily: FontConstants.fontFamily,
                        fontSize: FontSize.s12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontFamily: FontConstants.fontFamily,
                      fontSize: FontSize.s14,
                      color: step.isCurrent
                          ? Colors.grey.shade700
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month/$day/${dt.year}, $hour:$minute';
  }
}