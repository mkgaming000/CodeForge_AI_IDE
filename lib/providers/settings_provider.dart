import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';
import '../core/services/storage_service.dart';

/// Monospace font choices available for the code editor.
enum EditorFontFamily { jetBrainsMono, firaCode, sourceCodePro, robotoMono, ibmPlexMono }

extension EditorFontFamilyX on EditorFontFamily {
  String get label {
    switch (this) {
      case EditorFontFamily.jetBrainsMono:
        return 'JetBrains Mono';
      case EditorFontFamily.firaCode:
        return 'Fira Code';
      case EditorFontFamily.sourceCodePro:
        return 'Source Code Pro';
      case EditorFontFamily.robotoMono:
        return 'Roboto Mono';
      case EditorFontFamily.ibmPlexMono:
        return 'IBM Plex Mono';
    }
  }

  TextStyle textStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
    switch (this) {
      case EditorFontFamily.jetBrainsMono:
        return GoogleFonts.jetBrainsMono(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case EditorFontFamily.firaCode:
        return GoogleFonts.firaCode(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case EditorFontFamily.sourceCodePro:
        return GoogleFonts.sourceCodePro(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case EditorFontFamily.robotoMono:
        return GoogleFonts.robotoMono(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case EditorFontFamily.ibmPlexMono:
        return GoogleFonts.ibmPlexMono(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }
}

/// Editor and AI preferences, persisted via [StorageService].
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _load();
  }

  double _fontSize = AppConstants.defaultFontSize;
  int _tabSize = AppConstants.defaultTabSize;
  bool _wordWrap = false;
  bool _showLineNumbers = true;
  bool _autoSave = false;
  bool _autoCloseBrackets = true;
  bool _autoIndent = true;
  EditorFontFamily _fontFamily = EditorFontFamily.jetBrainsMono;
  String _aiModel = AppConstants.defaultAiModel;

  double get fontSize => _fontSize;
  int get tabSize => _tabSize;
  bool get wordWrap => _wordWrap;
  bool get showLineNumbers => _showLineNumbers;
  bool get autoSave => _autoSave;
  bool get autoCloseBrackets => _autoCloseBrackets;
  bool get autoIndent => _autoIndent;
  EditorFontFamily get fontFamily => _fontFamily;
  String get aiModel => _aiModel;

  /// Convenience: the [TextStyle] the code editor should use for its body
  /// text, combining the chosen font family and size.
  TextStyle editorTextStyle({Color? color}) => _fontFamily.textStyle(fontSize: _fontSize, fontWeight: FontWeight.w400, color: color);

  void _load() {
    final s = StorageService.instance;
    _fontSize = s.getDouble(AppConstants.prefFontSize) ?? AppConstants.defaultFontSize;
    _tabSize = s.getInt(AppConstants.prefTabSize) ?? AppConstants.defaultTabSize;
    _wordWrap = s.getBool(AppConstants.prefWordWrap) ?? false;
    _showLineNumbers = s.getBool(AppConstants.prefShowLineNumbers) ?? true;
    _autoSave = s.getBool(AppConstants.prefAutoSave) ?? false;
    _autoCloseBrackets = s.getBool(AppConstants.prefAutoCloseBrackets) ?? true;
    _autoIndent = s.getBool(AppConstants.prefAutoIndent) ?? true;

    final storedFont = s.getString(AppConstants.prefFontFamily);
    if (storedFont != null) {
      _fontFamily = EditorFontFamily.values.firstWhere(
        (f) => f.name == storedFont,
        orElse: () => EditorFontFamily.jetBrainsMono,
      );
    }
    _aiModel = s.getString(AppConstants.prefAiModel) ?? AppConstants.defaultAiModel;
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(AppConstants.minFontSize, AppConstants.maxFontSize).toDouble();
    notifyListeners();
    await StorageService.instance.setDouble(AppConstants.prefFontSize, _fontSize);
  }

  Future<void> setTabSize(int value) async {
    _tabSize = value;
    notifyListeners();
    await StorageService.instance.setInt(AppConstants.prefTabSize, value);
  }

  Future<void> setWordWrap(bool value) async {
    _wordWrap = value;
    notifyListeners();
    await StorageService.instance.setBool(AppConstants.prefWordWrap, value);
  }

  Future<void> setShowLineNumbers(bool value) async {
    _showLineNumbers = value;
    notifyListeners();
    await StorageService.instance.setBool(AppConstants.prefShowLineNumbers, value);
  }

  Future<void> setAutoSave(bool value) async {
    _autoSave = value;
    notifyListeners();
    await StorageService.instance.setBool(AppConstants.prefAutoSave, value);
  }

  Future<void> setAutoCloseBrackets(bool value) async {
    _autoCloseBrackets = value;
    notifyListeners();
    await StorageService.instance.setBool(AppConstants.prefAutoCloseBrackets, value);
  }

  Future<void> setAutoIndent(bool value) async {
    _autoIndent = value;
    notifyListeners();
    await StorageService.instance.setBool(AppConstants.prefAutoIndent, value);
  }

  Future<void> setFontFamily(EditorFontFamily family) async {
    _fontFamily = family;
    notifyListeners();
    await StorageService.instance.setString(AppConstants.prefFontFamily, family.name);
  }

  Future<void> setAiModel(String modelId) async {
    _aiModel = modelId;
    notifyListeners();
    await StorageService.instance.setString(AppConstants.prefAiModel, modelId);
  }
}
