import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AapnoColors {
  // ─── Primary (Navy — Trust & Depth) ───────
  static const primary = Color(0xFF1B2D5B);       // Aapno Navy
  static const primaryDark = Color(0xFF0F1D3D);    // Deep navy
  static const primaryLight = Color(0xFFE3E8F0);   // Light navy tint
  static const primarySoft = Color(0xFFF0F3F8);    // Soft navy wash

  // ─── Saffron (Warmth & Heritage) ──────────
  static const saffron = Color(0xFFE8862E);        // Aapno Saffron
  static const saffronDark = Color(0xFFD47420);     // Deep saffron
  static const saffronLight = Color(0xFFFFF4EB);    // Light saffron
  static const saffronGlow = Color(0xFFFFE0C5);     // Saffron glow

  // ─── Teal (Care & Health) ─────────────────
  static const teal = Color(0xFF0D9488);
  static const tealDark = Color(0xFF0F766E);
  static const tealLight = Color(0xFFCCFBF1);
  static const tealSoft = Color(0xFFF0FDFA);

  // ─── Semantic Colors ──────────────────────
  static const green = Color(0xFF059669);
  static const greenLight = Color(0xFFD1FAE5);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const orange = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFFEDD5);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFEDE9FE);
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const rose = Color(0xFFF43F5E);
  static const roseLight = Color(0xFFFFE4E6);

  // ─── Neutral & Surface ────────────────────
  static const background = Color(0xFFFAFAFC);
  static const surface = Colors.white;
  static const surfaceElevated = Color(0xFFFFF8F0);  // Aapno cream
  static const textPrimary = Color(0xFF1B2D5B);       // Navy text
  static const textSecondary = Color(0xFF555770);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnDark = Color(0xFFF8F9FA);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F1F3);
  static const divider = Color(0xFFF3F4F6);

  // ─── Dark Theme Specific Neutral & Surface ─
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const borderDark = Color(0xFF334155);

  // ─── Premium Gradients ────────────────────
  static const aapnoGradient = LinearGradient(
    colors: [Color(0xFF1B2D5B), Color(0xFF2A4070), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sevaGradient = aapnoGradient;

  static const warmGradient = LinearGradient(
    colors: [Color(0xFFE8862E), Color(0xFFF5A050)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const saffronGradient = LinearGradient(
    colors: [Color(0xFFE8862E), Color(0xFFD97706), Color(0xFFF5A623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lotusGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE8862E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const peacockGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF1B2D5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const nightGradient = LinearGradient(
    colors: [Color(0xFF0F1D3D), Color(0xFF1B2D5B), Color(0xFF2A4070)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFD4A036), Color(0xFFF7D774)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const stableGlow = Color(0x2006B65D);
  static const attentionGlow = Color(0x20F59E0B);
  static const criticalGlow = Color(0x20EF4444);
}

typedef SevaColors = AapnoColors;

class AapnoTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AapnoColors.primary,
        brightness: Brightness.light,
        primary: AapnoColors.primary,
        secondary: AapnoColors.saffron,
        tertiary: AapnoColors.teal,
      ),
      scaffoldBackgroundColor: AapnoColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w700, color: AapnoColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: AapnoColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: AapnoColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: AapnoColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AapnoColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AapnoColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AapnoColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AapnoColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: AapnoColors.textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AapnoColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AapnoColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AapnoColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AapnoColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AapnoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AapnoColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AapnoColors.primary, width: 1.5),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AapnoColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(color: AapnoColors.textTertiary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AapnoColors.textSecondary, fontSize: 14),
        prefixIconColor: AapnoColors.textTertiary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AapnoColors.primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AapnoColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AapnoColors.primary,
        unselectedItemColor: AapnoColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AapnoColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AapnoColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AapnoColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AapnoColors.textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AapnoColors.primary,
        brightness: Brightness.dark,
        primary: AapnoColors.primaryLight,
        secondary: AapnoColors.saffron,
        tertiary: AapnoColors.teal,
      ),
      scaffoldBackgroundColor: AapnoColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w700, color: AapnoColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: AapnoColors.textPrimaryDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: AapnoColors.textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: AapnoColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AapnoColors.textPrimaryDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AapnoColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AapnoColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AapnoColors.textSecondaryDark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: AapnoColors.textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AapnoColors.textPrimaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AapnoColors.surfaceDark,
        foregroundColor: AapnoColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AapnoColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AapnoColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AapnoColors.borderDark, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AapnoColors.primaryLight,
          foregroundColor: AapnoColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AapnoColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AapnoColors.primaryLight, width: 1.5),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AapnoColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AapnoColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(color: AapnoColors.textTertiary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AapnoColors.textSecondaryDark, fontSize: 14),
        prefixIconColor: AapnoColors.textTertiary,
      ),
    );
  }
}

typedef SevaTheme = AapnoTheme;

class AapnoDecorations {
  static BoxDecoration get glassCard => BoxDecoration(
    color: Colors.white.withAlpha(230),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AapnoColors.borderLight),
    boxShadow: [
      BoxShadow(
        color: AapnoColors.primary.withAlpha(8),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get elevatedCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(10),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: AapnoColors.primary.withAlpha(5),
        blurRadius: 40,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration statusGlow(Color color) => BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(color: color.withAlpha(80), blurRadius: 12, spreadRadius: 2),
    ],
  );

  static BoxDecoration get gradientHeader => const BoxDecoration(
    gradient: AapnoColors.aapnoGradient,
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
  );

  static BoxDecoration get saffronCard => BoxDecoration(
    gradient: AapnoColors.saffronGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AapnoColors.saffron.withAlpha(40),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

typedef SevaDecorations = AapnoDecorations;
