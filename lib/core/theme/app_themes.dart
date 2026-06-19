import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The three built-in appearance modes CodeForge supports.
enum AppThemeMode { dark, light, amoled }

extension AppThemeModeLabel on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.amoled:
        return 'AMOLED';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.amoled:
        return Icons.nights_stay_outlined;
    }
  }
}

/// Builds the [ThemeData] and code-editor color styles for each
/// [AppThemeMode].
class AppThemes {
  AppThemes._();

  /// The monospace font family used in the code editor and terminal.
  static String get editorFontFamily => GoogleFonts.jetBrainsMono().fontFamily!;

  static ThemeData themeData(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          background: AppColors.darkBackground,
          surface: AppColors.darkSurface,
          surfaceVariant: AppColors.darkSurfaceVariant,
          outline: AppColors.darkOutline,
          onSurface: AppColors.darkOnSurface,
          onSurfaceMuted: AppColors.darkOnSurfaceMuted,
        );
      case AppThemeMode.amoled:
        return _buildTheme(
          brightness: Brightness.dark,
          background: AppColors.amoledBackground,
          surface: AppColors.amoledSurface,
          surfaceVariant: AppColors.amoledSurfaceVariant,
          outline: AppColors.amoledOutline,
          onSurface: AppColors.darkOnSurface,
          onSurfaceMuted: AppColors.darkOnSurfaceMuted,
        );
      case AppThemeMode.light:
        return _buildTheme(
          brightness: Brightness.light,
          background: AppColors.lightBackground,
          surface: AppColors.lightSurface,
          surfaceVariant: AppColors.lightSurfaceVariant,
          outline: AppColors.lightOutline,
          onSurface: AppColors.lightOnSurface,
          onSurfaceMuted: AppColors.lightOnSurfaceMuted,
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color outline,
    required Color onSurface,
    required Color onSurfaceMuted,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accentDark,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      // Modern Material 3 role (Flutter >=3.22): widgets throughout this app
      // read colorScheme.surfaceContainerHighest / onSurfaceVariant directly,
      // NOT the deprecated surfaceVariant field.
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceMuted,
      outline: outline,
      outlineVariant: outline.withOpacity(0.6),
      inverseSurface: isDark ? Colors.white : Colors.black,
      onInverseSurface: isDark ? Colors.black : Colors.white,
      shadow: Colors.black,
      scrim: Colors.black54,
      inversePrimary: AppColors.accentDark,
      surfaceTint: AppColors.accent,
    );

    final baseTextTheme = isDark
        ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: baseTextTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      // Flutter 3.24.5: ThemeData.cardTheme and .dialogTheme are typed as
      // the classic CardTheme / DialogTheme classes (CardThemeData /
      // DialogThemeData were introduced in a later Flutter release).
      cardTheme: CardTheme(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withOpacity(0.18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconTheme: IconThemeData(color: onSurface),
      dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceMuted,
        textColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: TextStyle(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outline),
        ),
        textStyle: TextStyle(color: onSurface, fontSize: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceVariant,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: outline),
        ),
      ),
      // InkSparkle is available on Android/Fuchsia. On other platforms
      // Flutter falls back to the default ripple automatically.
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// The syntax-highlighting style map for the given [mode].
  static Map<String, TextStyle> codeHighlightStyles(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return atomOneDarkTheme;
      case AppThemeMode.amoled:
        return _amoledCodeStyles;
      case AppThemeMode.light:
        return atomOneLightTheme;
    }
  }

  /// The background color for the code editor surface.
  static Color editorBackground(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return const Color(0xFF282C34);
      case AppThemeMode.amoled:
        return AppColors.amoledBackground;
      case AppThemeMode.light:
        return const Color(0xFFFAFAFA);
    }
  }

  static final Map<String, TextStyle> _amoledCodeStyles = {
    ...atomOneDarkTheme,
    'root': (atomOneDarkTheme['root'] ?? const TextStyle()).copyWith(
      backgroundColor: AppColors.amoledBackground,
      color: AppColors.darkOnSurface,
    ),
  };
}
