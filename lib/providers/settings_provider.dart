import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class SettingsProvider extends ChangeNotifier {
  static const _prefsKeyUser = 'settings.user';
  static const _prefsKeyThemeMode = 'settings.themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppUser _user = AppUser(
    id: 'user-1',
    fullName: 'João Silva',
    cpf: '123.456.789-00',
    contact: '(11) 98765-4321',
    avatarUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  AppUser get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefsKeyUser);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          _user = AppUser.fromJson(map);
        } catch (e) {
          debugPrint('Failed to decode user from prefs: $e');
        }
      }
      final tm = prefs.getString(_prefsKeyThemeMode);
      if (tm != null) {
        switch (tm) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }
    } catch (e) {
      debugPrint('Settings load failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
      await prefs.setString(_prefsKeyThemeMode, value);
    } catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }

  Future<void> updateUser(AppUser newUser) async {
    _user = newUser.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyUser, jsonEncode(_user.toJson()));
    } catch (e) {
      debugPrint('Failed to persist user: $e');
    }
  }
}
