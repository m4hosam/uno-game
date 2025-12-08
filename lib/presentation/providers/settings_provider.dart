import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Shared Preferences Provider (UnimplementedError is a placeholder overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Has Seen Welcome Provider
final hasSeenWelcomeProvider =
    StateNotifierProvider<HasSeenWelcomeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HasSeenWelcomeNotifier(prefs);
});

class HasSeenWelcomeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  HasSeenWelcomeNotifier(this._prefs)
      : super(_prefs.getBool('hasSeenWelcome') ?? false);

  Future<void> setSeen() async {
    await _prefs.setBool('hasSeenWelcome', true);
    state = true;
  }
}

// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeNotifier(this._prefs) : super(_loadTheme(prefs: _prefs));

  static ThemeMode _loadTheme({required SharedPreferences prefs}) {
    final themeString = prefs.getString('themeMode');
    if (themeString == 'light') return ThemeMode.light;
    if (themeString == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await _prefs.setString('themeMode', value);
  }
}

// Locale Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  LocaleNotifier(this._prefs) : super(_loadLocale(prefs: _prefs));

  static Locale _loadLocale({required SharedPreferences prefs}) {
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString('languageCode', locale.languageCode);
  }
}
