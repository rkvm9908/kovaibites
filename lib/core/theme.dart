import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design.dart';

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

ThemeData _build() {
  final scheme = ColorScheme.fromSeed(seedColor: Brand.primary).copyWith(
    primary: Brand.primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFE4D9),
    onPrimaryContainer: Brand.primaryDark,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(bodyColor: Brand.ink, displayColor: Brand.ink);

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: Brand.cream,

    // Zoom transition for every platform, including web.
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      for (final p in TargetPlatform.values) p: const ZoomPageTransitionsBuilder(),
    }),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Brand.ink),
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700, color: Brand.ink),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 44),
        foregroundColor: Brand.primary,
        side: const BorderSide(color: Brand.primary, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Brand.primary,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _border(Colors.grey.shade300),
      enabledBorder: _border(Colors.grey.shade300),
      focusedBorder: _border(Brand.primary, 1.6),
      errorBorder: _border(Colors.red.shade400),
      focusedErrorBorder: _border(Colors.red.shade400, 1.6),
    ),

    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: Colors.grey.shade300),
      backgroundColor: Colors.white,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: Brand.primary,
      labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

final appTheme = _build();