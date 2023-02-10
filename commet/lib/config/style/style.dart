import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const secondary = Color(0xFF3B76F6);
  static const accent = Color(0xFFD6755B);
  static const textDark = Color(0xFF53585A);
  static const textLigth = Color(0xFFF5F5F5);
  static const textFaded = Color(0xFF9899A5);
  static const iconLight = Color(0xFFB1B4C0);
  static const iconDark = Color(0xFFB1B3C1);
  static const textHighlight = secondary;
  static const cardLight = Color(0xFFF9FAFE);
  static const cardDark = Color(0xFF303334);
}

abstract class _LightColors {
  static const background = Colors.white;
  static const card = AppColors.cardLight;
}

abstract class _DarkColors {
  static const background = Color(0xFF1B1E1F);
  static const card = AppColors.cardDark;
}

/// Reference to the application theme.
abstract class AppTheme {
  static const accentColor = AppColors.accent;
  static final visualDensity = VisualDensity.adaptivePlatformDensity;

  /// Light theme and its settings.
  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        accentColor: accentColor,
        visualDensity: visualDensity,
        textTheme: GoogleFonts.mulishTextTheme()
            .apply(bodyColor: AppColors.textDark),
        backgroundColor: _LightColors.background,
        scaffoldBackgroundColor: _LightColors.background,
        cardColor: _LightColors.card,
        primaryTextTheme: const TextTheme(
          headline6: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.iconDark),
      );

  /// Dark theme and its settings.
  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        accentColor: accentColor,
        visualDensity: visualDensity,
        textTheme: GoogleFonts.interTextTheme()
            .apply(bodyColor: AppColors.textLigth),
        backgroundColor: _DarkColors.background,
        scaffoldBackgroundColor: _DarkColors.background,
        cardColor: _DarkColors.card,
        primaryTextTheme: const TextTheme(
          headline6: TextStyle(color: AppColors.textLigth),
        ),
        iconTheme: const IconThemeData(color: AppColors.iconLight),
      );
}
