import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      _isLoggedIn = true;
    }

    notifyListeners();
  }

  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    _token = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}