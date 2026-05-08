import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════
//  STUDENT HUB  —  Unified Pastel Palette
//  4 accent colours used EVERYWHERE in the app.
// ════════════════════════════════════════════════════════════════

/// 🪻  Primary — soft lavender-purple
const kPrimary      = Color(0xFF8B8FF8);
const kPrimaryLight = Color(0xFFD0D2FD); // tint for chips / badges

/// 🌿  Mint — secondary / success / low-priority
const kMint         = Color(0xFF6ECFBF);
const kMintLight    = Color(0xFFBEEDE8);

/// 🍑  Coral — high-priority / warnings / alarm ring
const kCoral        = Color(0xFFFF9AA2);
const kCoralLight   = Color(0xFFFFD5D8);

/// 🌼  Amber — medium-priority / timer / warmth
const kAmber        = Color(0xFFFECF6A);
const kAmberLight   = Color(0xFFFFF0C2);

// ── Backgrounds ─────────────────────────────────────────────────
const kLightBg      = Color(0xFFF5F5FF); // very light lavender page bg
const kLightCard    = Color(0xFFFFFFFF);
const kLightSurface = Color(0xFFECECFF); // input fill / chips

const kDarkBg       = Color(0xFF13131F); // deep navy-black
const kDarkCard     = Color(0xFF1D1D2E);
const kDarkSurface  = Color(0xFF26263A);

// ── Gradient helpers ─────────────────────────────────────────────
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF8B8FF8), Color(0xFFB3B7FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kPrimaryGradientDark = LinearGradient(
  colors: [Color(0xFF3D3F8F), Color(0xFF5558C8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── Priority colours (from the palette) ─────────────────────────
const kPriorityHigh   = kCoral;
const kPriorityMedium = kAmber;
const kPriorityLow    = kMint;

// ════════════════════════════════════════════════════════════════
//  ThemeData
// ════════════════════════════════════════════════════════════════

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: Brightness.light,
        primary: kPrimary,
        secondary: kMint,
        surface: kLightCard,
        error: kCoral,
      ),
      scaffoldBackgroundColor: kLightBg,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: kLightBg,
        foregroundColor: const Color(0xFF2A2A3D),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF2A2A3D),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2A2A3D)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kLightCard,
        indicatorColor: kPrimaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kPrimary);
          }
          return const IconThemeData(color: Color(0xFF9090A0));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
                color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return GoogleFonts.poppins(
              color: const Color(0xFF9090A0), fontSize: 11);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kLightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFFAAABBF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: kLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kLightSurface,
        selectedColor: kPrimaryLight,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kLightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A3D),
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? kPrimary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? kPrimaryLight
              : const Color(0xFFDDDDEE),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: Brightness.dark,
        primary: kPrimary,
        secondary: kMint,
        surface: kDarkCard,
        error: kCoral,
      ),
      scaffoldBackgroundColor: kDarkBg,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: kDarkBg,
        foregroundColor: const Color(0xFFE5E5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFFE5E5F7),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE5E5F7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kDarkCard,
        indicatorColor: kPrimary.withOpacity(0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kPrimary);
          }
          return const IconThemeData(color: Color(0xFF7070A0));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
                color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return GoogleFonts.poppins(
              color: const Color(0xFF7070A0), fontSize: 11);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kDarkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF6060A0)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: kDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kDarkSurface,
        selectedColor: kPrimary.withOpacity(0.3),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kDarkCard,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? kPrimary : Colors.grey[400],
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? kPrimary.withOpacity(0.35)
              : kDarkSurface,
        ),
      ),
    );
  }
}
