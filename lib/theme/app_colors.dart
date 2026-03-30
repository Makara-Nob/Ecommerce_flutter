import 'package:flutter/material.dart';

/// App color palette with vibrant, modern colors
class AppColors {
  // Primary gradient colors (Charcoal Silver - NAGA Brand)
  static const primaryStart = Color(0xFF2C2C2C); // Deep charcoal (like the logo M box)
  static const primaryEnd = Color(0xFF5A5A5A);   // Warm silver

  // Accent colors
  static const accentPink = Color(0xFFFF6B6B);
  static const accentOrange = Color(0xFFF7B731);
  static const accentGreen = Color(0xFF2ED573);
  static const accentBlue = Color(0xFF1E90FF);

  // Semantic colors (Light mode)
  static const successLight = Color(0xFF2ED573);
  static const successLightBg = Color(0xFFE0F9ED);
  static const errorLight = Color(0xFFFF4757);
  static const errorLightBg = Color(0xFFFFEAEB);
  static const warningLight = Color(0xFFFFA502);
  static const warningLightBg = Color(0xFFFFF6E5);
  static const infoLight = Color(0xFF1E90FF);
  static const infoLightBg = Color(0xFFE5F3FF);

  // Background colors (Light mode)
  static const backgroundLight = Color(0xFFFAFAFA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);

  // Text colors (Light mode)
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);

  // Dark mode colors
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const cardDark = Color(0xFF334155);

  // Text colors (Dark mode)
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFFCBD5E1);
  static const textTertiaryDark = Color(0xFF94A3B8);

  // Semantic colors (Dark mode)
  static const successDark = Color(0xFF34D399);
  static const successDarkBg = Color(0xFF064E3B);
  static const errorDark = Color(0xFFF87171);
  static const errorDarkBg = Color(0xFF7F1D1D);
  static const warningDark = Color(0xFFFBBF24);
  static const warningDarkBg = Color(0xFF78350F);
  static const infoDark = Color(0xFF60A5FA);
  static const infoDarkBg = Color(0xFF1E3A8A);

  // Glassmorphism tokens
  static const glassBorder = Color(0x33FFFFFF); // 20% White
  static const glassHighlight = Color(0x66FFFFFF); // 40% White
  static const glassBackground = Color(0x1AFFFFFF); // 10% White

  // Refined Gradient definitions
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF232526), Color(0xFF414345)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gold NAGA accent from the logo bag
  static const gold = Color(0xFFC6A664);

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism overlay
  static Color glassOverlay(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4);
}
