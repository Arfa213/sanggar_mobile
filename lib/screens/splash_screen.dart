// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade, _scale, _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeIn));
    _scale = Tween(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _slide = Tween(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1, curve: Curves.easeOut)));
    _ctrl.forward();
    
    // Menjalankan pengecekan rute setelah delay 3 detik
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

void _navigate() {
    if (!mounted) return;
    
    // Cek status login
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Tentukan rute tujuan
    final String targetRoute = auth.isLoggedIn ? '/home' : '/register';

    // Pindah halaman menggunakan nama rute secara aman
    Navigator.pushReplacementNamed(context, targetRoute);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDark, kPrimary, Color(0xFFD4754A)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          // Pattern decoration
          Positioned(top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 40),
              ),
            )),
          Positioned(bottom: -80, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.06), width: 50),
              ),
            )),

          // Content
          Center(child: FadeTransition(opacity: _fade,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Logo
              ScaleTransition(scale: _scale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    shape:        BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('SMB', style: TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w900, letterSpacing: 1.5,
                      fontFamily: 'PlayfairDisplay',
                    )),
                    Container(width: 30, height: 1.5, color: Colors.white.withOpacity(0.5)),
                    SizedBox(height: 2),
                    Text('SANGGAR', style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 7, letterSpacing: 2, fontWeight: FontWeight.w700,
                    )),
                  ]),
                )),
              SizedBox(height: 28),

              // Title
              AnimatedBuilder(
                animation: _slide,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: child,
                ),
                child: Column(children: [
                  Text('Sanggar Mulya Bhakti',
                    style: TextStyle(
                      color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'PlayfairDisplay',
                      letterSpacing: 0.5,
                    )),
                  SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 20, height: 1, color: Colors.white.withOpacity(0.4)),
                    SizedBox(width: 8),
                    Text('Melestarikan Budaya Melalui Seni',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12,
                        letterSpacing: 0.5)),
                    SizedBox(width: 8),
                    Container(width: 20, height: 1, color: Colors.white.withOpacity(0.4)),
                  ]),
                ]),
              ),
              SizedBox(height: 52),

              // Loader
              SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  color:       Colors.white.withOpacity(0.6),
                  strokeWidth: 2,
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}