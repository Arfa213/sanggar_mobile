// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // 🚀 FIX 1: Import ApiService untuk membaca token secara langsung
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
    
    // Menjalankan pengecekan rute setelah durasi delay 3 detik terpenuhi
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  // 🚀 FIX 2: Mengubah fungsi menjadi 'async' agar akurat membaca memori lokal HP
  Future<void> _navigate() async {
    if (!mounted) return;
    
    // Ambil token login yang tersimpan di HP secara langsung dan pasti
    final String? token = await ApiService.getToken();

    if (!mounted) return;

    // Tentukan rute tujuan berdasarkan keberadaan token lokal
    // Jika token ada -> Masuk ke Dashboard (/home), jika kosong -> Masuk ke halaman login/register
    final String targetRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';

    // Pindah halaman menggunakan nama rute secara aman dan membuang riwayat splash screen
    Navigator.pushReplacementNamed(context, targetRoute);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDark, kPrimary, const Color(0xFFD4754A)],
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
                  width: 110, height: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logosanggar.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )),
              const SizedBox(height: 28),

              // Title
              AnimatedBuilder(
                animation: _slide,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: child,
                ),
                child: Column(children: [
                  const Text('Sanggar Mulya Bhakti',
                    style: TextStyle(
                      color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'PlayfairDisplay',
                      letterSpacing: 0.5,
                    )),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 20, height: 1, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 8),
                    Text('Melestarikan Budaya Melalui Seni',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12,
                        letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Container(width: 20, height: 1, color: Colors.white.withOpacity(0.4)),
                  ]),
                ]),
              ),
              const SizedBox(height: 52),

              // Loader
              Navigator.canPop(context) // Diganti logika aman agar progress bar tetap estetik saat rendering
                  ? const SizedBox()
                  : SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                        color:        Colors.white.withOpacity(0.6),
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