// lib/screens/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final bool showRegister;
  const LoginScreen({super.key, this.showRegister = false});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late bool _isReg;

  // Animasi masuk
  late AnimationController _entryCtrl;
  late Animation<double>   _bgFade;
  late Animation<double>   _logoFade;
  late Animation<double>   _logoScale;
  late Animation<Offset>   _titleSlide;
  late Animation<Offset>   _cardSlide;
  late Animation<double>   _cardFade;

  // Animasi toggle form
  late AnimationController _formCtrl;
  late Animation<double>   _formFade;

  final _form         = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _alamatCtrl   = TextEditingController();
  final _passConfCtrl = TextEditingController();

  bool    _loading = false, _obscure = true, _obscureConf = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isReg = widget.showRegister;

    // Entry animation
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _bgFade    = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn));
    _logoFade  = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.2, 0.55, curve: Curves.easeOut));
    _logoScale = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic)));
    _cardFade = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.45, 0.75, curve: Curves.easeIn));

    // Form toggle animation
    _formCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _formFade  = CurvedAnimation(parent: _formCtrl, curve: Curves.easeInOut);
    _formCtrl.value = 1.0;

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _formCtrl.dispose();
    for (final c in [_emailCtrl, _passCtrl, _nameCtrl, _alamatCtrl, _passConfCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle() {
    _formCtrl.reverse().then((_) {
      setState(() { _isReg = !_isReg; _error = null; });
      _formCtrl.forward();
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (_isReg) {
        await auth.register({
          'name':                  _nameCtrl.text.trim(),
          'email':                 _emailCtrl.text.trim(),
          'alamat':                _alamatCtrl.text.trim(),
          'password':              _passCtrl.text,
          'password_confirmation': _passConfCtrl.text,
        });
      } else {
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(children: [

          // ── Orb dekorasi atas-kiri ────────────────────────────
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 420, height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kPrimary.withOpacity(0.35),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Orb dekorasi bawah-kanan ──────────────────────────
          Positioned(
            bottom: -80, right: -100,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kPrimaryDark.withOpacity(0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Orb kecil tengah-kanan ────────────────────────────
          Positioned(
            top: size.height * 0.35, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kPrimaryLight.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Konten utama ──────────────────────────────────────
          SafeArea(
            child: Column(children: [

              // Back button
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white60, size: 20),
                  ),
                )
              else
                const SizedBox(height: 8),

              // ── Brand Section ───────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: _buildLogo(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & subtitle
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: _buildBrandText(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form Card ───────────────────────────────────
              Expanded(
                flex: 6,
                child: SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: _buildFormCard(),
                  ),
                ),
              ),

            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(alignment: Alignment.center, children: [
      // Glow ring
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 30, spreadRadius: 4),
          ],
        ),
      ),
      // Glass circle
      ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: const Center(
              child: Text('SMB', style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: 1.5,
                fontFamily: 'PlayfairDisplay')),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildBrandText() {
    return Column(children: [
      const Text('Sanggar Mulya Bhakti',
        style: TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900,
          fontFamily: 'PlayfairDisplay', letterSpacing: 0.3)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 24, height: 1, color: kPrimary.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text('Melestarikan Budaya Melalui Seni',
          style: TextStyle(color: Colors.white.withOpacity(0.5),
              fontSize: 11, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Container(width: 24, height: 1, color: kPrimary.withOpacity(0.6)),
      ]),
    ]);
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, -10)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Tab Toggle ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              _buildTab('Masuk',  !_isReg),
              _buildTab('Daftar', _isReg),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Greeting ───────────────────────────────────────
          FadeTransition(
            opacity: _formFade,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _isReg ? 'Buat Akun Baru' : 'Selamat Datang!',
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
              const SizedBox(height: 4),
              Text(
                _isReg ? 'Bergabung dengan komunitas seni kami'
                       : 'Masuk untuk mengakses semua fitur sanggar',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Error Banner ───────────────────────────────────
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1515),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                    color: Color(0xFFFF6B6B), fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Form ───────────────────────────────────────────
          Form(
            key: _form,
            child: FadeTransition(
              opacity: _formFade,
              child: Column(children: [
                if (_isReg) ...[
                  _DarkField(ctrl: _nameCtrl, label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null),
                  const SizedBox(height: 12),
                ],
                _DarkField(ctrl: _emailCtrl, label: 'Email',
                    hint: 'nama@gmail.com',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!v!.contains('@')) return 'Format email tidak valid';
                      return null;
                    }),
                const SizedBox(height: 12),
                if (_isReg) ...[
                  _DarkField(ctrl: _alamatCtrl, label: 'Alamat',
                      hint: 'Masukkan alamat (opsional)',
                      icon: Icons.location_on_outlined,
                      maxLines: 2),
                  const SizedBox(height: 12),
                ],

                // Password field
                _DarkPasswordField(
                  ctrl: _passCtrl,
                  label: 'Password',
                  hint: _isReg ? 'Minimal 8 karakter' : 'Masukkan password',
                  obscure: _obscure,
                  onToggle: () => setState(() => _obscure = !_obscure),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Password wajib diisi';
                    if (_isReg && v!.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),

                if (_isReg) ...[
                  const SizedBox(height: 12),
                  _DarkPasswordField(
                    ctrl: _passConfCtrl,
                    label: 'Konfirmasi Password',
                    hint: 'Ketik ulang password',
                    obscure: _obscureConf,
                    onToggle: () => setState(() => _obscureConf = !_obscureConf),
                    validator: (v) => v != _passCtrl.text ? 'Password tidak cocok' : null,
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Lupa Password?',
                        style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(_isReg ? 'Buat Akun' : 'Masuk Sekarang',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Toggle link
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: _isReg ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  TextSpan(
                    text: _isReg ? 'Masuk' : 'Daftar sekarang',
                    style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            )),
          ),
        ),
      ),
    );
  }
}

// ── DARK INPUT FIELD ──────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.ctrl, required this.label, required this.hint,
    required this.icon, this.type = TextInputType.text,
    this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white30, size: 18),
      filled: true,
      fillColor: const Color(0xFF262626),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2)),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator: validator,
  );
}

class _DarkPasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _DarkPasswordField({
    required this.ctrl, required this.label, required this.hint,
    required this.obscure, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white30, size: 18),
      suffixIcon: GestureDetector(
        onTap: onToggle,
        child: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white30, size: 18),
      ),
      filled: true,
      fillColor: const Color(0xFF262626),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2)),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator: validator,
  );
}