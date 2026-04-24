// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';

import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(ChangeNotifierProvider(
    create: (_) => AuthProvider()..init(),
    child: const SanggarApp(),
  ));
}

class SanggarApp extends StatelessWidget {
  const SanggarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                    'Sanggar Mulya Bhakti',
      debugShowCheckedModeBanner: false,
      theme:                    buildAppTheme(),
      home:                     const SplashScreen(),
    );
  }
}