import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const _prefsKeyThemeMode = 'settings.themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppUser? _user;
  AppUser? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Theme
      final tm = prefs.getString(_prefsKeyThemeMode);
      if (tm != null) {
        _themeMode = switch (tm) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }

      // Load User
      _user = await AuthService.I.getCurrentUser();
    } catch (e) {
      debugPrint('Settings init failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await AuthService.I.login(email, password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String cpf,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await AuthService.I.register(
        name: name,
        email: email,
        password: password,
        cpf: cpf,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.I.logout();
    _user = null;
    notifyListeners();
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
    // In a real app, we'd update AuthService/Backend too
  }
}
