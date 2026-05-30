// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showRegister;
  const LoginScreen({super.key, this.showRegister = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool _isReg;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _form         = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _alamatCtrl   = TextEditingController();
  final _noHpCtrl     = TextEditingController();
  final _passConfCtrl = TextEditingController();

  bool    _loading = false, _googleLoading = false;
  bool    _obscure = true, _obscureConf = true;
  String  _tipeAnggota = 'tetap';
  String? _error;

  @override
  void initState() {
    super.initState();
    _isReg = widget.showRegister;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in [_emailCtrl, _passCtrl, _nameCtrl, _alamatCtrl, _noHpCtrl, _passConfCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle() {
    _ctrl.reverse().then((_) {
      setState(() { _isReg = !_isReg; _error = null; });
      _ctrl.forward();
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
          'no_hp':                 _noHpCtrl.text.trim(),
          'tipe_anggota':          _tipeAnggota,
          'password':              _passCtrl.text,
          'password_confirmation': _passConfCtrl.text,
        });
      } else {
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on OtpRequiredException catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(
          userId: e.userId,
          email: _emailCtrl.text.trim(),
        )),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.loginWithGoogle();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: Stack(children: [
        // ── Dekorasi blob warna sanggar di sudut ──────────────────
        Positioned(
          top: -140, right: -100,
          child: Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kPrimary.withOpacity(0.12), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: -80, left: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kPrimaryDark.withOpacity(0.08), Colors.transparent]),
            ),
          ),
        ),

        // ── Konten utama ──────────────────────────────────────────
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabBar(),
                    const SizedBox(height: 24),
                    if (_error != null) ...[_buildErrorBanner(), const SizedBox(height: 16)],
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 28),
                    _buildToggleLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Logo badge
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logosanggar.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        _isReg ? 'Buat Akun\nBaru 🎭' : 'Selamat\nDatang Kembali 👋',
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFF1A1A1A), fontSize: 30,
          fontWeight: FontWeight.w900, height: 1.18,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _isReg
            ? 'Bergabung dengan komunitas seni budaya kami'
            : 'Masuk dan eksplorasi dunia seni Sanggar Mulya Bhakti',
        style: const TextStyle(
          color: Color(0xFF888888), fontSize: 13, height: 1.5),
      ),
    ]);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEECE9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _Tab(label: 'Masuk',  active: !_isReg, onTap: _isReg  ? _toggle : null),
        _Tab(label: 'Daftar', active: _isReg,  onTap: !_isReg ? _toggle : null),
      ]),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
        const SizedBox(width: 9),
        Expanded(child: Text(_error!,
          style: const TextStyle(color: Color(0xFFE53935), fontSize: 12))),
      ]),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _form,
      child: Column(children: [
        if (_isReg) ...[
          _LightField(ctrl: _nameCtrl, label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null),
          const SizedBox(height: 12),
        ],
        _LightField(
          ctrl: _emailCtrl, label: 'Email', hint: 'nama@gmail.com',
          icon: Icons.email_outlined, type: TextInputType.emailAddress,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Email wajib diisi';
            if (!v!.contains('@')) return 'Format email tidak valid';
            return null;
          },
        ),
        if (_isReg) ...[
          const SizedBox(height: 12),
          _LightField(ctrl: _alamatCtrl, label: 'Alamat',
              hint: 'Masukkan alamat (opsional)',
              icon: Icons.location_on_outlined, maxLines: 2),
          const SizedBox(height: 12),
          _buildTipeAnggota(),
          if (_tipeAnggota == 'sementara') ...[
            const SizedBox(height: 12),
            _LightField(
              ctrl: _noHpCtrl,
              label: 'Nomor WhatsApp',
              hint: '0812...',
              icon: Icons.phone_android_rounded,
              type: TextInputType.phone,
              validator: (v) => (v?.isEmpty ?? true) ? 'Nomor WA wajib diisi' : null,
            ),
          ],
        ],
        const SizedBox(height: 12),
        _LightPasswordField(
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
          _LightPasswordField(
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
        const SizedBox(height: 22),
        _buildSubmitButton(),
      ]),
    );
  }

  Widget _buildTipeAnggota() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tipe Anggota',
        style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _TipeCard(
          label: 'Anggota Tetap', sub: 'Rutin (Jumat/Minggu)',
          active: _tipeAnggota == 'tetap',
          onTap: () => setState(() => _tipeAnggota = 'tetap'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _TipeCard(
          label: 'Sementara', sub: 'Private / Tamu',
          active: _tipeAnggota == 'sementara',
          onTap: () => setState(() => _tipeAnggota = 'sementara'),
        )),
      ]),
    ]);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kPrimaryLight, kPrimaryDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(_isReg ? 'Buat Akun' : 'Masuk Sekarang',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Divider(color: const Color(0xFFDDDAD6), thickness: 1)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('atau',
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
      ),
      Expanded(child: Divider(color: const Color(0xFFDDDAD6), thickness: 1)),
    ]);
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: _googleLoading ? null : _googleSignIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E2DE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _googleLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Color(0xFF4285F4),
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Masuk dengan Google',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleLink() {
    return Center(
      child: GestureDetector(
        onTap: _toggle,
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: _isReg ? 'Sudah punya akun? ' : 'Belum punya akun? ',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
            TextSpan(
              text: _isReg ? 'Masuk' : 'Daftar sekarang',
              style: TextStyle(
                color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _Tab({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [
            BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2)),
          ] : null,
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: active ? kPrimary : const Color(0xFFAAAAAA),
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
          )),
        ),
      ),
    ),
  );
}

class _TipeCard extends StatelessWidget {
  final String label, sub;
  final bool active;
  final VoidCallback onTap;
  const _TipeCard({required this.label, required this.sub,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? kPrimary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? kPrimary.withOpacity(0.5) : const Color(0xFFE5E2DE),
          width: 1.5,
        ),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(
          color: active ? kPrimary : const Color(0xFF555555),
          fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(
          color: active ? kPrimary.withOpacity(0.6) : const Color(0xFFAAAAAA),
          fontSize: 9)),
      ]),
    ),
  );
}

class _LightField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;

  const _LightField({
    required this.ctrl, required this.label, required this.hint,
    required this.icon, this.type = TextInputType.text,
    this.maxLines = 1, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFBBBBBB), size: 18),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E2DE))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2)),
      errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator: validator,
  );
}

class _LightPasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _LightPasswordField({
    required this.ctrl, required this.label, required this.hint,
    required this.obscure, required this.onToggle, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, obscureText: obscure,
    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
      prefixIcon: const Icon(Icons.lock_outline_rounded,
          color: Color(0xFFBBBBBB), size: 18),
      suffixIcon: GestureDetector(
        onTap: onToggle,
        child: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFFBBBBBB), size: 18),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E2DE))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2)),
      errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator: validator,
  );
}