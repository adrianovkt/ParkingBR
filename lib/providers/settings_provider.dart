import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/parking/domain/pricing.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'settings.themeMode';
  static const _parkingNameKey = 'settings.parkingName';
  static const _graceSecondsKey = 'settings.graceSeconds';
  static const _firstHourCentsKey = 'settings.firstHourCents';
  static const _extraHourCentsKey = 'settings.extraHourCents';

  ThemeMode _themeMode = ThemeMode.system;
  String _parkingName = 'Parking BR';
  int _graceSeconds = 15 * 60;
  int _firstHourCents = 1000;
  int _extraHourCents = 500;
  bool _initialized = false;

  SettingsProvider() {
    _initialize();
  }

  ThemeMode get themeMode => _themeMode;
  String get parkingName => _parkingName;
  int get graceSeconds => _graceSeconds;
  int get firstHourCents => _firstHourCents;
  int get extraHourCents => _extraHourCents;
  bool get initialized => _initialized;
  PricingPolicy get pricing {
    if (!_initialized) {
      throw StateError('As configurações ainda estão carregando');
    }
    return PricingPolicy(
      graceSeconds: _graceSeconds,
      firstHourCents: _firstHourCents,
      extraHourCents: _extraHourCents,
    );
  }

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _parkingName = preferences.getString(_parkingNameKey) ?? 'Parking BR';
    _graceSeconds = preferences.getInt(_graceSecondsKey) ?? 15 * 60;
    _firstHourCents = preferences.getInt(_firstHourCentsKey) ?? 1000;
    _extraHourCents = preferences.getInt(_extraHourCentsKey) ?? 500;
    try {
      PricingPolicy(
        graceSeconds: _graceSeconds,
        firstHourCents: _firstHourCents,
        extraHourCents: _extraHourCents,
      ).validate();
    } on ArgumentError {
      _graceSeconds = 15 * 60;
      _firstHourCents = 1000;
      _extraHourCents = 500;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    if (!await preferences.setString(_themeKey, value)) {
      throw StateError('Não foi possível salvar o tema');
    }
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> updateOperationalSettings({
    required String parkingName,
    required int graceSeconds,
    required int firstHourCents,
    required int extraHourCents,
  }) async {
    final name = parkingName.trim();
    if (name.isEmpty) {
      throw ArgumentError('Informe o nome do estacionamento');
    }
    PricingPolicy(
      graceSeconds: graceSeconds,
      firstHourCents: firstHourCents,
      extraHourCents: extraHourCents,
    ).validate();

    final preferences = await SharedPreferences.getInstance();
    final writesSucceeded =
        await preferences.setString(_parkingNameKey, name) &&
        await preferences.setInt(_graceSecondsKey, graceSeconds) &&
        await preferences.setInt(_firstHourCentsKey, firstHourCents) &&
        await preferences.setInt(_extraHourCentsKey, extraHourCents);
    if (!writesSucceeded) {
      throw StateError('Não foi possível salvar as configurações');
    }

    _parkingName = name;
    _graceSeconds = graceSeconds;
    _firstHourCents = firstHourCents;
    _extraHourCents = extraHourCents;
    notifyListeners();
  }
}
