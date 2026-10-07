// ============================================================
// app_theme.dart - Design system and theme
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Dark navy
  static const Color primary = Color(0xFF0D2137);
  static const Color primaryLight = Color(0xFF1A3A5C);
  static const Color primarySurface = Color(0xFFEBF2FF);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);

  // Status colors
  static const Color statusNormal = Color(0xFF16A34A);
  static const Color statusNormalBg = Color(0xFFDCFCE7);
  static const Color statusNormalBorder = Color(0xFF86EFAC);

  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusWarningBorder = Color(0xFFFCD34D);

  static const Color statusCritical = Color(0xFFDC2626);
  static const Color statusCriticalBg = Color(0xFFFEE2E2);
  static const Color statusCriticalBorder = Color(0xFFFCA5A5);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF8B9EB7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Other
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A0D2137);
  static const Color accent = Color(0xFF0EA5E9); // Sky blue accent

  // Chart
  static const Color chartLine = Color(0xFF0EA5E9);
  static const Color chartFill = Color(0x220EA5E9);

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return statusNormal;
      case 'WARNING':
        return statusWarning;
      case 'CRITICAL':
        return statusCritical;
      default:
        return textMuted;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return statusNormalBg;
      case 'WARNING':
        return statusWarningBg;
      case 'CRITICAL':
        return statusCriticalBg;
      default:
        return surfaceVariant;
    }
  }

  static Color statusBorderColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return statusNormalBorder;
      case 'WARNING':
        return statusWarningBorder;
      case 'CRITICAL':
        return statusCriticalBorder;
      default:
        return divider;
    }
  }
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x220D2137),
        inactiveTrackColor: AppColors.divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.divider;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static BoxDecoration cardDecoration({
    Color? borderColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: borderColor ?? AppColors.divider, width: 1),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
