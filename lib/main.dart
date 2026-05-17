// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sanggar_mulya_bhakti/screens/archive_screen.dart';
import 'package:sanggar_mulya_bhakti/screens/event_screen.dart';

import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart'; 
import 'screens/main_nav.dart';   

import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const SanggarApp(),
    ),
  );
}

class SanggarApp extends StatelessWidget {
  const SanggarApp({super.key});

  @override
  Widget build(BuildContext context) {
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