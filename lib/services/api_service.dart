// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../models/jadwal_pendaftaran.dart';

class ApiService {
  static const _tokenKey = 'auth_token';

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<void> saveToken(String t) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, t);

  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove(_tokenKey);

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
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
    if (d['success'] == true) {
      final token = d['token'] as String;
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
    if (d['success'] == true) {
      final token = d['token'] as String;
      await saveToken(token);
      final u = UserModel.fromJson(d['user'] as Map<String, dynamic>);
      u.token = token;
      return u;
    }
    throw Exception(d['message'] ?? 'Registrasi gagal');
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
    req.files.add(await http.MultipartFile.fromPath('foto', imagePath));
    
    final res = await req.send();
    final body = await res.stream.bytesToString();
    final data = jsonDecode(body);
    
    if (res.statusCode >= 400 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal update foto');
    }
  }

  static Future<void> updatePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final d = await _put('/auth/password', {
      'password': password,
      'password_confirmation': passwordConfirmation,
    }, auth: true);
    if (d['success'] != true) throw Exception(d['message'] ?? 'Gagal ganti password');
  }

  // ── JADWAL & PENDAFTARAN ──────────────────────────────────────
  static Future<List<JadwalLatihan>> getJadwal() async {
    final d = await _get('/jadwal');
    return (d['data'] as List)
        .map((e) => JadwalLatihan.fromJson(e as Map<String, dynamic>))
        .toList();
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
    int? jadwalId,
    String? tanggalLatihan,
    String? jamLatihan,
    String? catatan,
  }) async {
    final d = await _post('/pendaftaran', {
      'tarian_id': tarianId,
      if (jadwalId != null) 'jadwal_id': jadwalId,
      if (tanggalLatihan != null) 'tanggal_latihan': tanggalLatihan,
      if (jamLatihan != null) 'jam_latihan': jamLatihan,
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