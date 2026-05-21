// lib/screens/auth/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class OtpScreen extends StatefulWidget {
  final int userId;
  final String email;
  const OtpScreen({super.key, required this.userId, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _ctrs = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _loading = false, _resending = false;
  String? _error;
  int _countdown = 60;
  Timer? _timer;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    for (final c in _ctrs) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) _countdown--;
        else _timer?.cancel();
      });
    });
  }

  String get _otpCode => _ctrs.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length < 6) {
      _shakeCtrl.forward(from: 0);
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.verifyOtp(widget.userId, _otpCode);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _shakeCtrl.forward(from: 0);
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      // Kosongkan kotak OTP
      for (final c in _ctrs) c.clear();
      _nodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _resending) return;
    setState(() { _resending = true; _error = null; });
    try {
      await ApiService.resendOtp(widget.userId);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kode OTP baru telah dikirim ke email Anda'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: Stack(children: [
        // Dekorasi background
        Positioned(
          top: -120, right: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kPrimary.withOpacity(0.10), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: -60, left: -50,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kPrimaryDark.withOpacity(0.08), Colors.transparent]),
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Tombol kembali
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Color(0xFF333333)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Icon email
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryLight, kPrimaryDark],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Verifikasi Email',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFF1A1A1A), fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
                      children: [
                        const TextSpan(text: 'Kode OTP 6 digit telah dikirim ke\n'),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            color: kPrimary, fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '\nBerlaku selama 10 menit.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Kotak OTP 6 digit
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeCtrl.isAnimating
                          ? 8 * ((_shakeAnim.value * 6).toInt().isEven ? 1 : -1)
                          : 0, 0),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _ctrs[i],
                        focusNode: _nodes[i],
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5) {
                            _nodes[i + 1].requestFocus();
                          } else if (val.isEmpty && i > 0) {
                            _nodes[i - 1].requestFocus();
                          }
                          if (_otpCode.length == 6) _verify();
                        },
                      )),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFE53935), size: 16),
                        const SizedBox(width: 9),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(color: Color(0xFFE53935), fontSize: 12))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Tombol Verifikasi
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kPrimaryLight, kPrimaryDark]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Verifikasi Sekarang',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kirim ulang OTP
                  Center(
                    child: _countdown > 0
                        ? RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13),
                              children: [
                                const TextSpan(
                                    text: 'Kirim ulang kode dalam ',
                                    style: TextStyle(color: Color(0xFF888888))),
                                TextSpan(
                                    text: '${_countdown}s',
                                    style: TextStyle(
                                        color: kPrimary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: _resend,
                            child: _resending
                                ? SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: kPrimary, strokeWidth: 2))
                                : RichText(
                                    text: TextSpan(children: [
                                      const TextSpan(
                                          text: 'Tidak menerima kode? ',
                                          style: TextStyle(
                                              color: Color(0xFF888888), fontSize: 13)),
                                      TextSpan(
                                          text: 'Kirim Ulang',
                                          style: TextStyle(
                                              color: kPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13)),
                                    ]),
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onChanged('');
          }
          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: kPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E2DE), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: kPrimary, width: 2)),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
