// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sanggar_mulya_bhakti/screens/archive_screen.dart';
import 'package:sanggar_mulya_bhakti/screens/event_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'services/auth_provider.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart'; 
import 'screens/main_nav.dart';   
import 'services/notification_service.dart';

import 'utils/app_theme.dart';

// Handler notifikasi saat aplikasi berada di background / dimatikan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Minta izin notifikasi (Notification Permission)
  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('Izin notifikasi disetujui oleh pengguna.');
  } else {
    debugPrint('Izin notifikasi ditolak oleh pengguna.');
  }

  // Dapatkan FCM token (bisa disimpan di backend untuk push individual)
  try {
    String? token = await messaging.getToken();
    debugPrint("FCM Registration Token: $token");
    
    // Subscribe ke topic global agar semua anggota mendapat notifikasi pengumuman
    await messaging.subscribeToTopic('pengumuman_smb');
  } catch (e) {
    debugPrint("Gagal mendaftarkan FCM Token/Topic: $e");
  }

  // Listen notifikasi saat aplikasi sedang menyala (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Notifikasi diterima saat foreground: ${message.notification?.title}');
    
    // Tambahkan notifikasi ke dalam NotificationService lokal secara instan
    if (message.notification != null) {
      NotificationService().notifications.insert(0, AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification!.title ?? 'Pengumuman Baru',
        message: message.notification!.body ?? '',
        timestamp: DateTime.now(),
        type: 'announcement',
      ));
      NotificationService().saveNotifications();
    }
  });

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
      statusBarIconBrightness: gIsDarkMode ? Brightness.light : Brightness.dark,
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