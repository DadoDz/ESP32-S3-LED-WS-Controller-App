import 'package:flutter/material.dart';

/// Centralized palette - teal/coral accent instead of the previous
/// indigo/purple scheme, so this doesn't just look like a recolor.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0B0D10);
  static const surface = Color(0xFF161A1F);
  static const surfaceHighlight = Color(0xFF1D232B);
  static const surfaceBorder = Color(0x14FFFFFF); // white @ 8%

  static const primary = Color(0xFF14B8A6); // teal
  static const primaryMuted = Color(0xFF0D9488);

  static const channelRed = Color(0xFFFB7185); // rose-400
  static const channelGreen = Color(0xFF4ADE80); // green-400
  static const channelBlue = Color(0xFF38BDF8); // sky-400
  static const brightnessAccent = Color(0xFFFBBF24); // amber-400

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white60;
  static const textMuted = Colors.white38;

  static const danger = Color(0xFFF87171);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
