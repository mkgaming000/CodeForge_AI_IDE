/// Global constant values used throughout CodeForge.
class AppConstants {
  AppConstants._();

  static const String appName = 'CodeForge';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefFontSize = 'pref_font_size';
  static const String prefTabSize = 'pref_tab_size';
  static const String prefWordWrap = 'pref_word_wrap';
  static const String prefShowLineNumbers = 'pref_show_line_numbers';
  static const String prefAutoSave = 'pref_auto_save';
  static const String prefAutoCloseBrackets = 'pref_auto_close_brackets';
  static const String prefAutoIndent = 'pref_auto_indent';
  static const String prefRecentProjects = 'pref_recent_projects';
  static const String prefFontFamily = 'pref_font_family';
  static const String prefAiModel = 'pref_ai_model';

  // Secure storage keys
  static const String secureKeyGeminiApiKey = 'secure_gemini_api_key';

  // AI defaults
  static const String defaultAiModel = 'gemini-2.5-flash';
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Editor defaults
  static const double minFontSize = 10.0;
  static const double maxFontSize = 28.0;
  static const double defaultFontSize = 14.0;
  static const int defaultTabSize = 4;

  // Limits
  static const int maxRecentProjects = 12;
  static const int maxOpenTabs = 20;
}
