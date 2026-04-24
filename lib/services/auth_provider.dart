// lib/services/auth_provider.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user     => _user;
  bool get isLoggedIn     => _user != null;
  bool get isLoading      => _loading;

  Future<void> init() async {
    _loading = true; notifyListeners();
    if (await ApiService.getToken() != null) _user = await ApiService.getMe();
    _loading = false; notifyListeners();
  }
  Future<void> login(String email, String pass) async {
    _user = await ApiService.login(email, pass); notifyListeners(); }
  Future<void> register(Map<String, String> data) async {
    _user = await ApiService.register(data); notifyListeners(); }
  Future<void> logout() async {
    await ApiService.logout(); _user = null; notifyListeners(); }
}