import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/core/theme/app_colors.dart';

class AppTypography {
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );
}
