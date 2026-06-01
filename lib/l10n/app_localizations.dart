import 'package:flutter/material.dart';
import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_te.dart';

/// ─────────────────────────────────────────────
/// Aapno Care — Localization Engine
/// Supports: English, Hindi (हिन्दी), Telugu (తెలుగు)
/// ─────────────────────────────────────────────
class AapnoLocalizations {
  static final AapnoLocalizations _instance = AapnoLocalizations._internal();
  factory AapnoLocalizations() => _instance;
  AapnoLocalizations._internal();

  static String _currentLocale = 'en';
  static final _listeners = <VoidCallback>[];

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': stringsEn,
    'hi': stringsHi,
    'te': stringsTe,
  };

  // ─── Supported Languages ─────────────────
  static const List<AapnoLanguage> supportedLanguages = [
    AapnoLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AapnoLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AapnoLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
  ];

  // ─── Getters ─────────────────────────────
  static String get currentLocale => _currentLocale;
  static AapnoLanguage get currentLanguage =>
      supportedLanguages.firstWhere((l) => l.code == _currentLocale);

  // ─── Set Language ────────────────────────
  static void setLocale(String locale) {
    if (_localizedStrings.containsKey(locale)) {
      _currentLocale = locale;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  // ─── Listeners for rebuild ───────────────
  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) => _listeners.remove(listener);

  // ─── Translation Lookup ──────────────────
  static String t(String key) {
    return _localizedStrings[_currentLocale]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }
}

/// Backward compatibility aliases
typedef SevaLocalizations = AapnoLocalizations;
typedef SevaLanguage = AapnoLanguage;

/// Short alias for translation
String t(String key) => AapnoLocalizations.t(key);

/// Language model
class AapnoLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AapnoLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
