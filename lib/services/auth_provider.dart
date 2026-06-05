// lib/services/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import '../models/models.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user    => _user;
  bool get isLoggedIn   => _user != null;
  bool get isLoading      => _loading;

  //  Web Client ID agar mudah jika sewaktu-waktu ingin diubah
  // PASTIKAN ganti dengan Web Client ID asli yang kamu salin dari Firebase Console!
  static const String _webClientId = '611713677810-86g03v381kvd8lua78c650t8elicjtce.apps.googleusercontent.com';

  Future<void> init() async {
    _loading = true; notifyListeners();
    if (await ApiService.getToken() != null) _user = await ApiService.getMe();
    _loading = false; notifyListeners();
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.updateFcmToken(token);
      }
    } catch (_) {}
  }

  Future<void> login(String email, String pass) async {
    final user = await ApiService.login(email, pass);
    _user = user;
    notifyListeners();
    _syncFcmToken();
  }

  Future<void> register(Map<String, String> data) async {
    final user = await ApiService.register(data);
    _user = user;
    notifyListeners();
    _syncFcmToken();
  }

  Future<void> logout() async {
    // Sign out dari Google menggunakan serverClientId agar sesi bersih global
    try { 
      await GoogleSignIn(serverClientId: _webClientId).signOut(); 
    } catch (_) {}
    try { 
      await FirebaseAuth.instance.signOut(); 
    } catch (_) {}
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  void updateUser(UserModel u) { _user = u; notifyListeners(); }

  /// Login menggunakan akun Google via Firebase (FIXED TOKEN)
  Future<void> loginWithGoogle() async {
    // 1. Tampilkan popup pilih akun Google dengan mengoper serverClientId resmi
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      serverClientId: _webClientId,
    ).signIn();
    
    if (googleUser == null) throw Exception('Login dibatalkan');

    // 2. Ambil token autentikasi dari Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 3. Buat credential Firebase dari token Google
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    // 4. Sign-in ke Firebase dengan credential Google
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // 5. Ambil idToken langsung dari GOOGLE (bukan dari userCredential Firebase)
    final googleIdToken = googleAuth.idToken; 
    if (googleIdToken == null) throw Exception('Token Google tidak valid');

    // 6. Kirim token asli GOOGLE ke backend Laravel
    _user = await ApiService.loginWithGoogleToken(googleIdToken);
    notifyListeners();
    _syncFcmToken();
  }

  // 📸 FUNGSI UPLOAD FOTO PROFIL
  Future<void> uploadFoto(File imageFile) async {
    try {
      final url = Uri.parse('https://senindrai.my.id/api/v1/auth/foto');
      final request = http.MultipartRequest('POST', url);
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
        final responseData = json.decode(response.body);
        if (responseData['user'] != null) {
          _user = UserModel.fromJson(responseData['user']);
        } else {
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
}