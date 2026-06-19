import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_themes.dart';

/// Holds the currently selected [AppThemeMode] and exposes the derived
/// [ThemeData] and code-editor color styles used throughout the app.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _load();
  }

  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;
  ThemeData get themeData => AppThemes.themeData(_mode);
  Map<String, TextStyle> get codeHighlightStyles => AppThemes.codeHighlightStyles(_mode);
  Color get editorBackground => AppThemes.editorBackground(_mode);

  void _load() {
    final stored = StorageService.instance.getString(AppConstants.prefThemeMode);
    if (stored == null) return;
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => AppThemeMode.dark,
    );
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await StorageService.instance.setString(AppConstants.prefThemeMode, mode.name);
  }
}
