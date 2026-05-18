// lib/screens/attendance/scan_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

// mobile_scanner hanya tersedia di Android/iOS
// ignore: uri_does_not_exist
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) '../../utils/web_stub.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanning = true;
  bool _processing = false;
  _ScanResult? _result;

  late AnimationController _lineCtrl;
  late Animation<double>   _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _processing) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() { _scanning = false; _processing = true; });
    _ctrl.stop();

    try {
      final res = await ApiService.scanAbsensi(code);
      setState(() {
        _processing = false;
        _result = _ScanResult(
          success: res['success'] == true,
          message: res['message'] ?? (res['success'] == true ? 'Kehadiran berhasil dicatat!' : 'Gagal mencatat kehadiran.'),
        );
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _result = _ScanResult(success: false, message: 'Terjadi kesalahan. Coba lagi.');
      });
    }
  }

  void _retry() {
    setState(() { _scanning = true; _processing = false; _result = null; });
    _ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── Kamera ──────────────────────────────────────────────
        if (_scanning || _processing)
          MobileScanner(controller: _ctrl, onDetect: _onDetect),

        // ── Overlay gelap + viewfinder ───────────────────────────
        if (_scanning)
          _buildScannerOverlay(),

        // ── Processing indicator ─────────────────────────────────
        if (_processing)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
                SizedBox(height: 16),
                Text('Memproses...', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
          ),

        // ── Result screen ────────────────────────────────────────
        if (_result != null)
          _buildResultScreen(),

        // ── Header ──────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text('Scan Absensi', style: TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              if (_scanning)
                GestureDetector(
                  onTap: () => _ctrl.toggleTorch(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const boxSize = 260.0;
      final left   = (w - boxSize) / 2;
      final top    = (h - boxSize) / 2 - 40;

      return Stack(children: [
        // Dark overlay dengan lubang di tengah
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.72), BlendMode.srcOut),
          child: Stack(children: [
            Container(decoration: BoxDecoration(
                color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
            Positioned(
              left: left, top: top, width: boxSize, height: boxSize,
              child: Container(decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(20))),
            ),
          ]),
        ),

        // Corner brackets
        Positioned(left: left, top: top,
          child: _Corner(top: true, left: true)),
        Positioned(left: left + boxSize - 32, top: top,
          child: _Corner(top: true, left: false)),
        Positioned(left: left, top: top + boxSize - 32,
          child: _Corner(top: false, left: true)),
        Positioned(left: left + boxSize - 32, top: top + boxSize - 32,
          child: _Corner(top: false, left: false)),

        // Scanning line
        Positioned(
          left: left + 4, top: top + 4,
          width: boxSize - 8, height: boxSize - 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AnimatedBuilder(
              animation: _lineAnim,
              builder: (_, __) => Align(
                alignment: Alignment(_lineAnim.value * 2 - 1, -1 + _lineAnim.value * 2),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent, kPrimary, kPrimary, Colors.transparent,
                    ]),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.6), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Label bawah viewfinder
        Positioned(
          left: 0, right: 0,
          top: top + boxSize + 24,
          child: Column(children: [
            Text('Arahkan kamera ke QR Code kelas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 6),
            Text('QR Code tersedia di papan informasi sanggar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      ]);
    });
  }

  Widget _buildResultScreen() {
    final ok = _result!.success;
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Icon circle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok ? const Color(0xFF1A3A1A) : const Color(0xFF3A1A1A),
                  border: Border.all(
                    color: ok ? const Color(0xFF2E7D32) : const Color(0xFFDC2626),
                    width: 2),
                ),
                child: Icon(
                  ok ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                  color: ok ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                  size: 52),
              ),
            ),
            SizedBox(height: 24),

            Text(ok ? 'Berhasil! 🎉' : 'Gagal',
              style: TextStyle(
                color: ok ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                fontSize: 26, fontWeight: FontWeight.w900,
                fontFamily: 'PlayfairDisplay')),
            SizedBox(height: 12),

            Text(_result!.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            SizedBox(height: 36),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, ok),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ok ? const Color(0xFF2E7D32) : kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(ok ? 'Kembali ke Dashboard' : 'Kembali',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            if (!ok) ...[
              SizedBox(height: 12),
              TextButton(
                onPressed: _retry,
                child: Text('Coba Scan Lagi',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ScanResult {
  final bool success;
  final String message;
  const _ScanResult({required this.success, required this.message});
}

class _Corner extends StatelessWidget {
  final bool top, left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 32, height: 32,
      child: CustomPaint(painter: _CornerPainter(top: top, left: left)));
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kPrimary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top  ? 0.0 : size.height;
    final dx = left ? size.width  : -size.width;
    final dy = top  ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
