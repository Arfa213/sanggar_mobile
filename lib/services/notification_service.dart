// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';
import '../models/jadwal_pendaftaran.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'reminder' | 'approval' | 'announcement'
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        type: json['type'],
        isRead: json['isRead'] ?? false,
      );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    await loadNotifications();
  }

  Future<void> showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sanggar_pengumuman',
      'Pengumuman Sanggar',
      channelDescription: 'Notifikasi untuk jadwal latihan dan pengumuman',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // ── SAVE & LOAD FROM LOCAL STORAGE ─────────────────────────
  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('app_notifications', jsonEncode(data));
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_notifications');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _notifications = list.map((item) => AppNotification.fromJson(item)).toList();
      } catch (_) {
        _notifications = [];
      }
    }
    notifyListeners();
  }

  // ── CLEAR & MARK AS READ ──────────────────────────────────
  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      await saveNotifications();
    }
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    await saveNotifications();
  }

  // ── GENERATOR PENGINGAT REAL-TIME ──────────────────────────
  // Dijalankan saat user masuk ke Dashboard untuk menghitung otomatis jadwal
  Future<void> generateRealtimeReminders({
    required UserModel user,
    required List<PendaftaranMember> pendaftaranList,
  }) async {
    final now = DateTime.now();
    bool updated = false;

    // Tambah Pengumuman Selamat Datang jika masih kosong
    if (_notifications.isEmpty) {
      _notifications.add(AppNotification(
        id: 'welcome_${user.id}',
        title: 'Selamat bergabung! 🎉',
        message: 'Selamat datang di aplikasi resmi Sanggar Mulya Bhakti. Di sini kamu bisa memantau jadwal latihan, daftar kelas private tari, dan melakukan presensi digital secara praktis!',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: 'announcement',
      ));
      updated = true;
    }

    // Ambil Broadcast Pengumuman dari Website Laravel API secara dinamis
    try {
      // 1. Ambil event mendatang
      final events = await ApiService.getEventsMendatang();
      for (var item in events) {
        final id = 'event_${item['id']}';
        if (!_notifications.any((n) => n.id == id)) {
          final dtStr = item['created_at'] ?? now.toIso8601String();
          _notifications.insert(0, AppNotification(
            id: id,
            title: '🎉 Event Baru: ${item['nama']}',
            message: 'Persiapkan dirimu! Kita akan melaksanakan kegiatan ini pada tanggal ${item['tanggal']} di ${item['lokasi']}!',
            timestamp: DateTime.parse(dtStr).toLocal(),
            type: 'announcement',
          ));
          updated = true;
        }
      }
      
      // Ambil pengumuman dari backend
      final apiAnnouncements = await ApiService.getPengumuman();
      for (var item in apiAnnouncements) {
        final id = 'pengumuman_${item['id']}';
        if (!_notifications.any((n) => n.id == id)) {
          final dtStr = item['created_at'] ?? now.toIso8601String();
          _notifications.insert(0, AppNotification(
            id: id,
            title: item['judul'] ?? '📢 Pengumuman',
            message: item['konten'] ?? '-',
            timestamp: DateTime.parse(dtStr).toLocal(),
            type: 'announcement',
          ));
          updated = true;
        }
      }
    } catch (_) {}

    // 1. GENERATOR UNTUK ANGGOTA TETAP (Latihan Wajib 2x Seminggu)
    if (!user.isPengunjung && !user.isAdmin) {
      for (var p in pendaftaranList) {
        final hariLatihan = p.jadwal.hari.trim().toLowerCase(); // e.g. 'jumat', 'minggu'
        final nextPracticeDate = _getNextPracticeDate(hariLatihan, p.jadwal.jamMulai);
        
        final diff = nextPracticeDate.difference(now);

        // 1.a Pengingat 24 Jam Sebelum Latihan
        if (diff.inHours <= 24 && diff.inHours > 1) {
          final id = '24h_tetap_${p.id}_${nextPracticeDate.day}';
          if (!_notifications.any((n) => n.id == id)) {
            final title = 'Besok Latihan Tari! 🎭';
            final body = 'Pengingat Wajib: Latihan kelas "${p.tarianNama}" dijadwalkan besok ${p.jadwal.hari} jam ${p.jadwal.jamMulai} WIB di ${p.jadwal.tempat}. Harap persiapkan diri!';
            _notifications.insert(0, AppNotification(
              id: id,
              title: title,
              message: body,
              timestamp: now,
              type: 'reminder',
            ));
            showLocalNotification(title: title, body: body);
            updated = true;
          }
        }

        // 1.b Pengingat 1 Jam Sebelum Latihan
        if (diff.inMinutes <= 60 && diff.inMinutes > 0) {
          final id = '1h_tetap_${p.id}_${nextPracticeDate.day}';
          if (!_notifications.any((n) => n.id == id)) {
            final title = '1 Jam Lagi Mulai! ⏰';
            final body = 'Latihan kelas "${p.tarianNama}" akan dimulai 1 jam lagi jam ${p.jadwal.jamMulai} WIB. Sampai jumpa di ruang latihan!';
            _notifications.insert(0, AppNotification(
              id: id,
              title: title,
              message: body,
              timestamp: now,
              type: 'reminder',
            ));
            showLocalNotification(title: title, body: body);
            updated = true;
          }
        }
      }
    }

    // 2. GENERATOR UNTUK ANGGOTA SEMENTARA (Berdasarkan Private)
    if (user.isPengunjung && !user.isAdmin) {
      for (var p in pendaftaranList) {
        // Status private disetujui (aktif / approved)
        final isApproved = p.status.toLowerCase() == 'aktif' || p.status.toLowerCase() == 'approved';
        
        // Notifikasi persetujuan admin jika belum pernah masuk
        final approvalId = 'approval_${p.id}';
        if (isApproved && !_notifications.any((n) => n.id == approvalId)) {
          _notifications.insert(0, AppNotification(
            id: approvalId,
            title: 'Sesi Private Disetujui! ✅',
            message: 'Sesi latihan "${p.tarianNama}" untuk hari ${p.jadwal.hari} jam ${p.jadwal.jamMulai} WIB telah DISETUJUI oleh Admin. Silakan datang sesuai jadwal!',
            timestamp: now,
            type: 'approval',
          ));
          updated = true;
        }

        // Hitung waktu latihan
        final nextPracticeDate = _getNextPracticeDate(p.jadwal.hari.toLowerCase(), p.jadwal.jamMulai);
        final diff = nextPracticeDate.difference(now);

        // 2.a Pengingat 24 Jam Sebelum Private
        if (isApproved && diff.inHours <= 24 && diff.inHours > 1) {
          final id = '24h_sementara_${p.id}_${nextPracticeDate.day}';
          if (!_notifications.any((n) => n.id == id)) {
            final title = 'Besok Agenda Latihanmu! 🎯';
            final body = 'Sesi private kelas "${p.tarianNama}" akan dimulai besok ${p.jadwal.hari} jam ${p.jadwal.jamMulai} WIB. Persiapkan fisik dan kelengkapan latihanmu!';
            _notifications.insert(0, AppNotification(
              id: id,
              title: title,
              message: body,
              timestamp: now,
              type: 'reminder',
            ));
            showLocalNotification(title: title, body: body);
            updated = true;
          }
        }

        // 2.b Pengingat 1 Jam Sebelum Private
        if (isApproved && diff.inMinutes <= 60 && diff.inMinutes > 0) {
          final id = '1h_sementara_${p.id}_${nextPracticeDate.day}';
          if (!_notifications.any((n) => n.id == id)) {
            final title = '1 Jam Lagi Mulai! ⏰';
            final body = 'Sesi latihan khusus "${p.tarianNama}" Anda dimulai 1 jam lagi jam ${p.jadwal.jamMulai} WIB. Harap datang 15 menit lebih awal!';
            _notifications.insert(0, AppNotification(
              id: id,
              title: title,
              message: body,
              timestamp: now,
              type: 'reminder',
            ));
            showLocalNotification(title: title, body: body);
            updated = true;
          }
        }
      }
    }

    if (updated) {
      await saveNotifications();
    }
  }

  // Helper untuk menghitung DateTime terdekat untuk hari latihan tertentu
  DateTime _getNextPracticeDate(String hariStr, String jamStr) {
    final now = DateTime.now();
    final days = {
      'senin': 1, 'selasa': 2, 'rabu': 3, 'kamis': 4,
      'jumat': 5, 'sabtu': 6, 'minggu': 7
    };
    
    final targetDay = days[hariStr.trim().toLowerCase()] ?? 5; // Default jumat
    int daysToAdd = targetDay - now.weekday;
    if (daysToAdd < 0) {
      daysToAdd += 7; // Cari hari tersebut di minggu depan
    }

    // Parse Jam (e.g. '15:00' atau '15:00:00')
    int hour = 15;
    int minute = 0;
    try {
      final parts = jamStr.split(':');
      if (parts.isNotEmpty) hour = int.parse(parts[0]);
      if (parts.length > 1) minute = int.parse(parts[1]);
    } catch (_) {}

    final targetDate = DateTime(now.year, now.month, now.day, hour, minute)
        .add(Duration(days: daysToAdd));

    // Jika waktu latihan hari ini sudah terlewat, majukan ke minggu depan
    if (targetDate.isBefore(now)) {
      return targetDate.add(const Duration(days: 7));
    }
    
    return targetDate;
  }
}
