// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sanggar_mulya_bhakti/screens/archive_screen.dart';
import 'package:sanggar_mulya_bhakti/screens/event_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

import 'services/auth_provider.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_nav.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'utils/app_theme.dart';

// ── Notification Channel Android (IMPORTANCE_HIGH = popup heads-up) ──────────
const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
  'smb_pengumuman_high',          // channel ID — harus sama di semua tempat
  'Pengumuman Sanggar',           // nama tampil di Settings HP
  description: 'Notifikasi pengumuman & jadwal latihan dari admin Sanggar Mulya Bhakti',
  importance: Importance.high,    // ← WAJIB agar muncul heads-up popup
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

// ── Background / Terminated handler ──────────────────────────────────────────
// Harus top-level function (bukan di dalam kelas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Di background isolate, buat instance FlutterLocalNotificationsPlugin baru
  final localNotifBg = FlutterLocalNotificationsPlugin();
  await localNotifBg.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    ),
  );
  // Buat channel di isolate background juga
  await localNotifBg
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_fcmChannel);

  // Tampilkan heads-up popup
  final title = message.notification?.title ??
      (message.data['title'] as String?) ??
      '📢 Pengumuman Baru';
  final body = message.notification?.body ??
      (message.data['body'] as String?) ??
      'Ada pengumuman baru dari Sanggar Mulya Bhakti.';

  await localNotifBg.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _fcmChannel.id,
        _fcmChannel.name,
        channelDescription: _fcmChannel.description ?? 'Notifikasi Sanggar Mulya Bhakti',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

// ── Helper: tampilkan heads-up popup notification (foreground) ─────────────
void _showHeadsUpNotification({
  required String title,
  required String body,
  int id = 0,
}) {
  _localNotif.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _fcmChannel.id,
        _fcmChannel.name,
        channelDescription: _fcmChannel.description ?? 'Notifikasi Sanggar Mulya Bhakti',
        importance: Importance.high,
        priority: Priority.high,
        ticker: title,
        styleInformation: BigTextStyleInformation(body),
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Set background/terminated message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Inisialisasi flutter_local_notifications
  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  await _localNotif.initialize(
    const InitializationSettings(android: initAndroid),
    // Aksi saat user tap notifikasi (bisa navigasi ke halaman tertentu)
    onDidReceiveNotificationResponse: (details) {
      debugPrint('Notifikasi di-tap: ${details.payload}');
    },
  );

  // 4. WAJIB: Buat notification channel IMPORTANCE_HIGH di Android
  //    Tanpa ini, popup heads-up tidak akan muncul di Android 8+
  await _localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_fcmChannel);

  // 5. Minta izin notifikasi dari user (Android 13+)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // 6. Paksa FCM menggunakan channel kita (bukan default)
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 7. Ambil & kirim FCM token ke backend
  try {
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      ApiService.updateFcmToken(token); // fire & forget
    }

    // 8. Subscribe topic global → semua user dapat broadcast pengumuman admin
    await messaging.subscribeToTopic('pengumuman_smb');
    debugPrint('Subscribed to topic: pengumuman_smb');
  } catch (e) {
    debugPrint('FCM setup error: $e');
  }

  // 9. Handle notifikasi saat app FOREGROUND (app terbuka)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('FCM Foreground: ${message.notification?.title}');

    final title = message.notification?.title ??
        message.data['title'] ??
        '📢 Pengumuman Baru';
    final body = message.notification?.body ??
        message.data['body'] ??
        'Ada pengumuman baru dari Sanggar Mulya Bhakti.';

    // Tampilkan heads-up popup
    _showHeadsUpNotification(
      title: title,
      body: body,
      id: message.messageId.hashCode,
    );

    // Simpan ke inbox notifikasi in-app
    final ns = NotificationService();
    final notif = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: body,
      timestamp: DateTime.now(),
      type: 'announcement',
    );
    ns.notifications.insert(0, notif);
    ns.saveNotifications();
  });

  // 10. Handle klik notifikasi saat app BACKGROUND (bukan terminated)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notifikasi di-tap dari background: ${message.notification?.title}');
    // Bisa tambahkan navigasi ke NotificationScreen di sini jika perlu
  });

  // 11. Handle notifikasi yang membuka app dari terminated state
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('App dibuka dari notif terminated: ${initialMessage.notification?.title}');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationService()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SanggarApp(),
    ),
  );
}

class SanggarApp extends StatelessWidget {
  const SanggarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    gIsDarkMode = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          gIsDarkMode ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Sanggar Mulya Bhakti',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/login':
            page = const LoginScreen(showRegister: false);
            break;
          case '/register':
            page = const LoginScreen(showRegister: true);
            break;
          case '/home':
            page = const MainNav();
            break;
          case '/event':
            page = const EventScreen();
            break;
          case '/archive':
            page = const ArchiveScreen();
            break;
          default:
            page = const SplashScreen();
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}