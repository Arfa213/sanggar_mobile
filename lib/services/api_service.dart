// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../models/jadwal_pendaftaran.dart';

class OtpRequiredException implements Exception {
  final int userId;
  final String message;
  OtpRequiredException(this.userId, this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'auth_token';

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<void> saveToken(String t) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, t);

  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove(_tokenKey);

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (auth) {
      final t = await getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  static Future<Map<String, dynamic>> _get(String path, {bool auth = false}) async {
    final res = await http.get(Uri.parse('$kApiUrl$path'),
        headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Error ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.post(Uri.parse('$kApiUrl$path'),
        headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.put(Uri.parse('$kApiUrl$path'),
        headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── PUBLIK ────────────────────────────────────────────────────
  static Future<SanggarProfile> getProfil() async {
    final d = await _get('/profil');
    return SanggarProfile.fromJson(d['data'] as Map<String, dynamic>);
  }

  static Future<List<Pelatih>> getPelatih() async {
    final d = await _get('/pelatih');
    return (d['data'] as List).map((e) => Pelatih.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> getEvents({String? kategori}) async {
    final d = await _get('/events${kategori != null ? '?kategori=$kategori' : ''}');
    List<Event> parse(String key) =>
        ((d[key] as List?) ?? []).map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    return {
      'featured':  parse('featured'),
      'selesai':   parse('selesai'),
      'mendatang': parse('mendatang'),
      'stats':     d['stats'] as Map<String, dynamic>? ?? {},
    };
  }

  static Future<List<Tarian>> getTarian({String? kategori}) async {
    final d = await _get('/tarian${kategori != null ? '?kategori=$kategori' : ''}');
    return (d['data'] as List).map((e) => Tarian.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Galeri>> getGaleri({String? seksi}) async {
    final d = await _get('/galeri${seksi != null ? '?seksi=$seksi' : ''}');
    return (d['data'] as List).map((e) => Galeri.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Tarian> getTarianDetail(int id) async {
    final d = await _get('/tarian/$id');
    return Tarian.fromJson(d['data'] as Map<String, dynamic>);
  }

  // ── AUTH ──────────────────────────────────────────────────────
  static Future<UserModel> login(String email, String password) async {
    final d = await _post('/auth/login', {'email': email, 'password': password});
    if (d['needs_verification'] == true) {
      final userId = (d['user_id'] is int)
          ? d['user_id'] as int
          : int.tryParse(d['user_id']?.toString() ?? '') ?? 0;
      throw OtpRequiredException(userId, d['message'] ?? 'Perlu verifikasi OTP');
    }
    if (d['success'] == true) {
      final token = d['token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Token tidak ditemukan');
      await saveToken(token);
      final u = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      u.token = token;
      return u;
    }
    throw Exception(d['message'] ?? 'Login gagal');
  }

  /// Login menggunakan Firebase ID Token dari Google Sign-In.
  /// Backend Laravel harus punya endpoint POST /api/v1/auth/google
  static Future<UserModel> loginWithGoogleToken(String firebaseIdToken) async {
    // FIX: Mengubah kunci pengiriman dari 'id_token' menjadi 'firebase_token'
    // agar pas dan cocok dengan $request->firebase_token yang dicari oleh Laravel
    final d = await _post('/auth/google', {'firebase_token': firebaseIdToken});
    
    if (d['success'] == true) {
      final token = d['token'] as String;
      await saveToken(token);
      final u = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      u.token = token;
      return u;
    }
    throw Exception(d['message'] ?? 'Login Google gagal');
  }

  static Future<UserModel> register(Map<String, String> body) async {
    final d = await _post('/auth/register', body);
    if (d['needs_verification'] == true) {
      final userId = (d['user_id'] is int)
          ? d['user_id'] as int
          : int.tryParse(d['user_id']?.toString() ?? '') ?? 0;
      throw OtpRequiredException(userId, d['message'] ?? 'Perlu verifikasi OTP');
    }
    if (d['success'] == true) {
      final token = d['token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Token tidak ditemukan');
      await saveToken(token);
      final u = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      u.token = token;
      return u;
    }
    throw Exception(d['message'] ?? 'Registrasi gagal');
  }

  static Future<UserModel> verifyOtp(int userId, String otp) async {
    final d = await _post('/auth/verify-otp', {'user_id': userId, 'otp': otp});
    if (d['success'] == true) {
      final token = d['token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Token verifikasi tidak ditemukan');
      await saveToken(token);
      final u = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      u.token = token;
      return u;
    }
    throw Exception(d['message'] ?? 'Verifikasi gagal');
  }

  static Future<void> resendOtp(int userId) async {
    final d = await _post('/auth/resend-otp', {'user_id': userId});
    if (d['success'] != true) {
      throw Exception(d['message'] ?? 'Gagal mengirim ulang OTP');
    }
  }

  static Future<void> logout() async {
    try { await _post('/auth/logout', {}, auth: true); } catch (_) {}
    await clearToken();
  }

  static Future<UserModel?> getMe() async {
    try {
      final d = await _get('/auth/me', auth: true);
      return UserModel.fromJson(d['data'] as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final d = await _put('/auth/profile', data, auth: true);
    if (d['success'] != true) throw Exception(d['message'] ?? 'Gagal update profil');
  }

  static Future<void> updateProfilePhoto(String imagePath) async {
    final token = await getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$kApiUrl/auth/foto'));
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';
    req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    req.files.add(await http.MultipartFile.fromPath('foto', imagePath));
    
    final res = await req.send();
    final body = await res.stream.bytesToString();
    final data = jsonDecode(body);
    
    if (res.statusCode >= 400 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal update foto');
    }
  }

  static Future<void> updatePassword({
    String? currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final body = {
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (currentPassword != null) {
      body['current_password'] = currentPassword;
      body['old_password'] = currentPassword;
    }
    
    final d = await _put('/auth/password', body, auth: true);
    if (d['success'] != true) throw Exception(d['message'] ?? 'Gagal ganti password');
  }

  // ── JADWAL & PENDAFTARAN ──────────────────────────────────────
  static Future<List<JadwalLatihan>> getJadwal() async {
    final d = await _get('/jadwal');
    return (d['data'] as List)
        .map((e) => JadwalLatihan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<dynamic>> getEventsMendatang() async {
    try {
      final d = await _get('/events');
      return (d['mendatang'] as List? ) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<PendaftaranMember>> getPendaftaranSaya() async {
    try {
      final d = await _get('/pendaftaran', auth: true);
      return (d['data'] as List)
          .map((e) => PendaftaranMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Pendaftaran>> getPendaftaranSayaRaw() async {
    try {
      final d = await _get('/pendaftaran', auth: true);
      return (d['data'] as List)
          .map((e) => Pendaftaran.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> daftarKelas({
    required int tarianId,
    required String tanggalLatihan,
    required String jamLatihan,
    String? catatan,
  }) async {
    final d = await _post('/pendaftaran', {
      'tarian_id'       : tarianId,
      'tanggal_latihan' : tanggalLatihan,
      'jam_latihan'     : jamLatihan,
      if (catatan != null) 'catatan': catatan,
    }, auth: true);
    if (d['success'] != true) {
      throw Exception(d['message'] ?? 'Gagal mendaftar kelas');
    }
  }

  static Future<void> batalkanPendaftaran(int id) async {
    final d = await _post('/pendaftaran/$id/batalkan', {}, auth: true);
    if (d['success'] != true) {
      throw Exception(d['message'] ?? 'Gagal membatalkan pendaftaran');
    }
  }

  // ── KEHADIRAN ─────────────────────────────────────────────────
  static Future<List<Kehadiran>> getKehadiranSaya({int page = 1}) async {
    try {
      final d = await _get('/kehadiran-saya?page=$page', auth: true);
      final list = (d['data'] as List?) ?? [];
      return list.map((e) => Kehadiran.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<StatistikKehadiran> getStatistikKehadiran({String? bulan}) async {
    final b = bulan ?? DateTime.now().toString().substring(0, 7);
    try {
      final d = await _get('/kehadiran-saya/statistik?bulan=$b', auth: true);
      return StatistikKehadiran.fromJson(d);
    } catch (_) {
      return StatistikKehadiran(bulan: b, hadir: 0, izin: 0, alpa: 0, total: 0, persenHadir: 0);
    }
  }

  static Future<Map<String, dynamic>> scanAbsensi(String barcodeToken) async {
    final d = await _post('/attendance/scan', {'barcode_token': barcodeToken}, auth: true);
    return d;
  }

  /// Kirim data "tidak hadir / alpa" otomatis ke backend.
  /// Dipanggil mobile saat jadwal sudah terlewat dan user tidak scan.
  /// Backend cukup terima pendaftaran_id + tanggal dan insert record alpa.
  static Future<bool> markAbsent({
    required int pendaftaranId,
    required String tanggal, // format: 'YYYY-MM-DD'
  }) async {
    try {
      final d = await _post(
        '/attendance/mark-absent',
        {'pendaftaran_id': pendaftaranId, 'tanggal': tanggal},
        auth: true,
      );
      return d['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah user sudah punya record kehadiran (hadir/izin/alpa) hari ini
  /// untuk suatu pendaftaran tertentu — mencegah double submit alpa.
  static Future<bool> sudahAbsenHariIni(int pendaftaranId) async {
    try {
      final today = DateTime.now().toString().substring(0, 10);
      final d = await _get(
        '/attendance/check-today?pendaftaran_id=$pendaftaranId&tanggal=$today',
        auth: true,
      );
      return d['exists'] == true;
    } catch (_) {
      // Jika endpoint belum ada / error, anggap sudah absen (aman, tidak double-submit)
      return true;
    }
  }

  // ── RAPOR PAGELARAN ───────────────────────────────────────────
  static Future<List<RaporPagelaran>> getRaporSaya() async {
    try {
      final d = await _get('/rapor-saya', auth: true);
      final list = (d['data'] as List?) ?? [];
      return list.map((e) => RaporPagelaran.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<RaporSummary?> getRaporSummary() async {
    try {
      final d = await _get('/rapor-saya/summary', auth: true);
      if (d['data'] == null) return null;
      return RaporSummary.fromJson(d['data']);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      await _post('/auth/update-fcm-token', {'fcm_token': token}, auth: true);
    } catch (e) {
      // Ignore if fail
    }
  }

  // ── HELPER ────────────────────────────────────────────────────
  static Future<Map<String, String>> authHeader() async {
    final token = await getToken();
    if (token != null) return {'Authorization': 'Bearer $token'};
    return {};
  }

  // ── OLD COMPAT (untuk Pendaftaran lama) ──────────────────────
  static Future<List<Pendaftaran>> getPendaftaranSayaLegacy() async {
    try {
      final d = await _get('/pendaftaran', auth: true);
      return (d['data'] as List)
          .map((e) => Pendaftaran.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPengumuman() async {
    try {
      final d = await _get('/pengumuman', auth: true);
      final list = (d['data'] as List?) ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
}