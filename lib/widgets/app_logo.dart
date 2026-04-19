import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const AppLogo({
    super.key,
    this.size = 44,
    this.showText = true,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.md,
          ),
          child: Icon(Icons.bolt, color: Colors.white, size: size * 0.6),
        ),
        if (showText) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            'FitTrack',
            style: AppTextStyles.heading2.copyWith(fontSize: fontSize),
          ),
        ],
      ],
    );
  }
}
