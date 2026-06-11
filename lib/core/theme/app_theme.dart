import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmind_ai/features/settings/domain/entities/app_settings.dart';

class AppTheme {
  static ThemeData getThemeData(AppSettings settings, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final isHighContrast = settings.highContrast;

    // 1. Accent Color Mapping
    Color primaryColor;
    Color secondaryColor;
    if (isHighContrast) {
      primaryColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0000E6);
      secondaryColor = isDark ? const Color(0xFFFFEB3B) : const Color(0xFFE65100);
    } else if (settings.customPrimaryColor != null) {
      primaryColor = Color(int.parse(settings.customPrimaryColor!));
      secondaryColor = settings.customAccentColor != null 
          ? Color(int.parse(settings.customAccentColor!)) 
          : primaryColor;
    } else {
      switch (settings.accentColor) {
        case 'cyan':
          primaryColor = const Color(0xFF00D4FF);
          secondaryColor = const Color(0xFF6C63FF);
          break;
        case 'emerald':
          primaryColor = const Color(0xFF10B981);
          secondaryColor = const Color(0xFF3B82F6);
          break;
        case 'amber':
          primaryColor = const Color(0xFFF59E0B);
          secondaryColor = const Color(0xFFEF4444);
          break;
        case 'rose':
          primaryColor = const Color(0xFFF43F5E);
          secondaryColor = const Color(0xFF8B5CF6);
          break;
        case 'purple':
        default:
          primaryColor = const Color(0xFF6C63FF);
          secondaryColor = const Color(0xFF00D4FF);
          break;
      }
    }

    // 2. Brightness Palette
    final scaffoldBg = isHighContrast
        ? (isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
        : (settings.customBgColor != null
            ? Color(int.parse(settings.customBgColor!))
            : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF9FAFB)));
            
    final surfaceColor = isHighContrast
        ? (isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
        : (settings.customSurfaceColor != null
            ? Color(int.parse(settings.customSurfaceColor!))
            : (isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF)));

    final cardColor = isHighContrast
        ? (isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6));

    final textPrimaryColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    
    final textSecondaryColor = isHighContrast
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : (isDark ? const Color(0x99FFFFFF) : const Color(0xFF4B5563));

    final textMutedColor = isHighContrast
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : (isDark ? const Color(0x66FFFFFF) : const Color(0xFF9CA3AF));

    final borderColor = isHighContrast
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
        : (isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE5E7EB));

    // 3. Font Scale Multiplier
    double scale = 1.0;
    if (settings.fontSize == 'small') scale = 0.85;
    if (settings.fontSize == 'large') scale = 1.25;

    final baseTextTheme = TextTheme(
      titleLarge: GoogleFonts.plusJakartaSans(
        color: textPrimaryColor,
        fontSize: 22 * scale,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: textPrimaryColor,
        fontSize: 18 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: GoogleFonts.inter(
        color: textPrimaryColor,
        fontSize: 16 * scale,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.inter(
        color: textSecondaryColor,
        fontSize: 14 * scale,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        color: textMutedColor,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: surfaceColor,
              error: const Color(0xFFFF1744),
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: surfaceColor,
              error: const Color(0xFFFF1744),
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontSize: 18 * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: baseTextTheme,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: isHighContrast ? 2.5 : 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: isHighContrast ? 2.0 : 1,
      ),
    );
  }

  // Fallbacks for compatibility
  static ThemeData get darkTheme => getThemeData(AppSettings.defaultSettings(), Brightness.dark);
  static ThemeData get lightTheme => getThemeData(AppSettings.defaultSettings(), Brightness.light);
}
