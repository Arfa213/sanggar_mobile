// lib/services/auth_provider.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/models.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user     => _user;
  bool get isLoggedIn    => _user != null;
  bool get isLoading      => _loading;

  Future<void> init() async {
    _loading = true; notifyListeners();
    if (await ApiService.getToken() != null) _user = await ApiService.getMe();
    _loading = false; notifyListeners();
  }

  Future<void> login(String email, String pass) async {
    _user = await ApiService.login(email, pass); notifyListeners(); 
  }

  Future<void> register(Map<String, String> data) async {
    _user = await ApiService.register(data); notifyListeners(); 
  }

  Future<void> logout() async {
    await ApiService.logout(); _user = null; notifyListeners(); 
  }

  void updateUser(UserModel u) { _user = u; notifyListeners(); }

  // 📸 FUNGSI UPLOAD FOTO PROFIL
  Future<void> uploadFoto(File imageFile) async {
    try {
      // Menambahkan /auth karena berdasarkan struktur API lainnya, profil diakses via /auth/profile
      final url = Uri.parse('https://senindrai.my.id/api/v1/auth/foto');
      final request = http.MultipartRequest('POST', url);

      // Mengambil token Sanctum langsung dari ApiService bawaan proyekmu
      final savedToken = await ApiService.getToken();

      request.headers.addAll({
        'Authorization': 'Bearer $savedToken', 
        'Accept': 'application/json',
      });

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'foto', 
        stream, 
        length,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Mengambil data user terupdate dari response backend jika ada
        final responseData = json.decode(response.body);
        if (responseData['user'] != null) {
          _user = UserModel.fromJson(responseData['user']);
        } else {
          // Jika backend tidak me-return data user baru, kita ambil ulang datanya
          _user = await ApiService.getMe();
        }
        notifyListeners();
      } else {
        throw Exception('${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
} // 👈 Kurung kurawal penutup class dipastikan di paling bawah