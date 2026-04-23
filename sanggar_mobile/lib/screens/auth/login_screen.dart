// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  final bool showRegister;
  const LoginScreen({super.key, this.showRegister = false});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool _isReg;
  late AnimationController _anim;
  late Animation<double> _fade;

  final _form        = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _alamatCtrl  = TextEditingController();
  final _passConfCtrl = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isReg = widget.showRegister;
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in [_emailCtrl,_passCtrl,_nameCtrl,_alamatCtrl,_passConfCtrl]) c.dispose();
    super.dispose();
  }

  void _toggle() {
    _anim.reverse().then((_) {
      setState(() { _isReg = !_isReg; _error = null; });
      _anim.forward();
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgSoft,
      body: Stack(children: [
        // Top decoration
        Positioned(top: 0, left: 0, right: 0,
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryDark, kPrimary],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
          )),

        SafeArea(
          child: Column(children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20))),

            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: kSpace),
              child: Column(children: [
                const SizedBox(height: kSpace),

                // Logo & title
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.15),
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
                  child: const Center(child: Text('SMB', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900,
                    fontFamily: 'PlayfairDisplay')))),
                const SizedBox(height: kSpace),

                FadeTransition(opacity: _fade,
                  child: Column(children: [
                    Text(_isReg ? 'Daftar Anggota' : 'Selamat Datang',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'PlayfairDisplay')),
                    const SizedBox(height: 4),
                    Text(
                      _isReg
                        ? 'Bergabunglah dengan komunitas seni kami'
                        : 'Masuk untuk mengakses fitur lengkap',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ])),
                const SizedBox(height: kSpaceLg),

                // Form card
                Container(
                  padding: const EdgeInsets.all(kSpaceMd),
                  decoration: BoxDecoration(
                    color:        kBgCard,
                    borderRadius: BorderRadius.circular(kRadiusXl),
                    boxShadow: [BoxShadow(
                      color:      Colors.black.withOpacity(0.08),
                      blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Form(key: _form, child: Column(children: [
                    // Error
                    if (_error != null)
                      Container(
                        margin:  const EdgeInsets.only(bottom: kSpace),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(kRadiusSm),
                          border: Border.all(color: const Color(0xFFFECACA))),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 12))),
                        ])),

                    // Fields
                    if (_isReg) ...[
                      _Field(ctrl: _nameCtrl, label: 'Nama Lengkap',
                          hint: 'Masukan nama lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null),
                      const SizedBox(height: kSpaceSm),
                    ],
                    _Field(ctrl: _emailCtrl, label: 'Email',
                        hint: 'nama@gmail.com',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Email wajib diisi';
                          if (!(v!.contains('@'))) return 'Format tidak valid';
                          return null;
                        }),
                    const SizedBox(height: kSpaceSm),
                    if (_isReg) ...[
                      _Field(ctrl: _alamatCtrl, label: 'Alamat',
                          hint: 'Masukan alamat lengkap',
                          icon: Icons.location_on_outlined,
                          maxLines: 2),
                      const SizedBox(height: kSpaceSm),
                    ],
                    // Password
                    TextFormField(
                      controller:  _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText:  'Password',
                        hintText:   _isReg ? 'Minimal 8 karakter' : 'Masukan password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: kMuted),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: kMuted, size: 20))),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Password wajib diisi';
                        if (_isReg && (v!.length < 8)) return 'Minimal 8 karakter';
                        return null;
                      }),
                    if (_isReg) ...[
                      const SizedBox(height: kSpaceSm),
                      TextFormField(
                        controller:  _passConfCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText:  'Konfirmasi Password',
                          hintText:   'Ulangi password',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: kMuted)),
                        validator: (v) => v != _passCtrl.text ? 'Password tidak cocok' : null),
                    ] else ...[
                      Align(alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () {},
                          child: const Text('Lupa Password?',
                            style: TextStyle(color: kPrimary, fontSize: 12,
                                fontWeight: FontWeight.w700)))),
                    ],
                    const SizedBox(height: kSpaceMd),

                    // Submit
                    SizedBox(width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(_isReg ? 'Daftar' : 'Masuk',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                      )),
                    const SizedBox(height: kSpace),

                    // Toggle
                    GestureDetector(
                      onTap: _toggle,
                      child: RichText(
                        text: TextSpan(style: AppText.bodySm, children: [
                          TextSpan(text: _isReg ? 'Sudah punya akun? ' : 'Belum punya akun? '),
                          TextSpan(
                            text: _isReg ? 'Masuk di sini' : 'Daftar di sini',
                            style: const TextStyle(
                              color: kPrimary, fontWeight: FontWeight.w800)),
                        ])),
                    ),
                  ])),
                ),
                const SizedBox(height: kSpaceXl),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl, required this.label, required this.hint,
    required this.icon, this.type = TextInputType.text,
    this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: kMuted, size: 20)),
    validator: validator);
}