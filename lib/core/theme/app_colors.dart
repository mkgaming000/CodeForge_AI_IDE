import 'package:flutter/material.dart';

/// Shared color constants used to build CodeForge's themes.
///
/// Centralizing these makes it straightforward to add new theme variants
/// (e.g. a custom user-defined accent color) later without touching the
/// theme definitions themselves.
class AppColors {
  AppColors._();

  // Brand accent — a vivid azure used across all themes for primary actions.
  static const Color accent = Color(0xFF4F8EF7);
  static const Color accentDark = Color(0xFF3B6FD1);

  // Status colors.
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Dark theme surfaces.
  static const Color darkBackground = Color(0xFF15171C);
  static const Color darkSurface = Color(0xFF1E2127);
  static const Color darkSurfaceVariant = Color(0xFF262A33);
  static const Color darkOutline = Color(0xFF3A3F4B);
  static const Color darkOnSurface = Color(0xFFE6E6E6);
  static const Color darkOnSurfaceMuted = Color(0xFF9AA0AC);

  // AMOLED (pure black) surfaces.
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0A0A0A);
  static const Color amoledSurfaceVariant = Color(0xFF141414);
  static const Color amoledOutline = Color(0xFF262626);

  // Light theme surfaces.
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFF1F4);
  static const Color lightOutline = Color(0xFFD8DCE2);
  static const Color lightOnSurface = Color(0xFF1A1C1E);
  static const Color lightOnSurfaceMuted = Color(0xFF6B7280);

  // Glassmorphism overlay tint used for panels (chat, dialogs).
  static Color glassTint(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);
  }
}
