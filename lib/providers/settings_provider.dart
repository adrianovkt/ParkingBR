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

  // Inicializa as configurações e o usuário logado
  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final tm = prefs.getString(_prefsKeyThemeMode);
      if (tm != null) {
        _themeMode = switch (tm) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }

      _user = await AuthService.I.getCurrentUser();
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Autentica o usuário
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

  // Registra um novo usuário
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

  // Encerra a sessão do usuário
  Future<void> logout() async {
    await AuthService.I.logout();
    _user = null;
    notifyListeners();
  }

  // Altera o tema do aplicativo
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
      debugPrint('Erro ao persistir tema: $e');
    }
  }

  // Atualiza os dados do usuário
  Future<void> updateUser(AppUser newUser) async {
    _user = newUser.copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }
}
