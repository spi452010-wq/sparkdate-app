import 'package:flutter/material.dart';

/// Design tokens extracted from the SparkDate Figma file.
abstract final class AppColors {
  static const primary = Color(0xFFFF4F7B);
  static const primaryMid = Color(0xFFC83FA5);
  static const magenta = Color(0xFFC53E8D);
  static const violet = Color(0xFF8455EF);
  static const purple = Color(0xFF7932E6);
  static const indigo = Color(0xFF5148B8);
  static const crimson = Color(0xFFCF2F5A);
  static const whatsapp = Color(0xFF25D366);
  static const success = Color(0xFF10A37F);

  static const textPrimary = Color(0xFF1D1A25);
  static const textTitle = Color(0xFF191825);
  static const textSecondary = Color(0xFF6A6579);
  static const textMuted = Color(0xFF555462);
  static const textBody = Color(0xFF4A4556);

  static const background = Color(0xFFFAF8FC);
  static const surfaceTint = Color(0xFFF8F1FF);
  static const border = Color(0xFFE4E4E7);
  static const divider = Color(0xFFE8E4EE);
  static const error = Color(0xFFCF2F5A);

  static const ctaGradient = LinearGradient(
    colors: [primary, Color(0xFFC53E8D), purple],
  );
  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMid, indigo],
    stops: [0, .52, 1],
  );
  static const splashBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8FC), Color(0xFFFAF6FE), Color(0xFFF4EEFF)],
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radiusField = 16.0;
  static const radiusCard = 20.0;
  static const radiusPill = 9999.0;
}
