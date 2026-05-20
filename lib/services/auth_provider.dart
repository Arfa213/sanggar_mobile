// lib/services/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    _user = await ApiService.login(email, pass); notifyListeners();
  }

  Future<void> register(Map<String, String> data) async {
    _user = await ApiService.register(data); notifyListeners();
  }

  Future<void> logout() async {
    // Sign out dari Google juga kalau sedang login via Google
    try { await GoogleSignIn().signOut(); } catch (_) {}
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  void updateUser(UserModel u) { _user = u; notifyListeners(); }

  /// Login menggunakan akun Google via Firebase
  Future<void> loginWithGoogle() async {
    // 1. Tampilkan popup pilih akun Google
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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

    // 5. Ambil idToken Firebase untuk dikirim ke backend Laravel
    final idToken = await userCredential.user!.getIdToken();
    if (idToken == null) throw Exception('Gagal mendapatkan token Firebase');

    // 6. Kirim idToken ke backend Laravel untuk verifikasi & buat session
    _user = await ApiService.loginWithGoogleToken(idToken);
    notifyListeners();
  }
}