import 'package:flutter/material.dart';

class AppColors {
  // Dark Background (Primary Theme Focus)
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D4FF);
  
  // Accents & Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Semantic Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF1744);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // Muted
  static const Color textMuted = Color(0x66FFFFFF); // Hint/Disabled
  
  // Borders & Dividers
  static const Color border = Color(0x1FFFFFFF); // 12% opacity white border
  static const Color borderBright = Color(0x3DFFFFFF); // 24% opacity white border
}
