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
  static Future<List<JadwalLatihan>> getJadwal() async {
  final d = await _get('/jadwal');
  return (d['data'] as List)
      .map((e) => JadwalLatihan.fromJson(e as Map<String, dynamic>))
      .toList();
}
 
// ── PENDAFTARAN SAYA ─────────────────────────────────────────
static Future<List<Pendaftaran>> getPendaftaranSaya() async {
  try {
    final d = await _get('/pendaftaran', auth: true);
    return (d['data'] as List)
        .map((e) => Pendaftaran.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}
 
// ── DAFTAR KELAS ─────────────────────────────────────────────
static Future<void> daftarKelas({
  required int tarianId,
  required int jadwalId,
  String? catatan,
}) async {
  final d = await _post('/pendaftaran', {
    'tarian_id': tarianId,
    'jadwal_id': jadwalId,
    if (catatan != null) 'catatan': catatan,
  }, auth: true);
  if (d['success'] != true) {
    throw Exception(d['message'] ?? 'Gagal mendaftar kelas');
  }
}
 
// ── BATALKAN PENDAFTARAN ──────────────────────────────────────
static Future<void> batalkanPendaftaran(int id) async {
  final d = await _post('/pendaftaran/$id/batalkan', {}, auth: true);
  if (d['success'] != true) {
    throw Exception(d['message'] ?? 'Gagal membatalkan pendaftaran');
  }
}
 
// ── AUTH HEADER HELPER ────────────────────────────────────────
// untuk dipakai ChatbotScreen
static Future<Map<String, String>> authHeader() async {
  final token = await getToken();
  if (token != null) return {'Authorization': 'Bearer $token'};
  return {};
}

// ── GET DETAIL TARIAN ─────────────────────────────────────────
  static Future<Tarian> getTarianDetail(int id) async {
    final d = await _get('/tarian/$id');
    // Kita ambil dari d['data'] karena biasanya Laravel membungkus object dalam key 'data'
    return Tarian.fromJson(d['data'] as Map<String, dynamic>);
  }
}