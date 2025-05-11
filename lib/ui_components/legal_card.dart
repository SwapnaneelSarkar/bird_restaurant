// lib/ui_components/legal_document_card.dart

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class LegalDocumentCard extends StatelessWidget {
  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final bool uploaded;
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const LegalDocumentCard({
    Key? key,
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.uploaded,
    this.fileName,
    required this.onTap,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hInset = w * 0.04;
    final vPad = w * 0.06;
    final iconBgSize = w * 0.16;
    final iconSize = w * 0.08;
    final spacer = w * 0.03;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hInset, vertical: vPad * 0.5),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        dashPattern: const [8, 4],
        color: uploaded ? Colors.green : ColorManager.grey,
        strokeWidth: 1,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: hInset,
              vertical: vPad,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: iconBgSize,
                      height: iconBgSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: uploaded
                            ? Colors.green.withOpacity(.1)
                            : ColorManager.primary.withOpacity(.1),
                      ),
                      child: Icon(
                        uploaded ? Icons.check : icon,
                        size: iconSize,
                        color: uploaded ? Colors.green : ColorManager.primary,
                      ),
                    ),
                    if (uploaded && onRemove != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacer),

                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontConstants.fontFamily,
                    fontSize: FontSize.s16,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: spacer * 0.5),

                Text(
                  uploaded && fileName != null ? fileName! : description,
                  style: TextStyle(
                    fontFamily: FontConstants.fontFamily,
                    fontSize: FontSize.s14,
                    color: uploaded ? Colors.green : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacer * 0.3),

                Text(
                  uploaded ? 'Tap to change file' : hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontConstants.fontFamily,
                    fontSize: FontSize.s12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}