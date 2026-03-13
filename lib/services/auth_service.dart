import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const _prefsKeyUsers = 'auth.users';
  static const _prefsKeyCurrentUser = 'auth.currentUser';

  static final AuthService I = AuthService._();
  AuthService._();

  Future<AppUser?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsKeyUsers) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);

    final userMap = usersList.firstWhere(
      (u) => u['email'] == email,
      orElse: () => null,
    );

    if (userMap == null) {
      throw 'Conta inexistente';
    }

    if (userMap['password'] != password) {
      throw 'Senha errada';
    }

    final user = AppUser.fromJson(userMap);
    await prefs.setString(_prefsKeyCurrentUser, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String cpf,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsKeyUsers) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);

    if (usersList.any((u) => u['email'] == email)) {
      throw 'E-mail já cadastrado';
    }

    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'fullName': name,
      'email': email,
      'password': password,
      'cpf': cpf,
      'contact': email,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    usersList.add(newUser);
    await prefs.setString(_prefsKeyUsers, jsonEncode(usersList));
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_prefsKeyCurrentUser);
    if (userJson == null) return null;
    return AppUser.fromJson(jsonDecode(userJson));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyCurrentUser);
  }
}
