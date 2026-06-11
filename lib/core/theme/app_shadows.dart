import 'package:flutter/material.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';

class AppShadows {
  static List<BoxShadow> get premiumGlow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.secondary.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get neonBorderGlow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
}
