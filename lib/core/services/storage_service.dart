import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized access to persistent storage.
///
/// Non-sensitive settings (theme, font size, recent projects, etc.) are kept
/// in [SharedPreferences]. Sensitive values — currently the user's Gemini
/// API key — are kept in the platform keystore via [FlutterSecureStorage].
///
/// [init] must be awaited once during app startup before any other method is
/// used.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('StorageService.init() must complete before use.');
    }
    return prefs;
  }

  // -------------------------------------------------------------------
  // SharedPreferences-backed values
  // -------------------------------------------------------------------

  String? getString(String key) => _p.getString(key);
  Future<void> setString(String key, String value) => _p.setString(key, value);

  int? getInt(String key) => _p.getInt(key);
  Future<void> setInt(String key, int value) => _p.setInt(key, value);

  double? getDouble(String key) => _p.getDouble(key);
  Future<void> setDouble(String key, double value) => _p.setDouble(key, value);

  bool? getBool(String key) => _p.getBool(key);
  Future<void> setBool(String key, bool value) => _p.setBool(key, value);

  Future<void> remove(String key) => _p.remove(key);

  /// Reads and decodes a JSON value stored under [key], or `null`.
  T? getJson<T>(String key, T Function(dynamic decoded) decode) {
    final raw = _p.getString(key);
    if (raw == null) return null;
    try {
      return decode(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Encodes [value] as JSON and stores it under [key].
  Future<void> setJson(String key, Object? value) {
    return _p.setString(key, jsonEncode(value));
  }

  // -------------------------------------------------------------------
  // Secure storage (API keys, tokens)
  // -------------------------------------------------------------------

  Future<String?> getSecure(String key) => _secureStorage.read(key: key);

  Future<void> setSecure(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  Future<void> deleteSecure(String key) => _secureStorage.delete(key: key);
}
